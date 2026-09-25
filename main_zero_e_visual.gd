extends "res://main_zero_e_road_choice.gd"

# ZERO E visual slice. All scenery derives from the actual grid, so a new road
# replaces planting instead of drawing over a fake city. The normal game and
# earlier experiments retain their existing presentation.

func _v10_create_materials() -> void:
    super._v10_create_materials()
    if not zero_e_session:
        return
    var ground: StandardMaterial3D = _v10_material(Color.WHITE, 1.0)
    ground.albedo_texture = _zero_e_grass_texture()
    v10_materials["v22_ground"] = ground
    v10_materials["v22_arterial"] = _v10_material(Color("#3B4140"), 0.97)
    v10_materials["v22_local"] = _v10_material(Color("#666D68"), 0.97)
    v10_materials["v22_curb"] = _v10_material(Color("#D8D1BD"), 0.98)
    v10_materials["v22_lane"] = _v10_material(Color("#EDCF7D"), 0.95)
    v10_materials["v22_stop"] = _v10_material(Color("#F3EEE0"), 0.94)
    v10_materials["v21_stucco_white"] = _v10_material(Color("#F7ECD8"), 0.94)
    v10_materials["v21_stucco_warm"] = _v10_material(Color("#E8D3B7"), 0.95)
    v10_materials["v21_stucco_sage"] = _v10_material(Color("#DAE3CF"), 0.95)
    v10_materials["v21_roof_terracotta"] = _v10_material(Color("#AD6850"), 0.91)
    v10_materials["v21_roof_green"] = _v10_material(Color("#596E58"), 0.93)
    v10_materials["v21_roof_gold"] = _v10_material(Color("#A77C53"), 0.93)
    v10_materials["v21_commercial_frame"] = _v10_material(Color("#E5DCC9"), 0.88)
    v10_materials["v21_glass_dark"] = _v10_material(Color("#506D70"), 0.52)
    v10_materials["v21_window_blue"] = _v10_material(Color("#96B6B6"), 0.47)
    v10_materials["ze_pavement"] = _v10_material(Color("#CABEA7"), 0.98)
    v10_materials["ze_park"] = _v10_material(Color("#6F9B69"), 1.0)
    v10_materials["ze_bloom"] = _v10_material(Color("#DCC9AB"), 1.0)
    v10_materials["ze_pine"] = _v10_material(Color("#456B4B"), 1.0)
    v10_materials["ze_leaf"] = _v10_material(Color("#628958"), 1.0)
    v10_materials["ze_leaf_sun"] = _v10_material(Color("#92A967"), 1.0)
    v10_materials["ze_shopfront"] = _v10_material(Color("#345F65"), 0.48)
    v10_materials["ze_window_warm"] = _v10_material(Color("#E5BE83"), 0.68)
    v10_materials["ze_car_red"] = _v10_material(Color("#B6674C"), 0.58)

func _zero_e_grass_texture() -> ImageTexture:
    var picture: Image = Image.create(128, 128, false, Image.FORMAT_RGB8)
    var noise: FastNoiseLite = FastNoiseLite.new()
    noise.seed = 1928
    noise.frequency = 0.055
    noise.fractal_octaves = 3
    for y: int in range(128):
        for x: int in range(128):
            var shade: float = noise.get_noise_2d(float(x), float(y))
            var grain: float = float((x * 41 + y * 73 + x * y * 3) % 17) / 16.0 - 0.5
            var t: float = clampf(0.45 + shade * 0.31 + grain * 0.065, 0.0, 1.0)
            picture.set_pixel(x, y, Color("#A4B477").lerp(Color("#C9BE8C"), t))
    picture.generate_mipmaps()
    return ImageTexture.create_from_image(picture)

func _v22_add_ground_variation() -> void:
    if not zero_e_session:
        super._v22_add_ground_variation()
    # The small, broad tone changes live in the E ground texture.

func _v24_apply_lighting() -> void:
    super._v24_apply_lighting()
    if not zero_e_session or not is_instance_valid(v10_world_root):
        return
    for child: Node in v10_world_root.get_children():
        if child is WorldEnvironment:
            var world: WorldEnvironment = child as WorldEnvironment
            world.environment.background_color = Color("#DDE4CE")
            world.environment.ambient_light_color = Color("#EDE9DC")
            world.environment.ambient_light_energy = 0.52
        elif child is DirectionalLight3D:
            var light: DirectionalLight3D = child as DirectionalLight3D
            if light.shadow_enabled:
                light.rotation_degrees = Vector3(-48.0, -48.0, 0.0)
                light.light_color = Color("#FFE8C2")
                light.light_energy = 1.50

func _v28_base_camera_size() -> float:
    if not zero_e_session:
        return super._v28_base_camera_size()
    var aspect: float = board_rect.size.x / maxf(board_rect.size.y, 1.0)
    return maxf(23.0, 14.0 / maxf(aspect, 0.4))

