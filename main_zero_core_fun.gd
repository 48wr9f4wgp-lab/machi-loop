extends "res://main_v44_core_fun.gd"

# AXIVA ZERO experimental core-fun mode.
# Normal v0.44 behavior is unchanged unless the Web URL contains ?zero=1.
# ZERO removes management explanation and asks one question:
# does drawing one road make the player want to draw the next one?

const ZERO_VILLAGE: Vector2i = Vector2i(1, 5)
const ZERO_STATION: Vector2i = Vector2i(14, 8)
const ZERO_INTERCHANGE: Vector2i = Vector2i(10, 20)
const ZERO_CASH: int = 9999

var zero_session: bool = false
var zero_landmark_count: int = 0
var zero_activated_until: Dictionary = {}
var zero_route_commits: int = 0

func _ready() -> void:
    zero_session = _zero_detect_session()
    super._ready()
    if not zero_session:
        return

    cash = ZERO_CASH
    unlocked_cols = GRID_W
    current_tool = Tool.ROAD
    v08_goal_stage = V08_GOAL_COUNT
    v42_pending_path.clear()
    v42_pending_plan.clear()
    _v10_sync_scene(true)
    queue_redraw()

func _zero_detect_session() -> bool:
    if not OS.has_feature("web"):
        return false
    var query_value: Variant = JavaScriptBridge.eval("window.location.search", true)
    return _zero_query_requests(str(query_value))

func _zero_query_requests(query: String) -> bool:
    var normalized: String = query.strip_edges()
    if normalized.begins_with("?"):
        normalized = normalized.substr(1)
    if normalized.is_empty():
        return false
    for raw_part: String in normalized.split("&"):
        if raw_part.strip_edges() == "zero=1":
            return true
    return false

func _v07_load_city() -> bool:
    if zero_session:
        return false
    return super._v07_load_city()

func _v07_save_city() -> void:
    if zero_session:
        return
    super._v07_save_city()

func _v42_build_label() -> String:
    if zero_session:
        return "ZERO"
    return super._v42_build_label()

# ---------------------------------------------------------------------------
# ZERO presentation: city, landmarks, one road tool. No economy/rank dashboard.
# ---------------------------------------------------------------------------

func _layout_tools(size: Vector2) -> void:
    if not zero_session:
        super._layout_tools(size)
        return

    tool_rects.clear()
    var side: float = 12.0
    var gap: float = 8.0
    var button_w: float = (size.x - side * 2.0 - gap) * 0.5
    var button_h: float = 54.0
    var y: float = size.y - V24_BOTTOM_H + 16.0
    tool_rects[Tool.ROAD] = Rect2(side, y, button_w, button_h)
    tool_rects[Tool.BULLDOZE] = Rect2(side + button_w + gap, y, button_w, button_h)

func _v23_draw_city_first_shell() -> void:
    if not zero_session:
        super._v23_draw_city_first_shell()
        return

    var size: Vector2 = get_viewport_rect().size
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font

    var top: Rect2 = Rect2(0.0, 0.0, size.x, V24_TOP_H)
    draw_rect(top, Color("#F3F0E6"))
    draw_line(Vector2(0.0, top.end.y), Vector2(size.x, top.end.y), Color("#CFD5CB"), 1.0)
    draw_string(font, Vector2(16.0, 30.0), "AXIVA ZERO",
        HORIZONTAL_ALIGNMENT_LEFT, 170.0, 16, Color("#173E30"))
    draw_string(font, Vector2(16.0, 54.0), "一本の道から、街が生まれる。",
        HORIZONTAL_ALIGNMENT_LEFT, size.x - 32.0, 9, Color("#667D70"))

    if _count_cells(Cell.ARTERIAL) == 0:
        var w: float = minf(250.0, board_rect.size.x - 32.0)
        var pill: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + 10.0, w, 32.0)
        draw_rect(pill, Color(0.055, 0.16, 0.115, 0.88))
        draw_string(font, pill.position + Vector2(8.0, 21.0), "一本だけ、道を引いてみよう",
            HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 16.0, 9, Color("#F7FFF9"))

    var bottom: Rect2 = Rect2(0.0, size.y - V24_BOTTOM_H, size.x, V24_BOTTOM_H)
    draw_rect(bottom, Color("#F3F0E6"))
    draw_line(Vector2(0.0, bottom.position.y), Vector2(size.x, bottom.position.y), Color("#CFD5CB"), 1.0)

    for id: int in [Tool.ROAD, Tool.BULLDOZE]:
        if not tool_rects.has(id):
            continue
        var rect: Rect2 = tool_rects[id] as Rect2
        var active: bool = current_tool == id
        var bg: Color = Color("#174B38") if active else Color("#E4E7DE")
        var fg: Color = Color.WHITE if active else Color("#274A3C")
        var label: String = "道を引く" if id == Tool.ROAD else "消す"
        draw_rect(rect, bg)
        draw_rect(rect, Color("#8DA397") if not active else Color("#174B38"), false, 1.0)
        draw_string(font, rect.position + Vector2(6.0, 34.0), label,
            HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 12, fg)

