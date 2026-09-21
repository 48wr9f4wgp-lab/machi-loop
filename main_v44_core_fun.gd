extends "res://main_v43_tempo_payoff.gd"

# AXIVA v0.44 - Core Fun Rebuild.
# Goal: make the next arterial a meaningful choice.
# - all slice land is playable from the start; no unexplained locked-white strip;
# - WIDEN is contextual instead of a permanent unexplained tool;
# - three derived land potentials bias autonomous growth, so route direction
#   changes what kind of city emerges without allowing direct building placement;
# - widening is a quick capacity fix, while a bypass can unlock fresh growth.
#
# Vertical Slice working rules only. No save-schema or release changes.

const V44_WIDEN_ACTION: int = 94
const V44_RESIDENTIAL_ANCHOR: Vector2i = Vector2i(3, 5)
const V44_COMMERCIAL_ANCHOR: Vector2i = Vector2i(8, 10)
const V44_INDUSTRIAL_ANCHOR: Vector2i = Vector2i(13, 16)
const V44_ATTRACTOR_RADIUS: float = 12.0
const V44_ROUTE_FEEDBACK_SECONDS: float = 2.8

var v44_last_route_kind: int = Cell.RESIDENTIAL
var v44_route_feedback_until: float = -1000.0
var v44_last_recovery_was_widen: bool = false

func _v42_build_label() -> String:
    return "v0.44"

# ---------------------------------------------------------------------------
# Full playable land. Population progression remains, but no map column is
# hidden behind a white/locked presentation in the Vertical Slice.
# ---------------------------------------------------------------------------

func _v35_prepare_width_before_renderer() -> void:
    unlocked_cols = GRID_W

func _v35_desired_unlocked_cols(_pop: int) -> int:
    return GRID_W

func _check_unlocks() -> void:
    var target_level: int = 1
    if population >= 90:
        target_level = 2
    if population >= 200:
        target_level = 3
    if population >= 360:
        target_level = 4

    if target_level > city_level:
        city_level = target_level
        var reward: int = 180 * target_level
        cash += reward
        _toast("CITY LV %d  +Y%d" % [city_level, reward])

    unlocked_cols = GRID_W

# ---------------------------------------------------------------------------
# Only the everyday tools stay in the permanent bar. Widening appears when the
# city has a traffic problem, next to the road it can actually help.
# ---------------------------------------------------------------------------

func _layout_tools(size: Vector2) -> void:
    tool_rects.clear()
    var gap: float = 8.0
    var side: float = 12.0
    var button_w: float = (size.x - side * 2.0 - gap) * 0.5
    var button_h: float = 54.0
    var y: float = size.y - V24_BOTTOM_H + 16.0
    tool_rects[Tool.ROAD] = Rect2(side, y, button_w, button_h)
    tool_rects[Tool.BULLDOZE] = Rect2(side + button_w + gap, y, button_w, button_h)

func _v44_widen_target() -> Vector2i:
    var target: Vector2i = Vector2i(-1, -1)
    if v29_recovery_stage in [V29_STAGE_PROBLEM, V29_STAGE_INTERVENTION]:
        target = v29_problem_anchor
    elif v16_traffic_status in ["warning", "severe"]:
        target = _v29_find_worst_arterial()

    if not _in_bounds(target) or target.x >= unlocked_cols:
        return Vector2i(-1, -1)
    if int(grid[target.y][target.x]) != Cell.ARTERIAL:
        return Vector2i(-1, -1)
    if widened.has(_key(target)):
        return Vector2i(-1, -1)
    return target

func _v44_should_offer_widen() -> bool:
    if dragging or not v42_pending_path.is_empty():
        return false
    if v16_traffic_status not in ["warning", "severe"] and v29_recovery_stage not in [V29_STAGE_PROBLEM, V29_STAGE_INTERVENTION]:
        return false
    return _v44_widen_target().x >= 0

func _v44_widen_card_rect() -> Rect2:
    return Rect2(
        board_rect.position.x + 8.0,
        board_rect.end.y - 126.0,
        board_rect.size.x - 16.0,
        72.0
    )

func _v44_widen_button_rect() -> Rect2:
    var card: Rect2 = _v44_widen_card_rect()
    return Rect2(card.end.x - 126.0, card.position.y + 17.0, 116.0, 40.0)

func _v41_ui_action(pos: Vector2) -> int:
    if _v44_should_offer_widen() and _v44_widen_button_rect().has_point(pos):
        return V44_WIDEN_ACTION
    return super._v41_ui_action(pos)

