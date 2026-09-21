extends "res://main_zero_core_fun.gd"

# AXIVA ZERO B experiment.
# A remains available at ?zero=1.
# B activates with ?zero=b and tests stronger destination identity plus
# a visible runway from settlement toward a future metropolis.

var zero_b_session: bool = false
var zero_b_last_signature: String = "none"
var zero_b_new_connections: Array[String] = []
var zero_b_stage_piece_count: int = 0

func _ready() -> void:
    zero_b_session = _zero_b_detect_session()
    super._ready()
    if zero_b_session:
        _v10_sync_scene(true)
        queue_redraw()

func _zero_detect_session() -> bool:
    if not OS.has_feature("web"):
        return false
    var query_value: Variant = JavaScriptBridge.eval("window.location.search", true)
    var query: String = str(query_value)
    return _zero_query_requests(query) or _zero_b_query_requests(query)

func _zero_b_detect_session() -> bool:
    if not OS.has_feature("web"):
        return false
    var query_value: Variant = JavaScriptBridge.eval("window.location.search", true)
    return _zero_b_query_requests(str(query_value))

func _zero_b_query_requests(query: String) -> bool:
    var normalized: String = query.strip_edges()
    if normalized.begins_with("?"):
        normalized = normalized.substr(1)
    if normalized.is_empty():
        return false
    for raw_part: String in normalized.split("&"):
        if raw_part.strip_edges() == "zero=b":
            return true
    return false

func _v42_build_label() -> String:
    if zero_b_session:
        return "ZERO B"
    return super._v42_build_label()

# ---------------------------------------------------------------------------
# Destination signatures.
# The player should see three clearly different cities emerge from the same verb.
# ---------------------------------------------------------------------------

func _zero_b_signature_for_kind(kind: int) -> String:
    match kind:
        Cell.RESIDENTIAL:
            return "village"
        Cell.COMMERCIAL:
            return "station"
        Cell.INDUSTRIAL:
            return "interchange"
        _:
            return "village"

func _zero_b_signature_for_path(path: Array) -> String:
    return _zero_b_signature_for_kind(_v44_path_pull_kind(path))

func _zero_b_wave(signature: String, connected: bool) -> Array[int]:
    var wave: Array[int] = []
    match signature:
        "station":
            wave.assign([
                Cell.COMMERCIAL, Cell.LOCAL, Cell.COMMERCIAL, Cell.COMMERCIAL,
                Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.LOCAL, Cell.COMMERCIAL,
                Cell.COMMERCIAL, Cell.RESIDENTIAL
            ])
        "interchange":
            wave.assign([
                Cell.INDUSTRIAL, Cell.LOCAL, Cell.INDUSTRIAL, Cell.INDUSTRIAL,
                Cell.COMMERCIAL, Cell.INDUSTRIAL, Cell.LOCAL, Cell.INDUSTRIAL,
                Cell.INDUSTRIAL, Cell.RESIDENTIAL
            ])
        _:
            wave.assign([
                Cell.RESIDENTIAL, Cell.LOCAL, Cell.RESIDENTIAL, Cell.RESIDENTIAL,
                Cell.LOCAL, Cell.RESIDENTIAL, Cell.RESIDENTIAL, Cell.COMMERCIAL,
                Cell.LOCAL, Cell.RESIDENTIAL
            ])

    if connected:
        match signature:
            "station":
                wave.append_array([Cell.COMMERCIAL, Cell.COMMERCIAL, Cell.RESIDENTIAL, Cell.COMMERCIAL])
            "interchange":
                wave.append_array([Cell.INDUSTRIAL, Cell.INDUSTRIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL])
            _:
                wave.append_array([Cell.RESIDENTIAL, Cell.LOCAL, Cell.RESIDENTIAL, Cell.RESIDENTIAL])
    return wave

func _zero_note_new_connections(before: Dictionary) -> int:
    if zero_b_session:
        zero_b_new_connections.clear()
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
                zero_b_new_connections.append(key)
    return super._zero_note_new_connections(before)

