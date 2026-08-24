extends "res://main_v09.gd"

# MACHI LOOP v0.10 — first real 3D rendering vertical slice.
# Simulation/state/input semantics remain the v0.9 grid model; only board rendering/picking move into 3D.

var v10_viewport: SubViewport
var v10_world_root: Node3D
var v10_static_root: Node3D
var v10_preview_root: Node3D
var v10_vehicle_root: Node3D
var v10_camera: Camera3D
var v10_materials: Dictionary = {}
var v10_vehicle_nodes: Array = []
var v10_building_nodes: Dictionary = {}
var v10_scene_signature: int = -2147483648

func _ready() -> void:
    super._ready()
    _v10_setup_renderer()
    _v10_sync_scene(true)
    _v10_sync_preview()
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    if is_instance_valid(v10_viewport):
        _v10_update_vehicles()
        _v10_update_building_growth()
        queue_redraw()

func _reflow() -> void:
    super._reflow()
    if is_instance_valid(v10_viewport):
        _v10_update_viewport_size()

func _draw() -> void:
    var size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#E8EFE5"))
    _draw_header(size)
    _v10_draw_3d_board()
    _v10_draw_projected_effects()
    _v10_draw_preview_cost()
    _draw_toolbar(size)

    var has_roads: bool = not _all_road_cells().is_empty()
    if not has_roads:
        _draw_v06_first_action_coach()
    elif banner_timer > 0.0:
        _draw_banner(size)

    if has_roads and congestion >= 68.0 and not paused:
        _draw_v05_traffic_hint()

    if v04_level_flash > 0.0:
        var alpha: float = clampf(v04_level_flash / 0.8, 0.0, 1.0) * 0.22
        draw_rect(board_rect.grow(7.0), Color(0.96, 0.76, 0.26, alpha), false, 5.0)

    if v08_goal_flash > 0.0:
        _v08_draw_goal_complete()
    elif not (_all_road_cells().is_empty() and v08_goal_stage == 0):
        _v08_draw_goal_card()

    if population >= 26 or v09_policy != V09Policy.NONE:
        _v09_draw_policy_chip()
    if v09_policy_panel_open:
        _v09_draw_policy_panel()

func _screen_to_cell(pos: Vector2) -> Vector2i:
    if not board_rect.has_point(pos) or not is_instance_valid(v10_camera) or not is_instance_valid(v10_viewport):
        return Vector2i(-1, -1)

    var local: Vector2 = pos - board_rect.position
    var vp_size: Vector2 = Vector2(v10_viewport.size)
    if vp_size.x <= 1.0 or vp_size.y <= 1.0:
        return Vector2i(-1, -1)
    var vp_pos: Vector2 = Vector2(local.x / board_rect.size.x * vp_size.x, local.y / board_rect.size.y * vp_size.y)
    var ray_origin: Vector3 = v10_camera.project_ray_origin(vp_pos)
    var ray_dir: Vector3 = v10_camera.project_ray_normal(vp_pos)
    if absf(ray_dir.y) < 0.0001:
        return Vector2i(-1, -1)
    var t: float = -ray_origin.y / ray_dir.y
    if t < 0.0:
        return Vector2i(-1, -1)
    var hit: Vector3 = ray_origin + ray_dir * t
    var gx: int = int(floor(hit.x + float(GRID_W) * 0.5))
    var gy: int = int(floor(hit.z + float(GRID_H) * 0.5))
    return Vector2i(gx, gy)

func _pointer_down(pos: Vector2) -> void:
    super._pointer_down(pos)
    _v10_sync_preview()

func _pointer_move(pos: Vector2) -> void:
    super._pointer_move(pos)
    _v10_sync_preview()

func _pointer_up(pos: Vector2) -> void:
    super._pointer_up(pos)
    _v10_sync_preview()
    _v10_sync_scene()

func _commit_arterial() -> void:
    super._commit_arterial()
    _v10_sync_scene()

func _widen(p: Vector2i) -> void:
    super._widen(p)
    _v10_sync_scene()

