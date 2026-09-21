extends "res://main_zero_b_core_fun.gd"

const ZeroCNetwork = preload("res://domain/zero_c_network.gd")
const ZERO_C_STAGES: Array[String] = ["集落", "町", "小都市", "都市", "大都市", "メトロポリス"]
const ZERO_C_DESTINATIONS: Array[String] = ["住宅地", "駅", "物流拠点"]
var zero_c_effect: String = ""
var zero_c_effect_until: float = -1.0
var zero_c_road_marks: Array[Vector2i] = []
var zero_c_growth_marks: Dictionary = {}
var zero_c_stage_notice: String = ""
var zero_c_stage_until: float = -1.0
var zero_c_session: bool = false
var zero_c_state: Dictionary = {}
var zero_c_grid_hash: int = -1
var zero_c_stable_ticks: int = 0
var zero_c_metropolis: bool = false
var zero_c_earned_once: bool = false
var zero_c_reveal: float = 0.0
var zero_c_stage: int = 0
var zero_c_was_stalled: bool = false
var zero_c_recovery_until: float = -1.0

func _ready() -> void:
    zero_c_session = _zero_c_detect_session()
    super._ready()
    if zero_c_session:
        _recalculate_city()
        _v10_sync_scene(true)

func _zero_c_query_requests(query: String) -> bool:
    return query.trim_prefix("?").split("&").has("zero=c")

func _zero_c_detect_session() -> bool:
    if OS.get_cmdline_user_args().has("--zero-c"):
        return true
    return OS.has_feature("web") and _zero_c_query_requests(str(JavaScriptBridge.eval("window.location.search", true)))

func _zero_detect_session() -> bool:
    return zero_c_session or super._zero_detect_session()

func _zero_b_detect_session() -> bool:
    return zero_c_session or super._zero_b_detect_session()

func _v20_load_ftue_stage() -> int:
    return 0 if zero_c_session else super._v20_load_ftue_stage()

func _v20_save_ftue() -> void:
    if not zero_c_session:
        super._v20_save_ftue()

func _v33_delete_persistent_city_state() -> void:
    if not zero_c_session:
        super._v33_delete_persistent_city_state()

func _v42_build_label() -> String:
    return "ZERO C2" if zero_c_session else super._v42_build_label()

func _zero_c_refresh() -> void:
    if grid.is_empty():
        return
    var signature: int = hash(grid)
    if signature == zero_c_grid_hash and not zero_c_state.is_empty():
        return
    zero_c_grid_hash = signature
    zero_c_state = ZeroCNetwork.analyze(grid)
    if not bool(zero_c_state["ready"]) or zero_c_state["buildings"].size() < ZeroCNetwork.LARGE_CITY:
        zero_c_stable_ticks = 0
        zero_c_metropolis = false
    var next_stage: int = ZeroCNetwork.stage(zero_c_state["buildings"].size(), zero_c_metropolis)
    if next_stage > zero_c_stage:
        zero_c_stage_notice = ZERO_C_STAGES[next_stage] + "へ。道の周りに街が育った"
        zero_c_stage_until = v04_time + 4.5
    zero_c_stage = next_stage

func _recalculate_city() -> void:
    super._recalculate_city()
    if not zero_c_session:
        return
    _zero_c_refresh()
    if zero_c_state.is_empty():
        return
    congestion = float(zero_c_state["peak"]) * 65.0
    v16_traffic_status = "severe" if float(zero_c_state["peak"]) > 1.0 else "good"
    v16_traffic_cause = "no_redundancy" if float(zero_c_state["peak"]) > 1.0 else "none"
    _check_unlocks()

func _check_unlocks() -> void:
    if not zero_c_session:
        super._check_unlocks()
        return
    unlocked_cols = GRID_W
    city_level = zero_c_stage + 1

func _zero_landmark_connected(anchor: Vector2i) -> bool:
    if not zero_c_session:
        return super._zero_landmark_connected(anchor)
    _zero_c_refresh()
    var index: int = ZeroCNetwork.ANCHORS.find(anchor)
    return index >= 0 and not zero_c_state.is_empty() and (zero_c_state["ports"][index] as Vector2i).x >= 0

