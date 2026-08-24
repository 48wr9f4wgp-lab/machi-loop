extends "res://main_v13_visual.gd"

# MACHI LOOP v0.14 — 3D polish pass.
# Renderer-only: stronger land read, tighter framing, street furniture, lot dressing and facade/roof detail.

func _v10_setup_renderer() -> void:
    super._v10_setup_renderer()
    if is_instance_valid(v10_viewport) and v10_viewport.world_3d != null and v10_viewport.world_3d.environment != null:
        var env: Environment = v10_viewport.world_3d.environment
        env.background_color = Color("#AFC3B1")
        env.ambient_light_color = Color("#B9CFBE")
        env.ambient_light_energy = 0.46
    if is_instance_valid(v10_world_root):
        var light_index: int = 0
        for child: Node in v10_world_root.get_children():
            if child is DirectionalLight3D:
                var light: DirectionalLight3D = child as DirectionalLight3D
                if light_index == 0:
                    light.light_energy = 1.05
                    light.shadow_enabled = true
                else:
                    light.light_energy = 0.16
                light_index += 1
    _v14_update_camera_framing()

func _v10_create_materials() -> void:
    super._v10_create_materials()
    # Deliberately darker than v0.13: iPhone Web was washing the land toward white.
    v10_materials["ground"] = _v10_material(Color("#6F9666"), 0.99)
    v10_materials["ground_alt"] = _v10_material(Color("#7EA374"), 0.99)
    v10_materials["parcel_a"] = _v10_material(Color("#789D70"), 0.99)
    v10_materials["parcel_b"] = _v10_material(Color("#86AA7A"), 0.99)
    v10_materials["locked"] = _v10_material(Color("#B7C0B8"), 1.0)
    v10_materials["asphalt_dark"] = _v10_material(Color("#252C2A"), 0.95)
    v10_materials["crosswalk"] = _v10_material(Color("#E9E8D9"), 0.82)
    v10_materials["parking"] = _v10_material(Color("#737D78"), 0.96)
    v10_materials["hedge"] = _v10_material(Color("#3F7B4C"), 0.99)
    v10_materials["lamp"] = _v10_material(Color("#394640"), 0.88)
    v10_materials["lamp_glow"] = _v10_material(Color("#FFE59A"), 0.52)
    v10_materials["sign_blue"] = _v10_material(Color("#397FA2"), 0.60)
    v10_materials["sign_red"] = _v10_material(Color("#C85B4B"), 0.68)
    v10_materials["sign_gold"] = _v10_material(Color("#D4A745"), 0.72)
    v10_materials["container_blue"] = _v10_material(Color("#4E8292"), 0.84)
    v10_materials["container_red"] = _v10_material(Color("#A9604D"), 0.86)
    v10_materials["hvac"] = _v10_material(Color("#7C8983"), 0.90)
    v10_materials["car_red"] = _v10_material(Color("#B95A4B"), 0.55)
    v10_materials["car_green"] = _v10_material(Color("#5D9274"), 0.55)

func _v10_sync_scene(force: bool = false) -> void:
    super._v10_sync_scene(force)
    _v14_update_camera_framing()

func _v10_rebuild_static_city() -> void:
    super._v10_rebuild_static_city()
    if not is_instance_valid(v10_static_root):
        return

    # Strong, explicit parcel carpet above the base mesh. This guarantees a green land read on Web/iPhone.
    for y: int in range(0, GRID_H, 4):
        for x: int in range(0, unlocked_cols, 4):
            var sx: float = minf(3.86, float(unlocked_cols - x) - 0.06)
            var sz: float = minf(3.86, float(GRID_H - y) - 0.06)
            if sx <= 0.1 or sz <= 0.1:
                continue
            var center: Vector3 = Vector3(
                float(x) - float(GRID_W) * 0.5 + sx * 0.5 + 0.03,
                0.011,
                float(y) - float(GRID_H) * 0.5 + sz * 0.5 + 0.03
            )
            var material: Material = v10_materials["parcel_a"] as Material if ((x / 4) + (y / 4)) % 2 == 0 else v10_materials["parcel_b"] as Material
            _v10_add_box(v10_static_root, center, Vector3(sx, 0.016, sz), material, false)

    if unlocked_cols < GRID_W:
        var locked_width: float = float(GRID_W - unlocked_cols)
        var locked_center_x: float = -float(GRID_W) * 0.5 + float(unlocked_cols) + locked_width * 0.5
        _v10_add_box(v10_static_root, Vector3(locked_center_x, 0.010, 0.0), Vector3(locked_width - 0.04, 0.014, float(GRID_H) - 0.04), v10_materials["locked"] as Material, false)

    _v14_add_street_furniture()