func _bulldoze(p: Vector2i) -> void:
    super._bulldoze(p)
    _v10_sync_scene()

func _simulation_tick() -> void:
    super._simulation_tick()
    _v10_sync_scene()

func _v09_select_policy(policy: int) -> void:
    super._v09_select_policy(policy)
    _v10_sync_scene(true)

func _v10_setup_renderer() -> void:
    v10_viewport = SubViewport.new()
    v10_viewport.name = "City3DViewport"
    v10_viewport.own_world_3d = true
    v10_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    v10_viewport.transparent_bg = false
    add_child(v10_viewport)

    v10_world_root = Node3D.new()
    v10_world_root.name = "City3DWorld"
    v10_viewport.add_child(v10_world_root)

    var world_environment: WorldEnvironment = WorldEnvironment.new()
    var environment: Environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#DDE8D8")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#DDE9DF")
    environment.ambient_light_energy = 0.72
    world_environment.environment = environment
    v10_world_root.add_child(world_environment)

    var sun: DirectionalLight3D = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
    sun.light_color = Color("#FFF1D6")
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    v10_world_root.add_child(sun)

    var fill: DirectionalLight3D = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-68.0, 138.0, 0.0)
    fill.light_color = Color("#B8D6C9")
    fill.light_energy = 0.28
    fill.shadow_enabled = false
    v10_world_root.add_child(fill)

    v10_camera = Camera3D.new()
    v10_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    v10_camera.size = 29.0
    v10_camera.position = Vector3(16.0, 22.0, 18.0)
    v10_camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
    v10_camera.current = true
    v10_world_root.add_child(v10_camera)

    v10_static_root = Node3D.new()
    v10_static_root.name = "StaticCity"
    v10_world_root.add_child(v10_static_root)

    v10_preview_root = Node3D.new()
    v10_preview_root.name = "RoadPreview"
    v10_world_root.add_child(v10_preview_root)

    v10_vehicle_root = Node3D.new()
    v10_vehicle_root.name = "Vehicles"
    v10_world_root.add_child(v10_vehicle_root)

    _v10_create_materials()
    _v10_update_viewport_size()

func _v10_update_viewport_size() -> void:
    if not is_instance_valid(v10_viewport):
        return
    var w: int = clampi(int(board_rect.size.x * 1.7), 480, 760)
    var h: int = clampi(int(board_rect.size.y * 1.7), 680, 1180)
    v10_viewport.size = Vector2i(w, h)

func _v10_create_materials() -> void:
    v10_materials.clear()
    v10_materials["ground"] = _v10_material(Color("#BFD7B5"), 0.96)
    v10_materials["ground_alt"] = _v10_material(Color("#C9DEBF"), 0.96)
    v10_materials["locked"] = _v10_material(Color("#D9DED7"), 1.0)
    v10_materials["grid"] = _v10_material(Color("#9FB39D"), 1.0)
    v10_materials["arterial"] = _v10_material(Color("#323A38"), 0.90)
    v10_materials["local"] = _v10_material(Color("#68736F"), 0.92)
    v10_materials["lane"] = _v10_material(Color("#E8C768"), 0.80)
    v10_materials["widen"] = _v10_material(Color("#63C7A0"), 0.74)
    v10_materials["heat"] = _v10_material(Color("#D95A42"), 0.82)
    v10_materials["home_wall"] = _v10_material(Color("#F0F1E8"), 0.88)
    v10_materials["home_roof"] = _v10_material(Color("#65A66F"), 0.78)
    v10_materials["commercial"] = _v10_material(Color("#BFDCE6"), 0.48)
    v10_materials["commercial_roof"] = _v10_material(Color("#4F93B0"), 0.62)
    v10_materials["industrial"] = _v10_material(Color("#D8C09A"), 0.90)
    v10_materials["industrial_roof"] = _v10_material(Color("#A77B45"), 0.86)
    v10_materials["window"] = _v10_material(Color("#557D86"), 0.34)
    v10_materials["tree_trunk"] = _v10_material(Color("#7B6749"), 1.0)
    v10_materials["tree_leaf"] = _v10_material(Color("#5E9667"), 0.96)
    v10_materials["boundary"] = _v10_material(Color("#D6A34C"), 0.82)
    v10_materials["preview_ok"] = _v10_material(Color("#71E2AF"), 0.58)
    v10_materials["preview_bad"] = _v10_material(Color("#E86E59"), 0.64)
    v10_materials["car_light"] = _v10_material(Color("#F3F6EE"), 0.45)
    v10_materials["car_blue"] = _v10_material(Color("#6FAFC9"), 0.45)
    v10_materials["car_gold"] = _v10_material(Color("#DBB45E"), 0.45)