func _draw_banner(_size: Vector2) -> void:
    if zero_session:
        return
    super._draw_banner(_size)

func _v42_draw_overview_control(font: Font) -> void:
    if zero_session:
        return
    super._v42_draw_overview_control(font)

func _v42_draw_footer_hint(font: Font) -> void:
    if zero_session:
        return
    super._v42_draw_footer_hint(font)

func _v44_draw_growth_pulls() -> void:
    if zero_session:
        return
    super._v44_draw_growth_pulls()

func _v44_draw_route_choice() -> void:
    if zero_session:
        return
    super._v44_draw_route_choice()

func _v44_draw_route_feedback() -> void:
    if zero_session:
        return
    super._v44_draw_route_feedback()

func _v44_draw_widen_offer() -> void:
    if zero_session:
        return
    super._v44_draw_widen_offer()

func _v43_draw_recovery_payoff() -> void:
    if zero_session:
        return
    super._v43_draw_recovery_payoff()

func _v10_draw_preview_cost() -> void:
    if zero_session:
        return
    super._v10_draw_preview_cost()

func _v44_should_offer_widen() -> bool:
    if zero_session:
        return false
    return super._v44_should_offer_widen()

func _v41_world_area() -> Rect2:
    if not zero_session:
        return super._v41_world_area()
    return Rect2(board_rect.position, board_rect.size)

func _v41_ui_action(pos: Vector2) -> int:
    if not zero_session:
        return super._v41_ui_action(pos)
    for value: Variant in tool_rects:
        var rect: Rect2 = tool_rects[value] as Rect2
        if rect.has_point(pos):
            return int(value)
    return -1

func _v41_execute_ui(action: int) -> void:
    if not zero_session:
        super._v41_execute_ui(action)
        return
    _v41_cancel_edit()
    if action in [Tool.ROAD, Tool.BULLDOZE]:
        current_tool = action
        queue_redraw()

# ---------------------------------------------------------------------------
# World landmarks replace explanatory land labels.
# They are visual destinations; the same underlying derived affinities still
# shape autonomous development near whichever destination the road reaches.
# ---------------------------------------------------------------------------

func _v44_anchor(kind: int) -> Vector2i:
    if not zero_session:
        return super._v44_anchor(kind)
    match kind:
        Cell.RESIDENTIAL:
            return ZERO_VILLAGE
        Cell.COMMERCIAL:
            return ZERO_STATION
        Cell.INDUSTRIAL:
            return ZERO_INTERCHANGE
        _:
            return Vector2i(8, 11)