func _commit_arterial() -> void:
    if not zero_b_session:
        super._commit_arterial()
        return

    var route_signature: String = _zero_b_signature_for_path(drag_path)
    var before_commits: int = zero_route_commits
    zero_b_new_connections.clear()

    super._commit_arterial()
    if zero_route_commits == before_commits:
        return

    var signature: String = route_signature
    if not zero_b_new_connections.is_empty():
        signature = zero_b_new_connections[0]

    zero_b_last_signature = signature
    v42_arrivals = _zero_b_wave(signature, not zero_b_new_connections.is_empty())
    v42_arrival_tick = tick_count - 1
    _v10_sync_scene(true)
    queue_redraw()

# ---------------------------------------------------------------------------
# Physical world payoff.
# A connected destination visibly changes shape, not just its numbers.
# ---------------------------------------------------------------------------

func _v10_create_materials() -> void:
    super._v10_create_materials()
    v10_materials["zero_b_village"] = _v10_material(Color("#EEDFCC"), 0.90)
    v10_materials["zero_b_village_roof"] = _v10_material(Color("#A95543"), 0.84)
    v10_materials["zero_b_tower"] = _v10_material(Color("#DDE8E7"), 0.88)
    v10_materials["zero_b_tower_glass"] = _v10_material(Color("#557A7E"), 0.80)
    v10_materials["zero_b_warehouse"] = _v10_material(Color("#D6CDBD"), 0.90)
    v10_materials["zero_b_warehouse_roof"] = _v10_material(Color("#7B6E5A"), 0.84)
    v10_materials["zero_b_core"] = _v10_material(Color("#E8E5DB"), 0.88)
    v10_materials["zero_b_core_top"] = _v10_material(Color("#315F59"), 0.82)

func _zero_add_landmarks() -> void:
    super._zero_add_landmarks()
    if not zero_b_session:
        return

    zero_b_stage_piece_count = 0
    if _zero_landmark_connected(ZERO_VILLAGE):
        _zero_b_add_village_growth()
    if _zero_landmark_connected(ZERO_STATION):
        _zero_b_add_station_growth()
    if _zero_landmark_connected(ZERO_INTERCHANGE):
        _zero_b_add_interchange_growth()

    var connected: int = _zero_b_connected_count()
    if connected >= 2:
        _zero_b_add_city_core(connected)

func _zero_b_add_village_growth() -> void:
    var root: Node3D = Node3D.new()
    root.name = "ZeroBVillageGrowth"
    root.position = _v10_world_position(ZERO_VILLAGE, 0.0)
    v10_static_root.add_child(root)

    var offsets: Array[Vector3] = [
        Vector3(-0.70, 0.0, 0.42),
        Vector3(-0.32, 0.0, 0.72),
        Vector3(0.30, 0.0, 0.66),
        Vector3(0.72, 0.0, 0.30),
        Vector3(-0.70, 0.0, -0.42),
        Vector3(0.64, 0.0, -0.44)
    ]
    for off: Vector3 in offsets:
        _v10_add_box(root, off + Vector3(0.0, 0.18, 0.0),
            Vector3(0.28, 0.32, 0.26), v10_materials["zero_b_village"] as Material)
        _v10_add_box(root, off + Vector3(0.0, 0.37, 0.0),
            Vector3(0.32, 0.08, 0.30), v10_materials["zero_b_village_roof"] as Material)
        zero_b_stage_piece_count += 2

func _zero_b_add_station_growth() -> void:
    var root: Node3D = Node3D.new()
    root.name = "ZeroBStationGrowth"
    root.position = _v10_world_position(ZERO_STATION, 0.0)
    v10_static_root.add_child(root)

    var towers: Array = [
        [Vector3(-0.72, 0.0, -0.48), Vector3(0.42, 1.20, 0.42)],
        [Vector3(-0.26, 0.0, 0.58), Vector3(0.38, 1.52, 0.38)],
        [Vector3(0.62, 0.0, 0.56), Vector3(0.46, 1.02, 0.46)],
        [Vector3(0.82, 0.0, -0.34), Vector3(0.34, 0.82, 0.34)]
    ]
    for value: Variant in towers:
        var tower: Array = value as Array
        var off: Vector3 = tower[0] as Vector3
        var size: Vector3 = tower[1] as Vector3
        _v10_add_box(root, off + Vector3(0.0, size.y * 0.5, 0.0),
            size, v10_materials["zero_b_tower"] as Material)
        _v10_add_box(root, off + Vector3(0.0, size.y + 0.05, 0.0),
            Vector3(size.x * 0.84, 0.08, size.z * 0.84),
            v10_materials["zero_b_tower_glass"] as Material)
        zero_b_stage_piece_count += 2

