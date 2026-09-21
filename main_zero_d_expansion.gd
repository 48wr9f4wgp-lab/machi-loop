extends "res://main_zero_c_core_fun.gd"

const Expansion = preload("res://domain/zero_d_expansion.gd")
const D_MOVE: int = 97
const D_HOME: int = 98
const D_REGION_ACTION: int = 110
var zero_d_session: bool = false
var zero_d_state: Dictionary = {}
var zero_d_hash: int = -1
var zero_d_preferred: int = 0
var zero_d_pan_point: Vector2 = Vector2.ZERO
var zero_d_hint: String = "道を駅前へ伸ばす？ 物流地区へ伸ばす？"
var zero_d_effect_until: float = -1.0
var zero_d_growth_marks: Dictionary = {}

func _ready() -> void:
    zero_d_session = _zero_d_detect_session()
    if zero_d_session:
        GRID_W = Expansion.SIZE.x
        GRID_H = Expansion.SIZE.y
        unlocked_cols = GRID_W
        # Manual camera owns framing from the first renderer initialization.
        v41_manual_camera = true
        v41_camera_target = _v10_world_position(Expansion.HOME, 0.0)
        v41_camera_size = 30.0
    super._ready()
    if zero_d_session:
        _zero_d_focus(Expansion.HOME)
        _recalculate_city()
        _v10_sync_scene()

func _zero_d_query_requests(query: String) -> bool:
    return query.trim_prefix("?").split("&").has("zero=d")

func _zero_d_detect_session() -> bool:
    if OS.get_cmdline_user_args().has("--zero-d"):
        return true
    return OS.has_feature("web") and _zero_d_query_requests(str(JavaScriptBridge.eval("window.location.search", true)))

func _zero_detect_session() -> bool:
    return zero_d_session or super._zero_detect_session()

func _init_grid() -> void:
    super._init_grid()
    if zero_d_session:
        for x: int in range(6, 10):
            grid[22][x] = Cell.ARTERIAL
        for p: Vector2i in [Vector2i(7,21), Vector2i(8,21), Vector2i(9,21)]:
            grid[p.y][p.x] = Cell.RESIDENTIAL
        v04_first_growth_seeded = true

func _v20_load_ftue_stage() -> int:
    return 0 if zero_d_session else super._v20_load_ftue_stage()

func _v20_save_ftue() -> void:
    if not zero_d_session:
        super._v20_save_ftue()

func _v33_delete_persistent_city_state() -> void:
    if not zero_d_session:
        super._v33_delete_persistent_city_state()

func _v42_build_label() -> String:
    return "ZERO D" if zero_d_session else super._v42_build_label()

func _zero_d_refresh() -> void:
    if grid.is_empty():
        return
    var signature: int = hash(grid)
    if signature != zero_d_hash or zero_d_state.is_empty():
        zero_d_state = Expansion.analyze(grid)
        zero_d_hash = signature

func _recalculate_city() -> void:
    if not zero_d_session:
        super._recalculate_city()
        return
    _zero_d_refresh()
    population = _count_cells(Cell.RESIDENTIAL) * 13
    jobs = _count_cells(Cell.COMMERCIAL) * 8 + _count_cells(Cell.INDUSTRIAL) * 11
    cash = ZERO_CASH
    happiness = 100
    congestion = 0.0
    v16_traffic_status = "good"
    v16_traffic_cause = "none"
    _check_unlocks()

func _check_unlocks() -> void:
    if not zero_d_session:
        super._check_unlocks()
        return
    unlocked_cols = GRID_W
    # A descriptive stage, not an unlock or a win gate.
    city_level = 1 + mini(4, zero_d_state.get("buildings", {}).size() / 32)

func _simulation_tick() -> void:
    if not zero_d_session:
        super._simulation_tick()
        return
    if paused or dragging or v41_single_down or v41_navigation_gesture_active:
        return
    tick_count += 1
    _auto_generate_local_roads()
    _auto_grow_buildings()
    _recalculate_city()
    _v10_sync_scene()
    queue_redraw()

func _auto_grow_buildings() -> void:
    if not zero_d_session:
        super._auto_grow_buildings()
        return
    _zero_d_refresh()
    var p: Vector2i = Expansion.growth_choice(zero_d_state, zero_d_preferred)
    if p.x < 0:
        return
    var region: int = Expansion.region_at(p)
    grid[p.y][p.x] = Expansion.KINDS[region]
    _v27_schedule_growth(p, false)
    zero_d_growth_marks[p] = v04_time + 2.0
    v42_response_count += 1

