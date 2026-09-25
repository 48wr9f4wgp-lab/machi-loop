extends "res://main_zero_d_expansion.gd"

const Choice = preload("res://domain/zero_e_road_choice.gd")
const GraphE = preload("res://domain/zero_c_network.gd")
var zero_e_session: bool = false
var zero_e_state: Dictionary = {}
var zero_e_initial_buildings: int = 0
var zero_e_response: String = ""
var zero_e_response_until: float = -1.0

func _ready() -> void:
    zero_e_session = _zero_e_detect_session()
    super._ready()
    if zero_e_session:
        _zero_e_recalculate()
        _v10_sync_scene()

func _zero_e_query_requests(query: String) -> bool:
    return query.trim_prefix("?").split("&").has("zero=e")

func _zero_e_detect_session() -> bool:
    if OS.get_cmdline_user_args().has("--zero-e"):
        return true
    return OS.has_feature("web") and _zero_e_query_requests(str(JavaScriptBridge.eval("window.location.search", true)))

func _v37_detect_recovery_session() -> bool:
    return zero_e_session or super._v37_detect_recovery_session()

func _v37_seed_recovery_fixture() -> void:
    if not zero_e_session:
        super._v37_seed_recovery_fixture()
        return
    _init_grid()
    widened.clear()
    unlocked_cols = GRID_W
    city_level = 4
    cash = 3000
    tick_count = 0
    paused = false
    current_tool = Tool.ROAD
    v04_first_growth_seeded = true
    v23_birth_started = true
    v23_birth_announced = true
    v28_sequence_active = false
    v29_recovery_stage = V29_STAGE_NONE
    zero_e_state.clear()
    zero_e_response = ""
    zero_e_response_until = -1.0
    for x: int in range(Choice.WEST.x, Choice.EAST.x + 1):
        grid[10][x] = Cell.ARTERIAL
    # Lived-in blocks leave two genuine, spatially separated possible bypasses.
    # Neither route is pre-drawn or prescribed to the player.
    for x: int in range(4, 12):
        grid[8][x] = Cell.RESIDENTIAL
        grid[12][x] = Cell.RESIDENTIAL
    for x: int in range(4, 8):
        grid[6][x] = Cell.COMMERCIAL
        grid[14][x] = Cell.INDUSTRIAL
    # Give the congested street an actual built frontage while leaving room
    # for short experiments beside it and full north/south bypasses at 7/13.
    for x: int in [4, 5, 9, 10, 11]:
        grid[9][x] = Cell.RESIDENTIAL if x % 3 else Cell.COMMERCIAL
        grid[11][x] = Cell.RESIDENTIAL
    for x: int in [2, 13]:
        grid[8][x] = Cell.RESIDENTIAL
        grid[12][x] = Cell.RESIDENTIAL
    zero_e_initial_buildings = _v29_building_count()
    _recalculate_city()
    v37_fixture_seed_count += 1

func _v29_observe_traffic_state() -> void:
    if not zero_e_session:
        super._v29_observe_traffic_state()

func _recalculate_city() -> void:
    super._recalculate_city()
    if zero_e_session:
        _zero_e_recalculate()

func _zero_e_recalculate() -> void:
    if grid.is_empty():
        return
    var previous: Dictionary = zero_e_state
    zero_e_state = Choice.analyze(grid)
    congestion = zero_e_state["peak"] * 65.0
    v16_traffic_status = "severe" if float(zero_e_state["peak"]) > 1.0 else "good"
    v16_traffic_cause = "no_redundancy" if v16_traffic_status == "severe" else "none"
    if previous.is_empty():
        return
    var old_routes: int = previous["routes"].size()
    var new_routes: int = zero_e_state["routes"].size()
    if new_routes > old_routes and float(zero_e_state["peak"]) < float(previous["peak"]):
        zero_e_response = "別の道に車が流れ、混雑が減った"
        zero_e_response_until = v04_time + 5.0
    elif new_routes < old_routes:
        zero_e_response = "迂回路が切れ、交通が集中した"
        zero_e_response_until = v04_time + 5.0

func _simulation_tick() -> void:
    if not zero_e_session:
        super._simulation_tick()
        return
    if paused or dragging or v41_single_down or v41_navigation_gesture_active:
        return
    tick_count += 1
    _auto_grow_buildings()
    _recalculate_city()
    _v10_sync_scene()
    queue_redraw()

