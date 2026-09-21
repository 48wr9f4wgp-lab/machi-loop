extends "res://main_v41_camera_navigation.gd"

# AXIVA v0.42: bounded, visible road-response beats and safe redevelopment.
# Working slice tuning, not a production balance or a Greenlight decision.
const V42_CONFIRM: int = 92
const V42_CANCEL: int = 93
var v42_pending_path: Array = []
var v42_pending_plan: Dictionary = {}
var v42_confirming: bool = false
var v42_response_cells: Array = []
var v42_arrivals: Array[int] = []
var v42_arrival_tick: int = 0
var v42_response_count: int = 0
var v42_widen_intervention: bool = false
var v42_widen_attributed_drop: float = 0.0

func _commit_arterial() -> void:
    var plan: Dictionary = _v40_preview_metrics()
    if bool(plan["valid"]) and int(plan["acquisition_count"]) > 0 and not v42_confirming:
        if cash >= int(plan["total_cost"]):
            v42_pending_path = drag_path.duplicate()
            v42_pending_plan = plan.duplicate(true)
            queue_redraw()
            return
    var before: int = v40_commit_count
    var first: bool = _count_cells(Cell.ARTERIAL) == 0
    super._commit_arterial()
    if v40_commit_count == before:
        return
    v42_response_cells = v40_last_result["cells"].duplicate()
    v42_arrival_tick = tick_count
    # A short arrival wave after the first road, not an endless growth subsidy.
    # Later routes get at most two accessibility responses, only without severe
    # congestion. The ordinary demand/traffic simulation continues underneath.
    if first and population > 0:
        v42_arrivals.assign([Cell.LOCAL, Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.RESIDENTIAL])
    elif congestion < 68.0:
        v42_arrivals.assign([-1, -1])

func _v42_confirm_acquisition() -> void:
    if v42_pending_path.is_empty():
        return
    drag_path = v42_pending_path.duplicate()
    var current: Dictionary = _v40_preview_metrics()
    if current != v42_pending_plan or cash < int(current["total_cost"]):
        _v41_cancel_edit()
        _toast("計画が変わりました。もう一度道を引こう")
        return
    v42_pending_path.clear()
    v42_pending_plan.clear()
    v42_confirming = true
    _commit_arterial()
    v42_confirming = false
    dragging = false
    drag_path.clear()
    _v10_sync_preview()
    queue_redraw()

func _v41_cancel_edit() -> void:
    v42_pending_path.clear()
    v42_pending_plan.clear()
    super._v41_cancel_edit()

func _v41_begin_single(pos: Vector2) -> void:
    if not v42_pending_path.is_empty() and _v41_ui_action(pos) < 0:
        return
    super._v41_begin_single(pos)

func _v41_ui_action(pos: Vector2) -> int:
    if not v42_pending_path.is_empty():
        if _v42_confirm_rect().has_point(pos):
            return V42_CONFIRM
        if _v42_cancel_rect().has_point(pos):
            return V42_CANCEL
    return super._v41_ui_action(pos)

func _v41_execute_ui(action: int) -> void:
    if action == V42_CONFIRM:
        _v42_confirm_acquisition()
    else:
        super._v41_execute_ui(action)

func _v42_confirm_rect() -> Rect2:
    return Rect2(board_rect.get_center().x + 4.0, board_rect.end.y - 62.0,
        minf(144.0, board_rect.size.x * 0.42), 44.0)

func _v42_cancel_rect() -> Rect2:
    var size: Vector2 = _v42_confirm_rect().size
    return Rect2(board_rect.get_center().x - size.x - 4.0, board_rect.end.y - 62.0, size.x, size.y)

func _v10_sync_preview() -> void:
    if v42_pending_path.is_empty():
        super._v10_sync_preview()
        return
    var old_path: Array = drag_path
    var old_dragging: bool = dragging
    drag_path = v42_pending_path
    dragging = true
    super._v10_sync_preview()
    drag_path = old_path
    dragging = old_dragging

func _v10_draw_preview_cost() -> void:
    if v42_pending_path.is_empty():
        super._v10_draw_preview_cost()

func _simulation_tick() -> void:
    if dragging or v41_single_down or not v42_pending_path.is_empty():
        return
    var before_tick: int = tick_count
    super._simulation_tick()
    if tick_count == before_tick or v42_arrivals.is_empty():
        return
    if congestion >= 68.0:
        v42_arrivals.clear()
        return
    if tick_count - v42_arrival_tick < 2:
        return
    v42_arrival_tick = tick_count
    var kind: int = v42_arrivals.pop_front()
    if kind == -1:
        kind = _choose_building_type()
    _v42_arrive_near_road(kind)