func _v10_material(color: Color, roughness: float) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = 0.0
    return material

func _v10_draw_3d_board() -> void:
    draw_rect(board_rect.grow(5.0), Color("#AAB9A6"))
    draw_rect(board_rect.grow(2.0), Color("#D8E2D4"))
    if is_instance_valid(v10_viewport):
        draw_texture_rect(v10_viewport.get_texture(), board_rect, false)
    else:
        draw_rect(board_rect, Color("#C7DCC0"))
    draw_rect(board_rect, Color(0.14, 0.22, 0.17, 0.32), false, 2.0)

func _v10_scene_hash() -> int:
    var signature: String = JSON.stringify(grid) + "|" + JSON.stringify(widened) + "|" + str(unlocked_cols) + "|" + str(v09_policy) + "|" + str(int(congestion / 10.0))
    return signature.hash()

func _v10_sync_scene(force: bool = false) -> void:
    if not is_instance_valid(v10_static_root):
        return
    var signature: int = _v10_scene_hash()
    if not force and signature == v10_scene_signature:
        return
    v10_scene_signature = signature
    _v10_rebuild_static_city()
    _v10_rebuild_vehicles()
    _v10_sync_preview()
    queue_redraw()

func _v10_rebuild_static_city() -> void:
    _v10_clear_children(v10_static_root)
    v10_building_nodes.clear()

    var open_width: float = float(unlocked_cols)
    if open_width > 0.0:
        var open_center_x: float = -float(GRID_W) * 0.5 + open_width * 0.5
        _v10_add_box(v10_static_root, Vector3(open_center_x, -0.09, 0.0), Vector3(open_width, 0.16, float(GRID_H)), v10_materials["ground"] as Material)
    var locked_width: float = float(GRID_W - unlocked_cols)
    if locked_width > 0.0:
        var locked_center_x: float = -float(GRID_W) * 0.5 + float(unlocked_cols) + locked_width * 0.5
        _v10_add_box(v10_static_root, Vector3(locked_center_x, -0.075, 0.0), Vector3(locked_width, 0.13, float(GRID_H)), v10_materials["locked"] as Material)

    # Large parcel seams: enough structure to read the grid without returning to spreadsheet visuals.
    for x: int in range(0, GRID_W + 1, 4):
        var wx: float = -float(GRID_W) * 0.5 + float(x)
        _v10_add_box(v10_static_root, Vector3(wx, 0.006, 0.0), Vector3(0.025, 0.012, float(GRID_H)), v10_materials["grid"] as Material, false)
    for y: int in range(0, GRID_H + 1, 4):
        var wz: float = -float(GRID_H) * 0.5 + float(y)
        _v10_add_box(v10_static_root, Vector3(0.0, 0.006, wz), Vector3(float(GRID_W), 0.012, 0.025), v10_materials["grid"] as Material, false)

    if unlocked_cols < GRID_W:
        var boundary_x: float = -float(GRID_W) * 0.5 + float(unlocked_cols)
        _v10_add_box(v10_static_root, Vector3(boundary_x, 0.055, 0.0), Vector3(0.09, 0.11, float(GRID_H)), v10_materials["boundary"] as Material, false)

    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            var cell: int = int(grid[y][x])
            if cell == Cell.ARTERIAL or cell == Cell.LOCAL:
                _v10_add_road(p, cell)
            elif cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
                _v10_add_building(p, cell)
            elif (x * 17 + y * 29 + x * y * 3) % 17 == 0:
                _v10_add_tree(p)