func _v41_execute_ui(action: int) -> void:
    if action == V44_WIDEN_ACTION:
        var target: Vector2i = _v44_widen_target()
        if target.x >= 0:
            _widen(target)
        queue_redraw()
        return
    super._v41_execute_ui(action)

# ---------------------------------------------------------------------------
# Land potential. These are simulation-owned tendencies, not zones placed by
# the player. The road decides which tendency becomes accessible.
# ---------------------------------------------------------------------------

func _v44_anchor(kind: int) -> Vector2i:
    match kind:
        Cell.RESIDENTIAL:
            return V44_RESIDENTIAL_ANCHOR
        Cell.COMMERCIAL:
            return V44_COMMERCIAL_ANCHOR
        Cell.INDUSTRIAL:
            return V44_INDUSTRIAL_ANCHOR
        _:
            return Vector2i(int(GRID_W / 2), int(GRID_H / 2))

func _v44_affinity(p: Vector2i, kind: int) -> float:
    var anchor: Vector2i = _v44_anchor(kind)
    var distance: float = float(absi(p.x - anchor.x) + absi(p.y - anchor.y))
    return clampf(1.0 - distance / V44_ATTRACTOR_RADIUS, 0.0, 1.0)

func _v44_land_kind(p: Vector2i) -> int:
    var best_kind: int = Cell.RESIDENTIAL
    var best: float = -1.0
    for kind: int in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
        var affinity: float = _v44_affinity(p, kind)
        if affinity > best:
            best = affinity
            best_kind = kind
    return best_kind

func _v44_demand_for_kind(kind: int) -> int:
    match kind:
        Cell.RESIDENTIAL:
            return v15_residential_demand
        Cell.COMMERCIAL:
            return v15_commercial_demand
        Cell.INDUSTRIAL:
            return v15_industrial_demand
        _:
            return 0

func _v15_pick_growth_candidate(candidates: Array) -> Vector2i:
    if candidates.is_empty():
        return Vector2i(-1, -1)

    var weights: Array[float] = []
    var total: float = 0.0
    for value: Variant in candidates:
        var p: Vector2i = value as Vector2i
        var kind: int = _v44_land_kind(p)
        var score: float = 0.40
        score += _v44_affinity(p, kind) * 1.75
        score += float(_v44_demand_for_kind(kind)) / 100.0 * 0.70
        if _distance_to_arterial(p) == 1:
            score += 0.20
        score = maxf(0.05, score)
        weights.append(score)
        total += score

    var roll: float = rng.randf() * total
    for i: int in range(candidates.size()):
        roll -= weights[i]
        if roll <= 0.0:
            return candidates[i] as Vector2i
    return candidates.back() as Vector2i

func _v15_choose_building_for_cell(p: Vector2i) -> int:
    if _count_cells(Cell.RESIDENTIAL) < 2:
        return Cell.RESIDENTIAL

    var kind: int = _v44_land_kind(p)
    var local_bias: float = 0.58 + _v44_affinity(p, kind) * 0.27
    if rng.randf() < local_bias:
        return kind
    return _choose_building_type()

func _v44_pick_arrival_candidate(candidates: Array[Vector2i], requested_kind: int) -> Vector2i:
    if candidates.is_empty():
        return Vector2i(-1, -1)

    var weights: Array[float] = []
    var total: float = 0.0
    for p: Vector2i in candidates:
        var kind: int = requested_kind
        if kind not in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
            kind = _v44_land_kind(p)
        var score: float = 0.35 + _v44_affinity(p, kind) * 2.20
        score += float(_v44_demand_for_kind(kind)) / 100.0 * 0.45
        score = maxf(0.05, score)
        weights.append(score)
        total += score

    var roll: float = rng.randf() * total
    for i: int in range(candidates.size()):
        roll -= weights[i]
        if roll <= 0.0:
            return candidates[i]
    return candidates.back()

func _v42_arrive_near_road(kind: int) -> void:
    var candidates: Array[Vector2i] = []
    for value: Variant in v42_response_cells:
        var road: Vector2i = value as Vector2i
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

    var p: Vector2i = _v44_pick_arrival_candidate(candidates, kind)
    if p.x < 0:
        return

    var actual_kind: int = kind
    if actual_kind == -1:
        actual_kind = _v15_choose_building_for_cell(p)

    var before_count: int = _v29_building_count()
    grid[p.y][p.x] = actual_kind
    v42_response_count += 1
    if actual_kind == Cell.LOCAL:
        _v04_add_fx(p, "local", "")
        if v28_sequence_active:
            _v28_note_local_road(p)
    else:
        _v27_schedule_growth(p, false)
        if actual_kind == Cell.COMMERCIAL and v28_sequence_active:
            _v28_note_commercial(p)

    _recalculate_city()
    _v28_maybe_reveal()
    _v29_note_growth_resume(before_count)
    _v10_sync_scene()
    _v07_save_city()