func _commit_arterial() -> void:
    var before: Dictionary = zero_c_state.duplicate(true) if zero_c_session else {}
    var commits: int = v40_commit_count
    super._commit_arterial()
    if zero_c_session:
        # C owns growth/traffic; inherited route waves must not bypass its cap.
        v42_arrivals.clear()
        _recalculate_city()
        if v40_commit_count > commits:
            if _zero_c_note_edit(before, false):
                zero_c_road_marks.assign(v40_last_result.get("cells", []))
        _v10_sync_scene()

func _bulldoze(p: Vector2i) -> void:
    if not _in_bounds(p):
        return
    var before: Dictionary = zero_c_state.duplicate(true) if zero_c_session else {}
    var prior: int = int(grid[p.y][p.x])
    super._bulldoze(p)
    if zero_c_session:
        cash = ZERO_CASH
        _recalculate_city()
        if prior != int(grid[p.y][p.x]):
            zero_c_road_marks.clear()
            _zero_c_note_edit(before, true)
        _v10_sync_scene()

func _zero_c_note_edit(before: Dictionary, removed: bool) -> bool:
    if before.is_empty() or zero_c_state.is_empty():
        return false
    var message: String = ""
    if int(zero_c_state["connected"]) < int(before["connected"]):
        message = "拠点への道が切れた。つなぎ直そう"
    elif zero_c_state["cramped"].size() > before["cramped"].size():
        message = "道で土地が細切れに。街区を広く残そう"
    elif removed and _zero_c_spacious_total(zero_c_state) > _zero_c_spacious_total(before):
        message = "土地がまとまり、中心地が育つ余地に"
    else:
        for i: int in range(3):
            if (before["ports"][i] as Vector2i).x < 0 and (zero_c_state["ports"][i] as Vector2i).x >= 0:
                message = ZERO_C_DESTINATIONS[i] + "につながった。周りの成長を見よう"
                break
        if message.is_empty() and not removed and int(zero_c_state["redundant_pairs"]) > int(before["redundant_pairs"]):
            message = "通り道が増え、車の流れが分かれた"
        if message.is_empty() and not removed and zero_c_state["accessible"].size() > before["accessible"].size():
            message = "道が伸びた。沿道に育つ土地を残そう"
    # No-op edits never fabricate success or erase the last useful feedback.
    if not message.is_empty():
        zero_c_effect = message
        zero_c_effect_until = v04_time + 5.0
        return true
    return false

func _zero_c_spacious_total(state: Dictionary) -> int:
    var total: int = 0
    for count: int in state.get("spacious", []):
        total += count
    return total

func _v27_schedule_growth(p: Vector2i, first_birth: bool) -> void:
    super._v27_schedule_growth(p, first_birth)
    if zero_c_session:
        zero_c_growth_marks[p] = v04_time + 2.5

func _simulation_tick() -> void:
    if not zero_c_session:
        super._simulation_tick()
        return
    if paused or dragging or v41_single_down or not v42_pending_path.is_empty():
        return
    var previous: int = tick_count
    var stalled_before: bool = _zero_c_stalled()
    super._simulation_tick()
    if tick_count == previous:
        return
    _zero_c_refresh()
    if bool(zero_c_state.get("ready", false)) and zero_c_state["buildings"].size() >= ZeroCNetwork.LARGE_CITY:
        zero_c_stable_ticks += 1
        if zero_c_stable_ticks >= ZeroCNetwork.STABLE_TICKS and not zero_c_metropolis:
            zero_c_metropolis = true
            zero_c_earned_once = true
            zero_c_stage = 5
            _check_unlocks()
            if v22_feedback != null:
                v22_feedback.goal_complete()
            _v10_sync_scene(true)
    else:
        zero_c_stable_ticks = 0
    if (zero_c_was_stalled or stalled_before) and not _zero_c_stalled():
        zero_c_recovery_until = v04_time + 5.0
    zero_c_was_stalled = _zero_c_stalled()
    queue_redraw()