func _v10_add_road(p: Vector2i, cell: int) -> void:
    var world: Vector3 = _v10_world_position(p, 0.045)
    var width: float = 0.66 if cell == Cell.ARTERIAL else 0.46
    var material: Material = v10_materials["arterial"] as Material if cell == Cell.ARTERIAL else v10_materials["local"] as Material
    _v10_add_box(v10_static_root, world, Vector3(width, 0.075, width), material, false)

    var connections: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
    for d: Vector2i in connections:
        if not _v04_is_road(p + d):
            continue
        if d.x != 0:
            _v10_add_box(v10_static_root, world + Vector3(float(d.x) * 0.28, 0.0, 0.0), Vector3(0.58, 0.075, width), material, false)
        else:
            _v10_add_box(v10_static_root, world + Vector3(0.0, 0.0, float(d.y) * 0.28), Vector3(width, 0.075, 0.58), material, false)

    if cell == Cell.ARTERIAL:
        var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
        var vertical: bool = _v04_is_road(p + Vector2i(0, 1)) or _v04_is_road(p + Vector2i(0, -1))
        if horizontal or not vertical:
            _v10_add_box(v10_static_root, world + Vector3(0.0, 0.047, 0.0), Vector3(0.90, 0.012, 0.035), v10_materials["lane"] as Material, false)
        if vertical:
            _v10_add_box(v10_static_root, world + Vector3(0.0, 0.047, 0.0), Vector3(0.035, 0.012, 0.90), v10_materials["lane"] as Material, false)

        if widened.has(_key(p)):
            var edge: float = 0.43
            _v10_add_box(v10_static_root, world + Vector3(edge, 0.055, 0.0), Vector3(0.035, 0.035, 0.92), v10_materials["widen"] as Material, false)
            _v10_add_box(v10_static_root, world + Vector3(-edge, 0.055, 0.0), Vector3(0.035, 0.035, 0.92), v10_materials["widen"] as Material, false)
            _v10_add_box(v10_static_root, world + Vector3(0.0, 0.055, edge), Vector3(0.92, 0.035, 0.035), v10_materials["widen"] as Material, false)
            _v10_add_box(v10_static_root, world + Vector3(0.0, 0.055, -edge), Vector3(0.92, 0.035, 0.035), v10_materials["widen"] as Material, false)

    var heat: float = clampf(_road_load(p) / maxf(0.1, _road_capacity(p)), 0.0, 1.5)
    if heat > 0.95:
        _v10_add_box(v10_static_root, world + Vector3(0.0, 0.06, 0.46), Vector3(0.88, 0.024, 0.03), v10_materials["heat"] as Material, false)

func _v10_add_building(p: Vector2i, cell: int) -> void:
    var root: Node3D = Node3D.new()
    root.position = _v10_world_position(p, 0.0)
    root.name = "Building_%d_%d" % [p.x, p.y]
    v10_static_root.add_child(root)
    v10_building_nodes[_key(p)] = root

    var seed: int = abs((p.x * 31 + p.y * 47 + cell * 13) % 7)
    if cell == Cell.RESIDENTIAL:
        var h: float = 0.62 + float(seed % 4) * 0.16
        _v10_add_box(root, Vector3(0.0, h * 0.5 + 0.03, 0.0), Vector3(0.72, h, 0.72), v10_materials["home_wall"] as Material)
        _v10_add_box(root, Vector3(0.0, h + 0.10, 0.0), Vector3(0.78, 0.18, 0.78), v10_materials["home_roof"] as Material)
        _v10_add_box(root, Vector3(0.0, h * 0.58, 0.366), Vector3(0.34, 0.16, 0.018), v10_materials["window"] as Material, false)
    elif cell == Cell.COMMERCIAL:
        var h: float = 1.25 + float(seed % 5) * 0.22
        _v10_add_box(root, Vector3(0.0, h * 0.5 + 0.03, 0.0), Vector3(0.76, h, 0.76), v10_materials["commercial"] as Material)
        _v10_add_box(root, Vector3(0.0, h + 0.08, 0.0), Vector3(0.80, 0.14, 0.80), v10_materials["commercial_roof"] as Material)
        for band: int in range(3):
            var wy: float = 0.36 + float(band) * minf(0.40, h / 4.0)
            if wy < h - 0.12:
                _v10_add_box(root, Vector3(0.0, wy, 0.386), Vector3(0.56, 0.10, 0.016), v10_materials["window"] as Material, false)
    else:
        var h: float = 0.62 + float(seed % 3) * 0.13
        _v10_add_box(root, Vector3(0.0, h * 0.5 + 0.03, 0.0), Vector3(0.84, h, 0.82), v10_materials["industrial"] as Material)
        _v10_add_box(root, Vector3(0.0, h + 0.08, 0.0), Vector3(0.88, 0.15, 0.86), v10_materials["industrial_roof"] as Material)
        _v10_add_box(root, Vector3(0.22, h + 0.30, -0.18), Vector3(0.16, 0.48, 0.16), v10_materials["industrial_roof"] as Material)