func _auto_generate_local_roads() -> void:
    if not zero_d_session:
        super._auto_generate_local_roads()
        return
    _zero_d_refresh()
    if tick_count % 8 != 0 or _count_cells(Cell.LOCAL) >= 24:
        return
    for value: Variant in zero_d_state["candidates"][zero_d_preferred]:
        var p: Vector2i = value
        if _adjacent_road_count(p) == 1 and _distance_to_arterial(p) <= 2:
            grid[p.y][p.x] = Cell.LOCAL
            return

func _commit_arterial() -> void:
    var prior: int = v40_commit_count
    var before: Dictionary = zero_d_state.duplicate(true) if zero_d_session else {}
    super._commit_arterial()
    if not zero_d_session:
        return
    v42_arrivals.clear()
    if prior == v40_commit_count:
        return
    _zero_d_refresh()
    var cells: Array = v40_last_result.get("cells", [])
    if not cells.is_empty():
        var p: Vector2i = cells[-1]
        if zero_d_state["connected"].has(p):
            zero_d_preferred = Expansion.opened_region(before, zero_d_state, zero_d_preferred)
            zero_d_hint = Expansion.NAMES[zero_d_preferred] + "へ道が伸びた。沿道が育ちはじめる"
        else:
            zero_d_hint = "中心街から道をつなぐと、沿道が育つ"
        zero_d_effect_until = v04_time + 5.0
    _v10_sync_scene()

func _bulldoze(p: Vector2i) -> void:
    super._bulldoze(p)
    if zero_d_session:
        cash = ZERO_CASH
        _recalculate_city()
        _v10_sync_scene()

func _v42_arrive_near_road(kind: int) -> void:
    if not zero_d_session:
        super._v42_arrive_near_road(kind)

func _v29_observe_traffic_state() -> void:
    if not zero_d_session:
        super._v29_observe_traffic_state()

func _v43_draw_pressure_readability() -> void:
    if not zero_d_session:
        super._v43_draw_pressure_readability()

func _v28_base_camera_size() -> float:
    if not zero_d_session:
        return super._v28_base_camera_size()
    # Same local scale as the 16x22 trial, irrespective of total world extent.
    var aspect: float = maxf(0.4, board_rect.size.x / maxf(1.0, board_rect.size.y))
    return maxf(22.0 * 1.06, 16.0 / aspect * 1.06)

func _zero_d_focus(p: Vector2i) -> void:
    _v41_cancel_edit()
    v41_manual_camera = true
    v41_camera_target = _v10_world_position(p, 0.0)
    v41_camera_size = _v28_base_camera_size()
    _v41_clamp_camera()
    _v41_apply_manual_camera()
    queue_redraw()

func _layout_tools(size: Vector2) -> void:
    if not zero_d_session:
        super._layout_tools(size)
        return
    tool_rects.clear()
    var width: float = (size.x - 40.0) / 3.0
    var actions: Array[int] = [Tool.ROAD, D_MOVE, Tool.BULLDOZE]
    for i: int in range(3):
        tool_rects[actions[i]] = Rect2(12.0 + i * (width + 8.0), size.y - V24_BOTTOM_H + 16.0, width, 54.0)

func _zero_d_nav_rect(action: int) -> Rect2:
    var left: float = board_rect.position.x + 10.0
    if action == D_HOME:
        left += 76.0
    return Rect2(left, board_rect.position.y + 10.0, 68.0, 44.0)

func _v33_reset_rect() -> Rect2:
    if not zero_d_session:
        return super._v33_reset_rect()
    return Rect2(board_rect.end.x - 82.0, board_rect.position.y + 10.0, 72.0, 44.0)

func _v41_world_area() -> Rect2:
    if not zero_d_session:
        return super._v41_world_area()
    return Rect2(board_rect.position + Vector2(0,64), board_rect.size - Vector2(0,112))