func _v42_arrive_near_road(kind: int) -> void:
    var candidates: Array[Vector2i] = []
    for value: Variant in v42_response_cells:
        var road: Vector2i = value
        if not _v04_is_road(road):
            continue
        for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var p: Vector2i = road + d
            if not _in_bounds(p) or p.x >= unlocked_cols or int(grid[p.y][p.x]) != Cell.EMPTY:
                continue
            if kind == Cell.LOCAL and _adjacent_road_count(p) >= 2:
                continue
            if not candidates.has(p):
                candidates.append(p)
    if candidates.is_empty():
        return
    var p: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
    var before_count: int = _v29_building_count()
    grid[p.y][p.x] = kind
    v42_response_count += 1
    if kind == Cell.LOCAL:
        _v04_add_fx(p, "local", "")
        if v28_sequence_active:
            _v28_note_local_road(p)
    else:
        _v27_schedule_growth(p, false)
        if kind == Cell.COMMERCIAL and v28_sequence_active:
            _v28_note_commercial(p)
    _recalculate_city()
    _v28_maybe_reveal()
    _v29_note_growth_resume(before_count)
    _v10_sync_scene()
    _v07_save_city()

func _widen(p: Vector2i) -> void:
    var had_width: bool = widened.has(_key(p))
    var was_problem: bool = v29_recovery_stage in [V29_STAGE_PROBLEM, V29_STAGE_INTERVENTION]
    var before_pressure: float = congestion
    super._widen(p)
    if had_width or not widened.has(_key(p)) or not was_problem:
        return
    v42_widen_intervention = true
    v42_widen_attributed_drop += maxf(0.0, before_pressure - congestion)
    var cells: Array[Vector2i] = [p]
    _v29_register_intervention(cells)

func _v29_begin_problem() -> void:
    v42_widen_intervention = false
    v42_widen_attributed_drop = 0.0
    super._v29_begin_problem()

func _v29_observe_traffic_state() -> void:
    super._v29_observe_traffic_state()
    if not v42_widen_intervention or v29_recovery_stage != V29_STAGE_INTERVENTION:
        return
    # Widening is a genuine capacity response, not a new graph cycle. Require a
    # measured reduction; buying away demand alone is never counted as a bypass.
    var drop: float = v29_problem_congestion - congestion
    var required: float = maxf(12.0, v29_problem_congestion * 0.12)
    if drop >= required and v42_widen_attributed_drop >= required:
        _v29_begin_recovery()

func _v29_begin_recovery() -> void:
    super._v29_begin_recovery()
    v42_response_cells = v29_bypass_cells.duplicate()
    v42_arrivals.assign([-1, -1])
    v42_arrival_tick = tick_count
    if v22_feedback != null:
        v22_feedback.goal_complete()

func _v23_context_message() -> String:
    if not v42_pending_path.is_empty():
        return "買収する建物と費用を確認しよう"
    if v29_recovery_stage == V29_STAGE_PROBLEM:
        return "幹線が混雑。迂回路か拡幅で流れを変えよう"
    if v29_recovery_stage == V29_STAGE_INTERVENTION:
        return "道をつなぐか拡幅して、混雑を減らそう"
    if current_tool == Tool.BULLDOZE:
        return "道路をタップして撤去・資金回収"
    if current_tool == Tool.WIDEN:
        return "混んでいる幹線をタップして拡幅 ¥90"
    return super._v23_context_message()

func _draw() -> void:
    super._draw()
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    _v42_button(_v41_overview_rect(), "全体", font)
    if not v42_pending_path.is_empty():
        _v42_draw_confirmation(font)
    elif not dragging:
        draw_string(font, Vector2(board_rect.position.x + 10.0, board_rect.end.y - 16.0),
            "1本指で道・2本指で移動と拡大   v0.42", HORIZONTAL_ALIGNMENT_CENTER,
            board_rect.size.x - 20.0, 9, Color("#214638"))

func _v42_button(rect: Rect2, text: String, font: Font) -> void:
    draw_rect(rect, Color("#174B38"))
    draw_rect(rect, Color("#8DA397"), false, 1.0)
    draw_string(font, rect.position + Vector2(4.0, 28.0), text,
        HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 12, Color.WHITE)

func _v42_draw_confirmation(font: Font) -> void:
    var panel: Rect2 = Rect2(board_rect.position.x + 6.0, board_rect.end.y - 106.0,
        board_rect.size.x - 12.0, 98.0)
    draw_rect(panel, Color(0.96, 0.95, 0.90, 0.98))
    var text: String = "買収 %d棟・合計 ¥%d" % [v42_pending_plan["acquisition_count"], v42_pending_plan["total_cost"]]
    draw_string(font, panel.position + Vector2(8.0, 27.0), text,
        HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 16.0, 13, Color("#173E30"))
    _v42_button(_v42_cancel_rect(), "やめる", font)
    _v42_button(_v42_confirm_rect(), "買収して建設", font)

func _v10_draw_projected_effects() -> void:
    super._v10_draw_projected_effects()
    var plan: Dictionary = v42_pending_plan
    if dragging and current_tool == Tool.ROAD:
        plan = _v40_preview_metrics()
    if plan.is_empty() or not is_instance_valid(v10_camera):
        return
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    for value: Variant in plan.get("acquired", []):
        var p: Vector2i = value
        var screen: Vector2 = _v27_project_cell(p, 2.8)
        if not _v41_world_area().has_point(screen):
            continue
        # A symbol and text, not color alone; never modify shared materials.
        draw_circle(screen, 11.0, Color("#D18C3D"), false, 2.0)
        draw_string(font, screen + Vector2(-19.0, -15.0), "買収",
            HORIZONTAL_ALIGNMENT_CENTER, 38.0, 9, Color("#173E30"))