func _zero_c_stalled() -> bool:
    return not zero_c_state.is_empty() and zero_c_state["buildings"].size() >= ZeroCNetwork.LARGE_CITY and not bool(zero_c_state["ready"])

func _auto_generate_local_roads() -> void:
    if not zero_c_session:
        super._auto_generate_local_roads()
        return
    _zero_c_refresh()
    if tick_count % 8 != 0 or _count_cells(Cell.LOCAL) >= 12 or _zero_c_stalled():
        return
    for value: Variant in zero_c_state.get("accessible", {}):
        var road: Vector2i = value
        for d: Vector2i in ZeroCNetwork.DIRS:
            var p: Vector2i = road + d
            if _in_bounds(p) and int(grid[p.y][p.x]) == Cell.EMPTY and _adjacent_road_count(p) == 1 and _distance_to_arterial(p) <= 2 and not ZeroCNetwork.fragments_land(grid, p):
                grid[p.y][p.x] = Cell.LOCAL
                _v04_add_fx(p, "local", "")
                if v28_sequence_active:
                    _v28_note_local_road(p)
                return

func _auto_grow_buildings() -> void:
    if not zero_c_session:
        super._auto_grow_buildings()
        return
    _zero_c_refresh()
    if zero_c_state.is_empty() or zero_c_state["accessible"].is_empty():
        return
    var count: int = zero_c_state["buildings"].size()
    if count >= 72 or (count >= 14 and tick_count % 2 != 0):
        return
    # Grow functional centers on usable blocks first. An impossible district
    # must not prevent another district from growing or recovering.
    var candidates: Array[Vector2i] = []
    for value: Variant in zero_c_state["accessible"]:
        var road: Vector2i = value
        for d: Vector2i in ZeroCNetwork.DIRS:
            var p: Vector2i = road + d
            if _in_bounds(p) and int(grid[p.y][p.x]) == Cell.EMPTY and not candidates.has(p):
                candidates.append(p)
    if candidates.is_empty():
        return
    var deficit: int = -1
    for i: int in range(3):
        if (zero_c_state["ports"][i] as Vector2i).x < 0 or int(zero_c_state["spacious"][i]) >= 4:
            continue
        var room: Array[Vector2i] = []
        for p: Vector2i in candidates:
            var a: Vector2i = ZeroCNetwork.ANCHORS[i]
            if absi(p.x - a.x) + absi(p.y - a.y) <= 5 and ZeroCNetwork.has_room(grid, p):
                room.append(p)
        if not room.is_empty():
            deficit = i
            candidates = room
            break
    if _zero_c_stalled() and deficit < 0:
        return
    var kind: int = ZeroCNetwork.KINDS[deficit] if deficit >= 0 else -1
    var p: Vector2i = _v44_pick_arrival_candidate(candidates, kind)
    if kind < 0:
        kind = _v15_choose_building_for_cell(p)
    grid[p.y][p.x] = kind
    v42_response_count += 1
    _v27_schedule_growth(p, false)
    if kind == Cell.COMMERCIAL and v28_sequence_active:
        _v28_note_commercial(p)
    _v28_maybe_reveal()

func _v42_arrive_near_road(kind: int) -> void:
    if not zero_c_session:
        super._v42_arrive_near_road(kind)

func _v29_observe_traffic_state() -> void:
    if not zero_c_session:
        super._v29_observe_traffic_state()

func _v43_draw_pressure_readability() -> void:
    if not zero_c_session:
        super._v43_draw_pressure_readability()

func _zero_add_landmarks() -> void:
    if not zero_c_session:
        super._zero_add_landmarks()
        return
    # Only the destination objects; C's skylines come from actual city parcels.
    zero_landmark_count = 0
    zero_b_stage_piece_count = 0
    _zero_add_village()
    _zero_add_station()
    _zero_add_interchange()