func _v10_add_road(p: Vector2i, cell: int) -> void:
    if not zero_e_session:
        super._v10_add_road(p, cell)
        return
    var center: Vector3 = _v10_world_position(p, 0.0)
    var main_road: bool = cell == Cell.ARTERIAL
    var width: float = 0.83 if main_road else 0.54
    var shoulder: float = width + 0.13
    var surface: Material = v10_materials["v22_arterial"] as Material if main_road else v10_materials["v22_local"] as Material
    _v10_add_box(v10_static_root, center + Vector3(0.0, 0.029, 0.0), Vector3(shoulder, 0.040, shoulder), v10_materials["v22_curb"] as Material, false)
    _v10_add_box(v10_static_root, center + Vector3(0.0, 0.055, 0.0), Vector3(width, 0.054, width), surface, false)
    for direction: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
        if not _v04_is_road(p + direction):
            continue
        var extension: Vector3 = Vector3(float(direction.x) * 0.50, 0.0, float(direction.y) * 0.50)
        var w: float = 1.0 + float(direction.x) * 0.12
        var d: float = 1.0 + float(direction.y) * 0.12
        _v10_add_box(v10_static_root, center + extension + Vector3(0.0, 0.029, 0.0), Vector3(shoulder * w, 0.040, shoulder * d), v10_materials["v22_curb"] as Material, false)
        _v10_add_box(v10_static_root, center + extension + Vector3(0.0, 0.055, 0.0), Vector3(width * w, 0.054, width * d), surface, false)
    if not main_road:
        return
    var east: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
    var north: bool = _v04_is_road(p + Vector2i(0, 1)) or _v04_is_road(p + Vector2i(0, -1))
    if east and north:
        for offset: float in [-0.22, -0.07, 0.08, 0.23]:
            _v10_add_box(v10_static_root, center + Vector3(offset, 0.089, -0.31), Vector3(0.06, 0.008, 0.11), v10_materials["v22_stop"] as Material, false)
    elif (p.x + p.y) % 2 == 0:
        var horizontal: bool = east or not north
        var size: Vector3 = Vector3(0.46, 0.008, 0.024) if horizontal else Vector3(0.024, 0.008, 0.46)
        _v10_add_box(v10_static_root, center + Vector3(0.0, 0.089, 0.0), size, v10_materials["v22_lane"] as Material, false)
    if widened.has(_key(p)):
        _v10_add_box(v10_static_root, center + Vector3(0.0, 0.089, -0.37), Vector3(0.60, 0.008, 0.025), v10_materials["widen"] as Material, false)
    if zero_e_state.get("hotspots", {}).has(p):
        _v10_add_box(v10_static_root, center + Vector3(0.0, 0.089, 0.37), Vector3(0.58, 0.008, 0.038), v10_materials["v22_heat"] as Material, false)

func _v10_add_building(p: Vector2i, cell: int) -> void:
    super._v10_add_building(p, cell)
    if not zero_e_session:
        return
    var root: Node3D = v10_building_nodes.get(_key(p)) as Node3D
    if not is_instance_valid(root):
        return
    var seed: int = abs(p.x * 67 + p.y * 43 + cell * 29)
    if cell == Cell.RESIDENTIAL:
        # Street-level detail makes each occupied parcel read as a small block.
        var wall: Material = v10_materials["v21_stucco_warm"] as Material if seed % 2 else v10_materials["v21_stucco_white"] as Material
        _v10_add_box(root, Vector3(-0.29, 0.23, -0.22), Vector3(0.20, 0.34, 0.28), wall)
        _v10_add_box(root, Vector3(-0.29, 0.43, -0.22), Vector3(0.25, 0.07, 0.32), v10_materials["v21_roof_terracotta"] as Material)
        _v10_add_box(root, Vector3(0.30, 0.32, 0.02), Vector3(0.018, 0.17, 0.16), v10_materials["v21_window_blue"] as Material, false)
        _v10_add_box(root, Vector3(-0.30, 0.32, 0.02), Vector3(0.018, 0.17, 0.16), v10_materials["ze_window_warm"] as Material, false)
        _v10_add_box(root, Vector3(0.05, 0.11, 0.36), Vector3(0.22, 0.15, 0.08), v10_materials["v21_hedge"] as Material, false)
    elif cell == Cell.COMMERCIAL:
        for level: int in range(2):
            _v10_add_box(root, Vector3(0.355, 0.28 + level * 0.34, -0.08), Vector3(0.013, 0.13, 0.18), v10_materials["v21_window_blue"] as Material, false)
        _v10_add_box(root, Vector3(0.0, 0.16, 0.366), Vector3(0.34, 0.19, 0.020), v10_materials["ze_shopfront"] as Material, false)
        _v10_add_box(root, Vector3(0.0, 0.30, 0.41), Vector3(0.44, 0.055, 0.11), _v21_awning_material(seed), false)
    else:
        _v10_add_box(root, Vector3(0.28, 0.20, -0.27), Vector3(0.14, 0.30, 0.18), v10_materials["v21_industrial_metal"] as Material)
        _v10_add_box(root, Vector3(-0.27, 0.22, 0.30), Vector3(0.19, 0.15, 0.14), v10_materials["v21_industrial_dark"] as Material, false)