func _v10_add_tree(p: Vector2i) -> void:
    var root: Node3D = Node3D.new()
    var jitter_x: float = (float((p.x * 7 + p.y * 3) % 5) - 2.0) * 0.055
    var jitter_z: float = (float((p.x * 5 + p.y * 11) % 5) - 2.0) * 0.055
    root.position = _v10_world_position(p, 0.0) + Vector3(jitter_x, 0.0, jitter_z)
    v10_static_root.add_child(root)
    _v10_add_box(root, Vector3(0.0, 0.19, 0.0), Vector3(0.10, 0.38, 0.10), v10_materials["tree_trunk"] as Material)
    var crown: SphereMesh = SphereMesh.new()
    crown.radius = 0.24
    crown.height = 0.44
    var leaves: MeshInstance3D = MeshInstance3D.new()
    leaves.mesh = crown
    leaves.material_override = v10_materials["tree_leaf"] as Material
    leaves.position = Vector3(0.0, 0.52, 0.0)
    root.add_child(leaves)

func _v10_rebuild_vehicles() -> void:
    _v10_clear_children(v10_vehicle_root)
    v10_vehicle_nodes.clear()
    var road_count: int = _all_road_cells().size()
    var count: int = mini(7, maxi(0, int(road_count / 3)))
    for i: int in range(count):
        var car: MeshInstance3D = _v10_add_box(v10_vehicle_root, Vector3.ZERO, Vector3(0.34, 0.14, 0.18), [v10_materials["car_light"], v10_materials["car_blue"], v10_materials["car_gold"]][i % 3] as Material, false)
        v10_vehicle_nodes.append(car)
    _v10_update_vehicles()

func _v10_update_vehicles() -> void:
    if v10_vehicle_nodes.is_empty():
        return
    var roads: Array = _all_road_cells()
    if roads.is_empty():
        return
    for i: int in range(v10_vehicle_nodes.size()):
        var car: MeshInstance3D = v10_vehicle_nodes[i] as MeshInstance3D
        var idx: int = (int(floor(v04_time * 0.75)) + i * 3) % roads.size()
        var p: Vector2i = roads[idx] as Vector2i
        var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
        var phase: float = fmod(v04_time * (0.48 + float(i % 3) * 0.05) + float(i) * 0.17, 1.0) - 0.5
        var world: Vector3 = _v10_world_position(p, 0.18)
        if horizontal:
            world.x += phase * 0.72
            world.z += 0.16 if i % 2 == 0 else -0.16
            car.rotation.y = 0.0
        else:
            world.z += phase * 0.72
            world.x += 0.16 if i % 2 == 0 else -0.16
            car.rotation.y = PI * 0.5
        car.position = world

func _v10_update_building_growth() -> void:
    if v10_building_nodes.is_empty():
        return
    for key: Variant in v10_building_nodes.keys():
        var text: String = str(key)
        var parts: PackedStringArray = text.split(":")
        if parts.size() != 2:
            continue
        var p: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
        var node: Node3D = v10_building_nodes[key] as Node3D
        var growth: float = _v04_growth_scale(p)
        node.scale = Vector3(1.0, growth, 1.0)