func _process(delta: float) -> void:
    if zero_c_session and not paused:
        zero_c_reveal = move_toward(zero_c_reveal, 1.0 if zero_c_metropolis else 0.0, delta * 0.45)
    for value: Variant in zero_c_growth_marks.keys():
        if float(zero_c_growth_marks[value]) <= v04_time:
            zero_c_growth_marks.erase(value)
    super._process(delta)

func _v10_update_building_growth() -> void:
    super._v10_update_building_growth()
    if not zero_c_session or zero_c_state.is_empty():
        return
    for value: Variant in zero_c_state["buildings"]:
        var p: Vector2i = value
        var node: Node3D = v10_building_nodes.get(_key(p)) as Node3D
        if not is_instance_valid(node):
            continue
        var kind: int = int(zero_c_state["buildings"][p])
        var district: int = ZeroCNetwork.KINDS.find(kind)
        var anchor: Vector2i = ZeroCNetwork.ANCHORS[district]
        var near_center: bool = absi(p.x - anchor.x) + absi(p.y - anchor.y) <= 5
        if near_center and int(zero_c_state["spacious"][district]) >= 4 and ZeroCNetwork.has_room(grid, p):
            var gain: float = 1.0 if kind == Cell.COMMERCIAL else (0.55 if kind == Cell.RESIDENTIAL else 0.2)
            node.scale.y *= 1.0 + zero_c_reveal * gain

func _v10_update_vehicles() -> void:
    if not zero_c_session or zero_c_state.get("routes", []).is_empty():
        super._v10_update_vehicles()
        return
    if paused:
        return
    var routes: Array = zero_c_state["routes"]
    for i: int in range(v10_vehicle_nodes.size()):
        var car: Node3D = v10_vehicle_nodes[i] as Node3D
        var route: Array = routes[i % routes.size()]
        if route.size() < 2 or not is_instance_valid(car):
            continue
        # Keep progress continuous when route pressure changes; each actual edge
        # controls the speed. Re-route after topology edits without new nodes.
        var progress: float = float(car.get_meta("zero_c_progress", float(i) * 2.3))
        var last_time: float = float(car.get_meta("zero_c_time", v04_time))
        var segment: int = int(progress) % (route.size() - 1)
        var edge: String = ZeroCNetwork.edge_key(route[segment], route[segment + 1])
        var ratio: float = float(zero_c_state["loads"].get(edge, 0.0)) / ZeroCNetwork.EDGE_CAPACITY
        var speed: float = 0.20 if ratio > 1.0 else 1.6
        progress += clampf(v04_time - last_time, 0.0, 0.1) * speed
        car.set_meta("zero_c_progress", progress)
        car.set_meta("zero_c_time", v04_time)
        segment = int(progress) % (route.size() - 1)
        var a: Vector3 = _v10_world_position(route[segment], 0.18)
        var b: Vector3 = _v10_world_position(route[segment + 1], 0.18)
        var direction: Vector3 = (b - a).normalized()
        car.position = a.lerp(b, fmod(progress, 1.0)) + Vector3(-direction.z, 0.0, direction.x) * 0.14
        car.rotation.y = -atan2(direction.z, direction.x)

func _zero_c_hint() -> String:
    if zero_c_metropolis:
        return "メトロポリスへ。道が街の未来を変えた"
    if not zero_c_state.is_empty() and zero_c_state["cramped"].size() >= 4 and int(zero_c_state["centers"]) < 2:
        return "細い街区は育ちにくい。道を減らし土地を広く"
    if zero_c_effect_until > v04_time:
        return zero_c_effect
    if zero_c_recovery_until > v04_time:
        return "流れが分かれ、街が再び育ちはじめた"
    if _zero_c_stalled():
        if int(zero_c_state["connected"]) < 3:
            return "街の先へ。まだつながっていない拠点へ"
        if float(zero_c_state["peak"]) > 1.0:
            return "車列の先へ、別の幹線をつなごう"
        if int(zero_c_state["centers"]) < 2:
            return "駅や住宅地の周りにも、育つ場所を"
        return "拠点の間に、もうひとつの通り道を"
    if zero_c_stable_ticks > 0:
        return "街の流れが整い、新しい中心が育つ"
    return ""