func _v44_path_pull_kind(path: Array) -> int:
    if path.is_empty():
        return Cell.RESIDENTIAL
    var best_kind: int = Cell.RESIDENTIAL
    var best_score: float = -1.0
    for kind: int in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
        var score: float = 0.0
        for value: Variant in path:
            score += _v44_affinity(value as Vector2i, kind)
        if score > best_score:
            best_score = score
            best_kind = kind
    return best_kind

func _v44_kind_name(kind: int) -> String:
    match kind:
        Cell.RESIDENTIAL:
            return "住宅"
        Cell.COMMERCIAL:
            return "商業"
        Cell.INDUSTRIAL:
            return "産業"
        _:
            return "街"

func _commit_arterial() -> void:
    var route_kind: int = _v44_path_pull_kind(drag_path)
    var before: int = v40_commit_count
    super._commit_arterial()
    if v40_commit_count > before:
        v44_last_route_kind = route_kind
        v44_route_feedback_until = v04_time + V44_ROUTE_FEEDBACK_SECONDS

# ---------------------------------------------------------------------------
# Widen vs bypass is a real choice. Widening can recover traffic quickly but
# does not receive the extra route-attributed growth beat. A new route does.
# ---------------------------------------------------------------------------

func _v29_begin_recovery() -> void:
    var was_widen: bool = v42_widen_intervention
    super._v29_begin_recovery()
    v44_last_recovery_was_widen = was_widen
    if was_widen:
        v42_arrivals.clear()

func _v23_context_message() -> String:
    if _count_cells(Cell.ARTERIAL) == 0:
        return "土地の特徴を見て、最初の幹線を引こう"
    if v29_recovery_stage in [V29_STAGE_PROBLEM, V29_STAGE_INTERVENTION]:
        return "混雑発生・拡幅でしのぐ？ 新ルートで街を広げる？"
    return super._v23_context_message()

# ---------------------------------------------------------------------------
# City-as-UI explanation: subtle in-world growth pulls, direct road preview,
# and contextual widening card.
# ---------------------------------------------------------------------------

func _draw() -> void:
    super._draw()
    _v44_draw_growth_pulls()
    _v44_draw_route_choice()
    _v44_draw_widen_offer()
    _v44_draw_route_feedback()

func _v44_pull_color(kind: int, alpha: float) -> Color:
    match kind:
        Cell.RESIDENTIAL:
            return Color(0.28, 0.58, 0.30, alpha)
        Cell.COMMERCIAL:
            return Color(0.24, 0.52, 0.70, alpha)
        Cell.INDUSTRIAL:
            return Color(0.68, 0.48, 0.22, alpha)
        _:
            return Color(0.30, 0.50, 0.36, alpha)

func _v44_draw_growth_pulls() -> void:
    if current_tool != Tool.ROAD or dragging or not v42_pending_path.is_empty():
        return
    if v29_recovery_stage in [V29_STAGE_PROBLEM, V29_STAGE_INTERVENTION]:
        return
    if population >= 180:
        return

    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var items: Array = [
        [Cell.RESIDENTIAL, "住宅人気"],
        [Cell.COMMERCIAL, "商業中心候補"],
        [Cell.INDUSTRIAL, "産業適地"]
    ]
    for item: Variant in items:
        var tuple: Array = item as Array
        var kind: int = int(tuple[0])
        var screen: Vector2 = _v27_project_cell(_v44_anchor(kind), 0.18)
        if not _v41_world_area().has_point(screen):
            continue
        var color: Color = _v44_pull_color(kind, 0.62)
        draw_circle(screen, 19.0, color, false, 2.0)
        var w: float = 86.0 if kind != Cell.COMMERCIAL else 100.0
        var pill: Rect2 = Rect2(screen.x - w * 0.5, screen.y - 38.0, w, 22.0)
        draw_rect(pill, Color(0.96, 0.95, 0.90, 0.90))
        draw_rect(pill, color, false, 1.0)
        draw_string(font, pill.position + Vector2(5.0, 15.0), str(tuple[1]),
            HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 10.0, 8, Color("#173E30"))