func _v10_add_road(p: Vector2i, cell: int) -> void:
    super._v10_add_road(p, cell)
    var world: Vector3 = _v10_world_position(p, 0.102)
    var neighbors: int = 0
    for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        if _v04_is_road(p + d):
            neighbors += 1

    # Intersections gain small crosswalk bars: high-value readability at mobile scale.
    if neighbors >= 3:
        for i: int in range(-1, 2):
            var offset: float = float(i) * 0.13
            _v10_add_box(v10_static_root, world + Vector3(offset, 0.0, 0.27), Vector3(0.075, 0.014, 0.22), v10_materials["crosswalk"] as Material, false)
            _v10_add_box(v10_static_root, world + Vector3(0.27, 0.0, offset), Vector3(0.22, 0.014, 0.075), v10_materials["crosswalk"] as Material, false)

func _v10_add_building(p: Vector2i, cell: int) -> void:
    super._v10_add_building(p, cell)
    var key: String = _key(p)
    if not v10_building_nodes.has(key):
        return
    var root: Node3D = v10_building_nodes[key] as Node3D
    var seed: int = abs(p.x * 61 + p.y * 43 + cell * 17)
    var road_dir: Vector2i = _v14_adjacent_road_dir(p)

    if cell == Cell.RESIDENTIAL:
        _v14_dress_residential(root, seed, road_dir)
    elif cell == Cell.COMMERCIAL:
        _v14_dress_commercial(root, seed, road_dir)
    else:
        _v14_dress_industrial(root, seed, road_dir)

func _v14_update_camera_framing() -> void:
    if not is_instance_valid(v10_camera):
        return

    var min_x: int = GRID_W
    var max_x: int = -1
    var min_y: int = GRID_H
    var max_y: int = -1
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) == Cell.EMPTY:
                continue
            min_x = mini(min_x, x)
            max_x = maxi(max_x, x)
            min_y = mini(min_y, y)
            max_y = maxi(max_y, y)

    var focus: Vector3
    if max_x < 0:
        focus = Vector3(-float(GRID_W) * 0.5 + float(unlocked_cols) * 0.5, 0.35, 0.0)
    else:
        var cx: float = (float(min_x + max_x) + 1.0) * 0.5 - float(GRID_W) * 0.5
        var cz: float = (float(min_y + max_y) + 1.0) * 0.5 - float(GRID_H) * 0.5
        # Bias a little toward free build space so the next road is still visible.
        var open_center_x: float = -float(GRID_W) * 0.5 + float(unlocked_cols) * 0.5
        cx = lerpf(cx, open_center_x, 0.22)
        focus = Vector3(cx, 0.42, cz)

    var target_size: float = 20.2
    if unlocked_cols >= 16:
        target_size = 22.4
    elif unlocked_cols >= 12:
        target_size = 21.2
    elif unlocked_cols >= 8:
        target_size = 20.4

    v10_camera.size = target_size
    v10_camera.position = focus + Vector3(11.5, 16.8, 13.2)
    v10_camera.look_at(focus, Vector3.UP)

func _v14_add_street_furniture() -> void:
    var lamp_count: int = 0
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            if not _v04_is_road(p):
                continue
            var marker: int = abs(x * 19 + y * 31 + x * y * 5)
            if marker % 8 != 0 or lamp_count >= 28:
                continue
            var world: Vector3 = _v10_world_position(p, 0.0)
            var side: float = 0.47 if marker % 2 == 0 else -0.47
            var pole_pos: Vector3 = world + Vector3(side, 0.29, 0.34)
            _v14_add_cylinder(v10_static_root, pole_pos, 0.024, 0.54, v10_materials["lamp"] as Material)
            _v10_add_box(v10_static_root, pole_pos + Vector3(0.0, 0.28, 0.0), Vector3(0.10, 0.06, 0.10), v10_materials["lamp_glow"] as Material, false)
            lamp_count += 1