func _v23_draw_city_first_shell() -> void:
    super._v23_draw_city_first_shell()
    if not zero_c_session:
        return
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(12.0, 10.0, size.x - 24.0, 51.0), Color("#F3F0E6"))
    draw_string(font, Vector2(16.0, 30.0), "AXIVA ZERO C2", HORIZONTAL_ALIGNMENT_LEFT, 190.0, 16, Color("#173E30"))
    draw_string(font, Vector2(size.x - 160.0, 30.0), ZERO_C_STAGES[zero_c_stage], HORIZONTAL_ALIGNMENT_RIGHT, 144.0, 14, Color("#173E30"))
    draw_string(font, Vector2(16.0, 54.0), (zero_c_stage_notice if zero_c_stage_until > v04_time else "一本の道から、メトロポリスへ。"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 32.0, 11, Color("#667D70"))
    var hint: String = _zero_c_hint()
    if not hint.is_empty() and not dragging:
        var panel: Rect2 = Rect2(board_rect.position.x + 8.0, board_rect.end.y - 40.0, board_rect.size.x - 16.0, 32.0)
        draw_rect(panel, Color(0.06, 0.16, 0.12, 0.9))
        draw_string(font, panel.position + Vector2(6.0, 21.0), hint, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 12.0, 12, Color.WHITE)

func _draw() -> void:
    super._draw()
    if not zero_c_session or zero_c_state.is_empty():
        return
    _zero_c_draw_effects()
    # Bounded world-space queue silhouettes; shape and motion, not color alone.
    var shown: int = 0
    for value: Variant in zero_c_state["hotspots"]:
        if shown >= 4:
            break
        var p: Vector2i = value
        var screen: Vector2 = _v27_project_cell(p, 0.25)
        if not board_rect.grow(-12.0).has_point(screen):
            continue
        shown += 1
        for i: int in range(3):
            var pos: Vector2 = screen + Vector2(float(i - 1) * 7.0, 0.0)
            draw_rect(Rect2(pos, Vector2(5.0, 3.0)), Color("#F3D7A4"))
            draw_rect(Rect2(pos, Vector2(5.0, 3.0)), Color("#805531"), false, 1.0)

func _zero_c_draw_effects() -> void:
    if zero_c_effect_until > v04_time:
        for p: Vector2i in zero_c_road_marks:
            var pos: Vector2 = _v27_project_cell(p, 0.2)
            if board_rect.grow(-12.0).has_point(pos):
                draw_circle(pos, 3.0, Color(0.94, 0.79, 0.35, 0.8))
    var shown: int = 0
    for p: Vector2i in zero_c_growth_marks:
        if shown >= 5 or not zero_c_state["buildings"].has(p):
            continue
        var pos: Vector2 = _v27_project_cell(p, 0.3)
        if board_rect.grow(-15.0).has_point(pos):
            var left: float = clampf(float(zero_c_growth_marks[p]) - v04_time, 0.0, 2.5)
            draw_circle(pos, 7.0 + (2.5 - left) * 3.0, Color(0.18, 0.52, 0.35, left / 2.5), false, 2.0)
            shown += 1
    if int(zero_c_state["centers"]) >= 2:
        return
    shown = 0
    for p: Vector2i in zero_c_state["cramped"]:
        if shown >= 4:
            break
        var pos: Vector2 = _v27_project_cell(p, 0.35)
        if board_rect.grow(-15.0).has_point(pos):
            # Brackets identify the affected parcels without a full-map overlay.
            draw_line(pos + Vector2(-9, -5), pos + Vector2(-9, 5), Color("#805531"), 2.0)
            draw_line(pos + Vector2(9, -5), pos + Vector2(9, 5), Color("#805531"), 2.0)
            shown += 1