func _auto_grow_buildings() -> void:
    if not zero_e_session:
        super._auto_grow_buildings()
        return
    if zero_e_state.get("routes", []).size() < 2 or float(zero_e_state["peak"]) > 1.0:
        return
    if _v29_building_count() >= zero_e_initial_buildings + 8:
        return
    var alternative: Array = zero_e_state["routes"][1]
    for value: Variant in alternative:
        var road: Vector2i = value
        for d: Vector2i in GraphE.DIRS:
            var p: Vector2i = road + d
            if not _in_bounds(p) or int(grid[p.y][p.x]) != Cell.EMPTY:
                continue
            if p.y == 10 or _adjacent_road_count(p) == 0:
                continue
            grid[p.y][p.x] = Cell.COMMERCIAL if p.y < 10 else Cell.RESIDENTIAL
            _v27_schedule_growth(p, false)
            zero_e_response = "新しい道の沿線にも街が育った"
            zero_e_response_until = v04_time + 4.0
            return

func _v07_save_city() -> void:
    if not zero_e_session:
        super._v07_save_city()

func _v10_update_vehicles() -> void:
    if not zero_e_session or zero_e_state.get("routes", []).is_empty():
        super._v10_update_vehicles()
        return
    if paused:
        return
    var routes: Array = zero_e_state["routes"]
    for i: int in range(v10_vehicle_nodes.size()):
        var car: Node3D = v10_vehicle_nodes[i] as Node3D
        var route: Array = routes[i % routes.size()]
        if route.size() < 2 or not is_instance_valid(car):
            continue
        var progress: float = float(car.get_meta("zero_e_progress", float(i) * 1.7))
        var last_time: float = float(car.get_meta("zero_e_time", v04_time))
        var segment: int = int(progress) % (route.size() - 1)
        var edge: String = GraphE.edge_key(route[segment], route[segment + 1])
        var ratio: float = float(zero_e_state["loads"].get(edge, 0.0)) / Choice.CAPACITY
        var speed: float = 0.20 if ratio > 1.0 else 1.6
        progress += clampf(v04_time - last_time, 0.0, 0.1) * speed
        car.set_meta("zero_e_progress", progress)
        car.set_meta("zero_e_time", v04_time)
        segment = int(progress) % (route.size() - 1)
        var a: Vector3 = _v10_world_position(route[segment], 0.18)
        var b: Vector3 = _v10_world_position(route[segment + 1], 0.18)
        var direction: Vector3 = (b - a).normalized()
        car.position = a.lerp(b, fmod(progress, 1.0)) + Vector3(-direction.z, 0.0, direction.x) * 0.14
        car.rotation.y = -atan2(direction.z, direction.x)

func _v42_build_label() -> String:
    return "ZERO E" if zero_e_session else super._v42_build_label()

func _v16_draw_traffic_diagnosis() -> void:
    if not zero_e_session:
        super._v16_draw_traffic_diagnosis()

func _v23_draw_city_first_shell() -> void:
    super._v23_draw_city_first_shell()
    if not zero_e_session:
        return
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(12, 10, size.x - 24, 51), Color("#F3F0E6"))
    draw_string(font, Vector2(16, 30), "AXIVA ZERO E", HORIZONTAL_ALIGNMENT_LEFT, 190, 16, Color("#173E30"))
    draw_string(font, Vector2(16, 54), "道の選び方で、街の流れは変わる？", HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 11, Color("#667D70"))
    var hint: String = zero_e_response if zero_e_response_until > v04_time else ("この通りに車が集中している" if float(zero_e_state.get("peak", 0.0)) > 1.0 else "沿道に街が育っている")
    var panel: Rect2 = Rect2(board_rect.position.x + 8, board_rect.end.y - 40, board_rect.size.x - 16, 32)
    draw_rect(panel, Color(0.06, 0.16, 0.12, 0.90))
    draw_string(font, panel.position + Vector2(6, 21), hint, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 12, 11, Color.WHITE)

func _draw() -> void:
    super._draw()
    if not zero_e_session or zero_e_state.is_empty():
        return
    # The road edge and actual cars carry the diagnosis. A single small marker
    # locates the initial bottleneck without covering the world in UI rings.
    if float(zero_e_state["peak"]) > 1.0:
        var screen: Vector2 = _v27_project_cell(Vector2i(8, 10), 0.28)
        if _v41_world_area().has_point(screen):
            draw_circle(screen, 6.0, Color(0.92, 0.38, 0.22, 0.82), false, 1.5)