func _zero_d_region_rect(i: int) -> Rect2:
    # Resolve nearby labels in screen space, so a compact phone does not turn
    # two destination targets into one overlapping hitbox.
    var placed: Array[Rect2] = []
    var area: Rect2 = _v41_world_area()
    for index: int in range(i + 1):
        var pos: Vector2 = _v27_project_cell(Expansion.ANCHORS[index], 0.8)
        var original: Rect2 = Rect2(pos - Vector2(44,44), Vector2(88,44))
        var chosen: Rect2 = original
        if area.encloses(original):
            for shift: int in [0, 1, -1, 2, -2]:
                var candidate: Rect2 = Rect2(original.position + Vector2(0, shift * 48), original.size)
                if not area.encloses(candidate):
                    continue
                var overlaps: bool = false
                for prior: Rect2 in placed:
                    overlaps = overlaps or (area.encloses(prior) and candidate.grow(2).intersects(prior))
                if not overlaps:
                    chosen = candidate
                    break
        placed.append(chosen)
    return placed[-1]

func _zero_d_region_visible(i: int) -> bool:
    var rect: Rect2 = _zero_d_region_rect(i)
    return _v41_world_area().encloses(rect)

func _v41_ui_action(pos: Vector2) -> int:
    if not zero_d_session:
        return super._v41_ui_action(pos)
    if _v33_reset_rect().has_point(pos):
        return V41_RESET
    for action: int in [V41_OVERVIEW, D_HOME]:
        if _zero_d_nav_rect(action).has_point(pos):
            return action
    for action: int in tool_rects:
        if (tool_rects[action] as Rect2).has_point(pos):
            return action
    # Only overview labels navigate; close-up labels must not steal road input.
    if v41_camera_size > _v28_base_camera_size() * 1.2:
        for i: int in range(Expansion.ANCHORS.size()):
            if _zero_d_region_visible(i) and _zero_d_region_rect(i).has_point(pos):
                return D_REGION_ACTION + i
    return -1

func _v41_execute_ui(action: int) -> void:
    if not zero_d_session:
        super._v41_execute_ui(action)
        return
    _v41_cancel_edit()
    if action == V41_RESET:
        _v33_request_reset()
    elif action == V41_OVERVIEW:
        _v41_show_overview()
    elif action == D_HOME:
        _zero_d_focus(Expansion.HOME)
    elif action >= D_REGION_ACTION and action < D_REGION_ACTION + Expansion.ANCHORS.size():
        _zero_d_focus(Expansion.ANCHORS[action - D_REGION_ACTION])
    elif action in [Tool.ROAD, Tool.BULLDOZE, D_MOVE]:
        current_tool = action
    queue_redraw()

func _v41_begin_single(pos: Vector2) -> void:
    super._v41_begin_single(pos)
    if zero_d_session:
        zero_d_pan_point = pos

func _v41_move_single(pos: Vector2) -> void:
    if zero_d_session and v41_single_down and not v41_single_is_ui and v41_single_action == D_MOVE and _v41_world_area().has_point(v41_single_origin):
        var before: Vector3 = _v41_ground_at(zero_d_pan_point)
        var after: Vector3 = _v41_ground_at(pos)
        if before.is_finite() and after.is_finite():
            v41_camera_target += before - after
            _v41_clamp_camera()
            _v41_apply_manual_camera()
            v41_pan_update_count += 1
        zero_d_pan_point = pos
        v41_single_moved = true
        queue_redraw()
        return
    super._v41_move_single(pos)

func _zero_add_landmarks() -> void:
    if not zero_d_session:
        super._zero_add_landmarks()
        return
    zero_landmark_count = 0
    for i: int in range(Expansion.ANCHORS.size()):
        var node: Node3D = Node3D.new()
        node.name = "ExpansionDestination%d" % i
        # Small roadside sign/landmark; growth comes from real occupied parcels.
        node.position = _v10_world_position(Expansion.ANCHORS[i], 0.0) + Vector3(-0.4,0,-0.4)
        v10_static_root.add_child(node)
        var kind: int = Expansion.KINDS[i]
        var material: Material = v10_materials["zero_station_roof"] if kind == Cell.COMMERCIAL else v10_materials["zero_roof"]
        _v10_add_box(node, Vector3(0,0.35,0), Vector3(0.08,0.7,0.08), v10_materials["zero_rail"])
        _v10_add_box(node, Vector3(0,0.65,0), Vector3(0.5,0.25,0.10), material)
        if kind == Cell.INDUSTRIAL:
            _v10_add_box(node, Vector3(0,0.92,0), Vector3(0.15,0.32,0.15), v10_materials["zero_mark"])
        zero_landmark_count += 1