func _v22_should_add_tree(p: Vector2i) -> bool:
    if not zero_e_session:
        return super._v22_should_add_tree(p)
    if v22_tree_count >= 48 or p.x < 1 or p.x > 14 or p.y < 3 or p.y > 18:
        return false
    if p.y in [7, 9, 11, 13]:
        return false
    var marker: int = abs(p.x * 31 + p.y * 47 + p.x * p.y * 7)
    return marker % 5 == 0 or (p.y in [4, 16] and marker % 3 == 0)

func _v10_add_tree(p: Vector2i) -> void:
    if not zero_e_session:
        super._v10_add_tree(p)
        return
    var seed: int = abs(p.x * 41 + p.y * 67)
    var group: Node3D = Node3D.new()
    group.name = "StreetTree_%d_%d" % [p.x, p.y]
    group.position = _v10_world_position(p, 0.0) + Vector3(float(seed % 5 - 2) * 0.060, 0.0, float(seed % 7 - 3) * 0.05)
    v10_static_root.add_child(group)
    var height: float = 0.42 + float(seed % 5) * 0.055
    _v14_add_cylinder(group, Vector3(0.0, height * 0.48, 0.0), 0.040, height, v10_materials["tree_trunk"] as Material)
    var color: Material = [v10_materials["ze_pine"], v10_materials["ze_leaf"], v10_materials["ze_leaf_sun"]][seed % 3] as Material
    for i: int in range(3):
        var crown: SphereMesh = SphereMesh.new()
        crown.radius = 0.18 if i == 0 else 0.13
        crown.height = 0.30 if i == 0 else 0.23
        var leaves: MeshInstance3D = MeshInstance3D.new()
        leaves.mesh = crown
        leaves.material_override = color
        leaves.position = Vector3(float(i - 1) * 0.11, height + (0.12 if i == 0 else 0.04), float((seed + i) % 3 - 1) * 0.065)
        group.add_child(leaves)
    if seed % 3 == 0:
        _v10_add_box(group, Vector3(0.24, 0.055, 0.20), Vector3(0.22, 0.09, 0.15), v10_materials["v21_hedge"] as Material, false)
    v22_tree_count += 1

func _v10_rebuild_static_city() -> void:
    super._v10_rebuild_static_city()
    if not zero_e_session:
        return
    # Low park beds sit in actual empty parcels, and disappear when built on.
    for p: Vector2i in [Vector2i(2, 5), Vector2i(12, 5), Vector2i(2, 15), Vector2i(12, 15)]:
        if int(grid[p.y][p.x]) != Cell.EMPTY:
            continue
        var at: Vector3 = _v10_world_position(p, 0.0)
        _v10_add_box(v10_static_root, at + Vector3(0.0, 0.030, 0.0), Vector3(0.74, 0.034, 0.65), v10_materials["ze_pavement"] as Material, false)
        _v10_add_box(v10_static_root, at + Vector3(0.0, 0.052, 0.0), Vector3(0.56, 0.018, 0.47), v10_materials["ze_park"] as Material, false)
        for i: int in range(3):
            _v10_add_box(v10_static_root, at + Vector3(-0.18 + i * 0.18, 0.073, 0.09), Vector3(0.11, 0.035, 0.09), v10_materials["ze_bloom"] as Material, false)

func _v10_rebuild_vehicles() -> void:
    if not zero_e_session:
        super._v10_rebuild_vehicles()
        return
    _v10_clear_children(v10_vehicle_root)
    v10_vehicle_nodes.clear()
    for i: int in range(16):
        var car: Node3D = Node3D.new()
        car.name = "Traffic_%d" % i
        v10_vehicle_root.add_child(car)
        var body: Material = [v10_materials["car_light"], v10_materials["car_blue"], v10_materials["ze_car_red"], v10_materials["car_gold"]][i % 4] as Material
        _v10_add_box(car, Vector3.ZERO, Vector3(0.31, 0.12, 0.17), body, false)
        _v10_add_box(car, Vector3(-0.015, 0.094, 0.0), Vector3(0.16, 0.075, 0.145), v10_materials["v22_vehicle_glass"] as Material, false)
        _v10_add_box(car, Vector3(-0.16, 0.02, -0.055), Vector3(0.012, 0.033, 0.032), v10_materials["ze_car_red"] as Material, false)
        _v10_add_box(car, Vector3(-0.16, 0.02, 0.055), Vector3(0.012, 0.033, 0.032), v10_materials["ze_car_red"] as Material, false)
        car.set_meta("zero_e_progress", 2.5 + float(i) * 0.31)
        v10_vehicle_nodes.append(car)
    _v10_update_vehicles()