func _v10_sync_preview() -> void:
    if not is_instance_valid(v10_preview_root):
        return
    _v10_clear_children(v10_preview_root)
    if not dragging or current_tool != Tool.ROAD:
        return
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if not _in_bounds(p) or p.x >= unlocked_cols:
            continue
        var valid: bool = int(grid[p.y][p.x]) in [Cell.EMPTY, Cell.ARTERIAL]
        var material: Material = v10_materials["preview_ok"] as Material if valid else v10_materials["preview_bad"] as Material
        _v10_add_box(v10_preview_root, _v10_world_position(p, 0.13), Vector3(0.84, 0.05, 0.84), material, false)

func _v10_draw_preview_cost() -> void:
    if not dragging or current_tool != Tool.ROAD:
        return
    var new_count: int = 0
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if _in_bounds(p) and int(grid[p.y][p.x]) == Cell.EMPTY:
            new_count += 1
    if new_count <= 0:
        return
    var font: Font = ThemeDB.fallback_font
    var pill: Rect2 = Rect2(board_rect.get_center().x - 68.0, board_rect.end.y - 39.0, 136.0, 29.0)
    draw_rect(pill, Color(0.05, 0.13, 0.09, 0.94))
    draw_rect(pill, Color("#71D0A2"), false, 1.0)
    draw_string(font, pill.position + Vector2(0.0, 20.0), "%d CELLS  -Y%d" % [new_count, new_count * ROAD_COST], HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 11, Color("#F3FFF7"))

func _v10_draw_projected_effects() -> void:
    if not is_instance_valid(v10_camera) or not is_instance_valid(v10_viewport):
        return
    var font: Font = ThemeDB.fallback_font
    var vp_size: Vector2 = Vector2(v10_viewport.size)
    for item: Variant in v04_cell_fx:
        var fx: Dictionary = item as Dictionary
        var p: Vector2i = fx["p"] as Vector2i
        var life: float = float(fx["life"])
        var max_life: float = maxf(0.001, float(fx["max_life"]))
        var ratio: float = clampf(life / max_life, 0.0, 1.0)
        var world: Vector3 = _v10_world_position(p, 0.75)
        var projected: Vector2 = v10_camera.unproject_position(world)
        if projected.x < 0.0 or projected.y < 0.0 or projected.x > vp_size.x or projected.y > vp_size.y:
            continue
        var screen: Vector2 = board_rect.position + Vector2(projected.x / vp_size.x * board_rect.size.x, projected.y / vp_size.y * board_rect.size.y)
        var ring_color: Color = Color(0.43, 0.91, 0.67, ratio * 0.76)
        if str(fx["kind"]) == "road":
            ring_color = Color(0.40, 0.88, 0.84, ratio * 0.74)
        draw_circle(screen, 8.0 + (1.0 - ratio) * 7.0, ring_color, false, 2.0)
        var label: String = str(fx["label"])
        if not label.is_empty():
            draw_string(font, screen + Vector2(-46.0, -11.0 - (1.0 - ratio) * 13.0), label, HORIZONTAL_ALIGNMENT_CENTER, 92.0, 10, Color(0.08, 0.22, 0.15, minf(1.0, ratio * 1.8)))

func _v10_world_position(p: Vector2i, y: float = 0.0) -> Vector3:
    return Vector3(float(p.x) - float(GRID_W) * 0.5 + 0.5, y, float(p.y) - float(GRID_H) * 0.5 + 0.5)

func _v10_add_box(parent: Node, position: Vector3, size: Vector3, material: Material, cast_shadow: bool = true) -> MeshInstance3D:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    var instance: MeshInstance3D = MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material
    instance.position = position
    if not cast_shadow:
        instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(instance)
    return instance

func _v10_clear_children(parent: Node) -> void:
    for child: Node in parent.get_children():
        child.free()