func _v44_draw_route_choice() -> void:
    if not dragging or current_tool != Tool.ROAD or drag_path.size() < 2:
        return
    var kind: int = _v44_path_pull_kind(drag_path)
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var w: float = 196.0
    var rect: Rect2 = Rect2(
        board_rect.get_center().x - w * 0.5,
        _v41_world_area().position.y + 12.0,
        w,
        30.0
    )
    draw_rect(rect, Color(0.96, 0.95, 0.90, 0.94))
    draw_rect(rect, _v44_pull_color(kind, 0.78), false, 2.0)
    draw_string(font, rect.position + Vector2(8.0, 20.0),
        "この道 → %sが伸びやすい" % _v44_kind_name(kind),
        HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 9, Color("#173E30"))

func _v44_draw_route_feedback() -> void:
    if v04_time > v44_route_feedback_until:
        return
    var remaining: float = v44_route_feedback_until - v04_time
    var alpha: float = clampf(remaining / 0.35, 0.0, 1.0)
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var w: float = 180.0
    var rect: Rect2 = Rect2(
        board_rect.get_center().x - w * 0.5,
        _v41_world_area().position.y + 50.0,
        w,
        28.0
    )
    draw_rect(rect, Color(0.055, 0.16, 0.115, 0.90 * alpha))
    draw_string(font, rect.position + Vector2(8.0, 19.0),
        "%s方面へ街が反応" % _v44_kind_name(v44_last_route_kind),
        HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 9, Color(0.97, 1.0, 0.97, alpha))

func _v44_draw_widen_offer() -> void:
    if not _v44_should_offer_widen():
        return

    var card: Rect2 = _v44_widen_card_rect()
    var button: Rect2 = _v44_widen_button_rect()
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    draw_rect(card, Color(0.96, 0.95, 0.90, 0.97))
    draw_rect(card, Color("#D99545"), false, 1.0)

    draw_string(font, card.position + Vector2(10.0, 20.0),
        "混雑した幹線", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 148.0, 10, Color("#173E30"))
    draw_string(font, card.position + Vector2(10.0, 38.0),
        "拡幅＝今の1区間を強化", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 148.0, 8, Color("#50665A"))
    draw_string(font, card.position + Vector2(10.0, 55.0),
        "新ルート＝周辺にも新しい成長", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 148.0, 8, Color("#50665A"))

    var button_bg: Color = Color("#174B38") if cash >= WIDEN_COST else Color("#7B817D")
    draw_rect(button, button_bg)
    draw_string(font, button.position + Vector2(5.0, 25.0),
        "拡幅 ¥%d" % WIDEN_COST if cash >= WIDEN_COST else "資金不足",
        HORIZONTAL_ALIGNMENT_CENTER, button.size.x - 10.0, 10, Color.WHITE)

func _v43_draw_recovery_payoff() -> void:
    if v43_recovery_tick < 0:
        return
    var age: float = v04_time - v43_recovery_started_at
    if age < 0.0 or age > V43_RECOVERY_CALLOUT_SECONDS:
        return

    var alpha: float = minf(1.0, age / 0.18)
    alpha *= minf(1.0, (V43_RECOVERY_CALLOUT_SECONDS - age) / 0.42)

    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var w: float = minf(310.0, board_rect.size.x - 24.0)
    var rect: Rect2 = Rect2(
        board_rect.get_center().x - w * 0.5,
        _v41_world_area().position.y + 10.0,
        w,
        62.0
    )
    draw_rect(rect, Color(0.045, 0.16, 0.105, 0.94 * alpha))
    draw_rect(rect, Color(0.38, 0.88, 0.64, 0.95 * alpha), false, 2.0)

    var headline: String = "交通 %d%% → %d%%・%dpt改善" % [
        int(round(v43_recovery_from)),
        int(round(v43_recovery_to)),
        int(round(v43_last_recovery_drop))
    ]
    draw_string(font, rect.position + Vector2(8.0, 25.0), headline,
        HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 12, Color(0.97, 1.0, 0.97, alpha))

    var detail: String = (
        "拡幅：すぐ改善・街の骨格はそのまま"
        if v44_last_recovery_was_widen
        else "新ルート：交通分散＋沿道に新しい成長"
    )
    draw_string(font, rect.position + Vector2(8.0, 47.0), detail,
        HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 8, Color(0.78, 0.94, 0.85, alpha))