func _zero_d_context() -> String:
    if current_tool == D_MOVE:
        return "一本指で移動・二本指で拡大縮小"
    if zero_d_state.get("connected", {}).is_empty():
        return "街へ戻り、中心街の道をつなぎ直そう"
    if zero_d_effect_until > v04_time:
        return zero_d_hint
    if Expansion.growth_choice(zero_d_state, zero_d_preferred).x < 0:
        return "全景から次の地区へ。道を伸ばして街を広げよう"
    return "駅前には商業、物流地区には工業が育つ"

func _v23_draw_city_first_shell() -> void:
    if not zero_d_session:
        super._v23_draw_city_first_shell()
        return
    var size: Vector2 = get_viewport_rect().size
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    draw_rect(Rect2(0,0,size.x,V24_TOP_H), Color("#F3F0E6"))
    draw_string(font, Vector2(16,30), "AXIVA ZERO D", HORIZONTAL_ALIGNMENT_LEFT, 180, 16, Color("#173E30"))
    draw_string(font, Vector2(16,54), "次は、どちらへ街を広げよう。", HORIZONTAL_ALIGNMENT_LEFT, size.x-32, 11, Color("#667D70"))
    draw_rect(Rect2(0,size.y-V24_BOTTOM_H,size.x,V24_BOTTOM_H), Color("#F3F0E6"))
    var labels: Dictionary = {Tool.ROAD:"道を引く", D_MOVE:"移動", Tool.BULLDOZE:"消す"}
    for action: int in tool_rects:
        _zero_d_button(tool_rects[action], labels[action], current_tool == action, font)
    _zero_d_button(_zero_d_nav_rect(V41_OVERVIEW), "全景", false, font)
    _zero_d_button(_zero_d_nav_rect(D_HOME), "街へ", false, font)
    var hint: Rect2 = Rect2(board_rect.position.x+8, board_rect.end.y-40, board_rect.size.x-16, 32)
    draw_rect(hint, Color(0.06,0.16,0.12,0.90))
    draw_string(font, hint.position+Vector2(6,21), _zero_d_context(), HORIZONTAL_ALIGNMENT_CENTER, hint.size.x-12, 11, Color.WHITE)

func _zero_d_button(rect: Rect2, label: String, active: bool, font: Font) -> void:
    draw_rect(rect, Color("#174B38") if active else Color("#E4E7DE"))
    draw_rect(rect, Color("#8DA397"), false, 1.0)
    draw_string(font, rect.position+Vector2(4,rect.size.y*0.5+5), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x-8, 12, Color.WHITE if active else Color("#274A3C"))

func _process(delta: float) -> void:
    super._process(delta)
    for p: Vector2i in zero_d_growth_marks.keys():
        if float(zero_d_growth_marks[p]) < v04_time:
            zero_d_growth_marks.erase(p)

func _draw() -> void:
    super._draw()
    if not zero_d_session or zero_d_state.is_empty():
        return
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    for i: int in range(Expansion.ANCHORS.size()):
        if _zero_d_region_visible(i):
            var rect: Rect2 = _zero_d_region_rect(i)
            var kind: String = "住宅" if Expansion.KINDS[i] == Cell.RESIDENTIAL else ("商業" if Expansion.KINDS[i] == Cell.COMMERCIAL else "工業")
            draw_line(_v27_project_cell(Expansion.ANCHORS[i],0.8), rect.get_center(), Color("#8DA397"), 1.0)
            draw_rect(rect, Color(0.96,0.95,0.90,0.90))
            draw_string(font, rect.position+Vector2(4,17), Expansion.NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color("#173E30"))
            var can_grow: bool = int(zero_d_state["counts"][i]) < Expansion.REGION_LIMIT and not zero_d_state["candidates"][i].is_empty()
            var status: String = "成長中" if can_grow else ("街区" if int(zero_d_state["counts"][i]) > 3 else "用地")
            draw_string(font, rect.position+Vector2(4,34), kind + "・" + status, HORIZONTAL_ALIGNMENT_CENTER, 80, 10, Color("#667D70"))
    for p: Vector2i in zero_d_growth_marks:
        var pos: Vector2 = _v27_project_cell(p,0.3)
        if _v41_world_area().has_point(pos):
            draw_circle(pos, 9.0, Color(0.2,0.6,0.4,0.6), false, 2.0)