func _v10_create_materials() -> void:
    super._v10_create_materials()
    v10_materials["zero_platform"] = _v10_material(Color("#D8D0BF"), 0.94)
    v10_materials["zero_station"] = _v10_material(Color("#E9E4D8"), 0.88)
    v10_materials["zero_station_roof"] = _v10_material(Color("#496E63"), 0.86)
    v10_materials["zero_rail"] = _v10_material(Color("#4B5150"), 0.78)
    v10_materials["zero_highway"] = _v10_material(Color("#343937"), 0.90)
    v10_materials["zero_mark"] = _v10_material(Color("#E9C55F"), 0.80)
    v10_materials["zero_home"] = _v10_material(Color("#F1E7D7"), 0.92)
    v10_materials["zero_roof"] = _v10_material(Color("#B8644F"), 0.86)

func _v10_rebuild_static_city() -> void:
    super._v10_rebuild_static_city()
    if zero_session:
        _zero_add_landmarks()

func _zero_add_landmarks() -> void:
    zero_landmark_count = 0
    _zero_add_village()
    _zero_add_station()
    _zero_add_interchange()

func _zero_add_village() -> void:
    var root: Node3D = Node3D.new()
    root.name = "ZeroVillage"
    root.position = _v10_world_position(ZERO_VILLAGE, 0.0) + Vector3(-0.54, 0.0, -0.34)
    v10_static_root.add_child(root)

    var offsets: Array[Vector3] = [
        Vector3(-0.18, 0.0, -0.10),
        Vector3(0.18, 0.0, 0.10),
        Vector3(0.05, 0.0, -0.30)
    ]
    for i: int in range(offsets.size()):
        var off: Vector3 = offsets[i]
        _v10_add_box(root, off + Vector3(0.0, 0.18, 0.0),
            Vector3(0.28, 0.32, 0.26), v10_materials["zero_home"] as Material)
        _v10_add_box(root, off + Vector3(0.0, 0.37, 0.0),
            Vector3(0.32, 0.08, 0.30), v10_materials["zero_roof"] as Material)
    zero_landmark_count += 1

func _zero_add_station() -> void:
    var root: Node3D = Node3D.new()
    root.name = "ZeroStation"
    root.position = _v10_world_position(ZERO_STATION, 0.0) + Vector3(0.54, 0.0, 0.0)
    v10_static_root.add_child(root)

    _v10_add_box(root, Vector3(0.0, 0.08, 0.0),
        Vector3(0.92, 0.10, 0.34), v10_materials["zero_platform"] as Material, false)
    _v10_add_box(root, Vector3(0.18, 0.34, 0.0),
        Vector3(0.44, 0.50, 0.30), v10_materials["zero_station"] as Material)
    _v10_add_box(root, Vector3(0.18, 0.62, 0.0),
        Vector3(0.50, 0.08, 0.34), v10_materials["zero_station_roof"] as Material)
    _v10_add_box(root, Vector3(-0.32, 0.04, -0.16),
        Vector3(1.20, 0.035, 0.035), v10_materials["zero_rail"] as Material, false)
    _v10_add_box(root, Vector3(-0.32, 0.04, 0.16),
        Vector3(1.20, 0.035, 0.035), v10_materials["zero_rail"] as Material, false)
    zero_landmark_count += 1

func _zero_add_interchange() -> void:
    var root: Node3D = Node3D.new()
    root.name = "ZeroInterchange"
    root.position = _v10_world_position(ZERO_INTERCHANGE, 0.0) + Vector3(0.0, 0.0, 0.54)
    v10_static_root.add_child(root)

    _v10_add_box(root, Vector3(0.0, 0.065, 0.0),
        Vector3(1.55, 0.08, 0.42), v10_materials["zero_highway"] as Material, false)
    _v10_add_box(root, Vector3(0.0, 0.115, 0.0),
        Vector3(1.28, 0.012, 0.035), v10_materials["zero_mark"] as Material, false)
    _v10_add_box(root, Vector3(0.38, 0.075, -0.33),
        Vector3(0.42, 0.07, 0.66), v10_materials["zero_highway"] as Material, false)
    zero_landmark_count += 1