func _v14_dress_residential(root: Node3D, seed: int, road_dir: Vector2i) -> void:
    var hedge_side: float = -0.36 if seed % 2 == 0 else 0.36
    _v10_add_box(root, Vector3(hedge_side, 0.10, 0.28), Vector3(0.10, 0.18, 0.44), v10_materials["hedge"] as Material, false)
    if road_dir != Vector2i.ZERO and seed % 3 != 0:
        var driveway: Vector3 = _v14_lot_edge_position(road_dir, 0.37, 0.045)
        var drive_size: Vector3 = Vector3(0.25, 0.028, 0.42) if road_dir.x == 0 else Vector3(0.42, 0.028, 0.25)
        _v10_add_box(root, driveway, drive_size, v10_materials["parking"] as Material, false)
        _v14_add_parked_car(root, driveway + Vector3(0.0, 0.09, 0.0), road_dir, seed)

func _v14_dress_commercial(root: Node3D, seed: int, road_dir: Vector2i) -> void:
    var sign_materials: Array = [v10_materials["sign_blue"], v10_materials["sign_red"], v10_materials["sign_gold"]]
    var sign_mat: Material = sign_materials[seed % sign_materials.size()] as Material
    _v10_add_box(root, Vector3(0.0, 0.34, 0.385), Vector3(0.38, 0.13, 0.035), sign_mat, false)
    _v10_add_box(root, Vector3(0.18, 1.08 + float(seed % 3) * 0.15, -0.12), Vector3(0.22, 0.16, 0.24), v10_materials["hvac"] as Material)
    if road_dir != Vector2i.ZERO:
        var parking_pos: Vector3 = _v14_lot_edge_position(road_dir, 0.36, 0.038)
        var parking_size: Vector3 = Vector3(0.34, 0.024, 0.46) if road_dir.x == 0 else Vector3(0.46, 0.024, 0.34)
        _v10_add_box(root, parking_pos, parking_size, v10_materials["parking"] as Material, false)
        if seed % 2 == 0:
            _v14_add_parked_car(root, parking_pos + Vector3(0.0, 0.09, 0.0), road_dir, seed + 4)

func _v14_dress_industrial(root: Node3D, seed: int, road_dir: Vector2i) -> void:
    var container_mat: Material = v10_materials["container_blue"] as Material if seed % 2 == 0 else v10_materials["container_red"] as Material
    _v10_add_box(root, Vector3(-0.25, 0.14, 0.28), Vector3(0.32, 0.20, 0.22), container_mat)
    _v10_add_box(root, Vector3(0.18, 0.14, 0.30), Vector3(0.28, 0.20, 0.20), v10_materials["roof_detail"] as Material)
    if seed % 3 == 0:
        _v14_add_cylinder(root, Vector3(0.28, 0.32, -0.22), 0.11, 0.50, v10_materials["hvac"] as Material)

func _v14_adjacent_road_dir(p: Vector2i) -> Vector2i:
    for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
        if _v04_is_road(p + d):
            return d
    return Vector2i.ZERO

func _v14_lot_edge_position(dir: Vector2i, edge: float, y: float) -> Vector3:
    return Vector3(float(dir.x) * edge, y, float(dir.y) * edge)

func _v14_add_parked_car(parent: Node, pos: Vector3, road_dir: Vector2i, seed: int) -> void:
    var mat: Material
    match seed % 4:
        0:
            mat = v10_materials["car_blue"] as Material
        1:
            mat = v10_materials["car_gold"] as Material
        2:
            mat = v10_materials["car_red"] as Material
        _:
            mat = v10_materials["car_green"] as Material
    var size: Vector3 = Vector3(0.18, 0.12, 0.34) if road_dir.x == 0 else Vector3(0.34, 0.12, 0.18)
    _v10_add_box(parent, pos, size, mat, false)

func _v14_add_cylinder(parent: Node, pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 8
    var instance: MeshInstance3D = MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material
    instance.position = pos
    parent.add_child(instance)
    return instance

func _draw_banner(size: Vector2) -> void:
    # Compact toast: the old banner obscured too much of the city on portrait screens.
    var w: float = minf(size.x - 96.0, 274.0)
    var rect: Rect2 = Rect2((size.x - w) * 0.5, board_origin.y + 9.0, w, 34.0)
    draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.02, 0.06, 0.04, 0.15))
    draw_rect(rect, Color(0.055, 0.14, 0.105, 0.94))
    draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), Color("#71D0A2"))
    draw_string(v11_font, rect.position + Vector2(8.0, 23.0), _v11_banner_text(banner), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 11, Color.WHITE)