func _zero_b_add_interchange_growth() -> void:
    var root: Node3D = Node3D.new()
    root.name = "ZeroBInterchangeGrowth"
    root.position = _v10_world_position(ZERO_INTERCHANGE, 0.0)
    v10_static_root.add_child(root)

    var sheds: Array = [
        [Vector3(-0.72, 0.0, -0.52), Vector3(0.78, 0.34, 0.48)],
        [Vector3(0.18, 0.0, -0.68), Vector3(0.92, 0.42, 0.54)],
        [Vector3(0.70, 0.0, 0.22), Vector3(0.70, 0.30, 0.46)],
        [Vector3(-0.38, 0.0, 0.62), Vector3(0.64, 0.28, 0.42)]
    ]
    for value: Variant in sheds:
        var shed: Array = value as Array
        var off: Vector3 = shed[0] as Vector3
        var size: Vector3 = shed[1] as Vector3
        _v10_add_box(root, off + Vector3(0.0, size.y * 0.5, 0.0),
            size, v10_materials["zero_b_warehouse"] as Material)
        _v10_add_box(root, off + Vector3(0.0, size.y + 0.04, 0.0),
            Vector3(size.x * 1.02, 0.07, size.z * 1.02),
            v10_materials["zero_b_warehouse_roof"] as Material)
        zero_b_stage_piece_count += 2

func _zero_b_connected_count() -> int:
    return (
        int(_zero_landmark_connected(ZERO_VILLAGE))
        + int(_zero_landmark_connected(ZERO_STATION))
        + int(_zero_landmark_connected(ZERO_INTERCHANGE))
    )

func _zero_b_add_city_core(stage: int) -> void:
    var root: Node3D = Node3D.new()
    root.name = "ZeroBCityCore"
    root.position = _v10_world_position(Vector2i(8, 11), 0.0)
    v10_static_root.add_child(root)

    var tower_count: int = 3 if stage == 2 else 6
    var offsets: Array[Vector3] = [
        Vector3(-0.48, 0.0, -0.38),
        Vector3(0.10, 0.0, -0.48),
        Vector3(0.52, 0.0, 0.04),
        Vector3(-0.34, 0.0, 0.42),
        Vector3(0.18, 0.0, 0.50),
        Vector3(0.58, 0.0, 0.52)
    ]
    var heights: Array[float] = [0.90, 1.24, 1.02, 1.38, 1.12, 1.56]
    for i: int in range(tower_count):
        var off: Vector3 = offsets[i]
        var h: float = heights[i]
        _v10_add_box(root, off + Vector3(0.0, h * 0.5, 0.0),
            Vector3(0.32, h, 0.32), v10_materials["zero_b_core"] as Material)
        _v10_add_box(root, off + Vector3(0.0, h + 0.04, 0.0),
            Vector3(0.24, 0.07, 0.24), v10_materials["zero_b_core_top"] as Material)
        zero_b_stage_piece_count += 2

# ---------------------------------------------------------------------------
# Purely visual lure. No text tells the player what to do.
# ---------------------------------------------------------------------------

func _draw() -> void:
    super._draw()
    if zero_b_session:
        _zero_b_draw_destinations()

func _zero_b_color(key: String, alpha: float) -> Color:
    match key:
        "station":
            return Color(0.26, 0.62, 0.68, alpha)
        "interchange":
            return Color(0.82, 0.58, 0.25, alpha)
        _:
            return Color(0.36, 0.68, 0.39, alpha)

func _zero_b_draw_destinations() -> void:
    var entries: Array = [
        ["village", ZERO_VILLAGE],
        ["station", ZERO_STATION],
        ["interchange", ZERO_INTERCHANGE]
    ]
    var pulse: float = 0.5 + 0.5 * sin(v04_time * 2.4)
    for value: Variant in entries:
        var entry: Array = value as Array
        var key: String = str(entry[0])
        var anchor: Vector2i = entry[1] as Vector2i
        if _zero_landmark_connected(anchor):
            continue
        var screen: Vector2 = _v27_project_cell(anchor, 0.24)
        if not board_rect.has_point(screen):
            continue
        draw_circle(screen, 20.0 + pulse * 5.0, _zero_b_color(key, 0.28), false, 2.0)