# ---------------------------------------------------------------------------
# Fast spectacle. Passive growth stays restrained, but each committed arterial
# releases a short one-arrival-per-tick wave. Reaching a landmark adds more.
# ---------------------------------------------------------------------------

func _zero_landmark_connected(anchor: Vector2i) -> bool:
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            if not _v04_is_road(p):
                continue
            if absi(p.x - anchor.x) + absi(p.y - anchor.y) <= 1:
                return true
    return false

func _zero_connection_snapshot() -> Dictionary:
    return {
        "village": _zero_landmark_connected(ZERO_VILLAGE),
        "station": _zero_landmark_connected(ZERO_STATION),
        "interchange": _zero_landmark_connected(ZERO_INTERCHANGE)
    }

func _zero_note_new_connections(before: Dictionary) -> int:
    var count: int = 0
    var entries: Array = [
        ["village", ZERO_VILLAGE],
        ["station", ZERO_STATION],
        ["interchange", ZERO_INTERCHANGE]
    ]
    for value: Variant in entries:
        var entry: Array = value as Array
        var key: String = str(entry[0])
        var anchor: Vector2i = entry[1] as Vector2i
        if not bool(before.get(key, false)) and _zero_landmark_connected(anchor):
            zero_activated_until[key] = v04_time + 2.4
            _v04_add_fx(anchor, "road", "")
            count += 1
    return count

func _commit_arterial() -> void:
    if not zero_session:
        super._commit_arterial()
        return

    var first: bool = _count_cells(Cell.ARTERIAL) == 0
    var before_commits: int = v40_commit_count
    var connections_before: Dictionary = _zero_connection_snapshot()

    v42_confirming = true
    super._commit_arterial()
    v42_confirming = false
    cash = ZERO_CASH

    if v40_commit_count == before_commits:
        return

    zero_route_commits += 1
    var new_connections: int = _zero_note_new_connections(connections_before)

    if first:
        v42_arrivals.assign([
            Cell.LOCAL,
            Cell.RESIDENTIAL,
            Cell.RESIDENTIAL,
            Cell.LOCAL,
            Cell.COMMERCIAL,
            Cell.RESIDENTIAL,
            Cell.LOCAL,
            Cell.RESIDENTIAL,
            Cell.COMMERCIAL,
            Cell.RESIDENTIAL
        ])
    else:
        v42_arrivals.assign([-1, Cell.LOCAL, -1, -1, Cell.LOCAL, -1])

    for _i: int in range(new_connections * 3):
        v42_arrivals.append(-1)

    v42_arrival_tick = tick_count - 1
    v42_pending_path.clear()
    v42_pending_plan.clear()

func _simulation_tick() -> void:
    if zero_session and not v42_arrivals.is_empty():
        v42_arrival_tick = mini(v42_arrival_tick, tick_count - 1)
    super._simulation_tick()
    if zero_session:
        cash = ZERO_CASH

func _draw() -> void:
    super._draw()
    if zero_session:
        _zero_draw_activation()

func _zero_draw_activation() -> void:
    if zero_activated_until.is_empty():
        return

    var entries: Array = [
        ["village", ZERO_VILLAGE],
        ["station", ZERO_STATION],
        ["interchange", ZERO_INTERCHANGE]
    ]
    for value: Variant in entries:
        var entry: Array = value as Array
        var key: String = str(entry[0])
        var until: float = float(zero_activated_until.get(key, -1.0))
        if v04_time >= until:
            continue
        var anchor: Vector2i = entry[1] as Vector2i
        var screen: Vector2 = _v27_project_cell(anchor, 0.35)
        if not board_rect.has_point(screen):
            continue
        var age_left: float = until - v04_time
        var pulse: float = 0.5 + 0.5 * sin(v04_time * 7.0)
        var alpha: float = clampf(age_left / 0.35, 0.0, 1.0)
        draw_circle(screen, 18.0 + pulse * 8.0, Color(0.92, 0.76, 0.28, 0.35 * alpha), false, 2.4)
