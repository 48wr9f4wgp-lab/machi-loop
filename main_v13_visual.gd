extends "res://main_v12_web3d.gd"

# MACHI LOOP v0.13 — first serious 3D visual pass.
# Simulation, save data and input rules remain unchanged; this layer only improves rendering.

func _v10_setup_renderer() -> void:
    super._v10_setup_renderer()
    if is_instance_valid(v10_camera):
        v10_camera.size = 23.5
        v10_camera.position = Vector3(13.5, 19.5, 15.5)
        v10_camera.look_at(Vector3(0.0, 0.35, 0.0), Vector3.UP)
        v10_camera.near = 0.08
        v10_camera.far = 100.0
    if is_instance_valid(v10_viewport) and v10_viewport.world_3d != null and v10_viewport.world_3d.environment != null:
        var env: Environment = v10_viewport.world_3d.environment
        env.background_color = Color("#BFD0BF")
        env.ambient_light_color = Color("#C9DCCB")
        env.ambient_light_energy = 0.62
    _v10_sync_scene(true)

func _v10_create_materials() -> void:
    super._v10_create_materials()
    v10_materials["ground"] = _v10_material(Color("#9FC28F"), 0.98)
    v10_materials["ground_alt"] = _v10_material(Color("#AACB9A"), 0.98)
    v10_materials["locked"] = _v10_material(Color("#C9D0C7"), 1.0)
    v10_materials["grid"] = _v10_material(Color("#76906F"), 1.0)
    v10_materials["arterial"] = _v10_material(Color("#2B3130"), 0.94)
    v10_materials["local"] = _v10_material(Color("#56615E"), 0.95)
    v10_materials["lane"] = _v10_material(Color("#F0D36C"), 0.78)
    v10_materials["sidewalk"] = _v10_material(Color("#C7CEC4"), 0.98)
    v10_materials["curb"] = _v10_material(Color("#A7B0A5"), 0.98)
    v10_materials["grass_dark"] = _v10_material(Color("#84AC79"), 0.98)
    v10_materials["grass_light"] = _v10_material(Color("#B4D19F"), 0.98)
    v10_materials["home_wall_alt"] = _v10_material(Color("#E7D8C5"), 0.90)
    v10_materials["home_roof_alt"] = _v10_material(Color("#CF765A"), 0.82)
    v10_materials["commercial_dark"] = _v10_material(Color("#4F8098"), 0.46)
    v10_materials["commercial_light"] = _v10_material(Color("#D1E7ED"), 0.44)
    v10_materials["industrial_dark"] = _v10_material(Color("#9C754C"), 0.92)
    v10_materials["roof_detail"] = _v10_material(Color("#66746D"), 0.90)
    v10_materials["tree_leaf2"] = _v10_material(Color("#73A95F"), 0.98)
    v10_materials["tree_leaf3"] = _v10_material(Color("#4C8A58"), 0.98)
    v10_materials["park"] = _v10_material(Color("#7EAE73"), 0.98)

func _v10_rebuild_static_city() -> void:
    super._v10_rebuild_static_city()
    if not is_instance_valid(v10_static_root):
        return

    # Parcel colour breaks up the large flat board and gives the city a miniature-diorama read.
    for y: int in range(0, GRID_H, 4):
        for x: int in range(0, unlocked_cols, 4):
            if ((x / 4) + (y / 4)) % 2 != 0:
                continue
            var sx: float = minf(3.72, float(unlocked_cols - x) - 0.12)
            var sz: float = minf(3.72, float(GRID_H - y) - 0.12)
            if sx <= 0.1 or sz <= 0.1:
                continue
            var center: Vector3 = Vector3(
                float(x) - float(GRID_W) * 0.5 + sx * 0.5 + 0.06,
                0.004,
                float(y) - float(GRID_H) * 0.5 + sz * 0.5 + 0.06
            )
            _v10_add_box(v10_static_root, center, Vector3(sx, 0.009, sz), v10_materials["ground_alt"] as Material, false)

    # Small park/grass pads add visual anchors without changing simulation semantics.
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) != Cell.EMPTY:
                continue
            var marker: int = abs(x * 37 + y * 53 + x * y * 11)
            if marker % 41 == 0:
                var p: Vector2i = Vector2i(x, y)
                _v10_add_box(v10_static_root, _v10_world_position(p, 0.016), Vector3(0.72, 0.025, 0.72), v10_materials["park"] as Material, false)
                if marker % 82 == 0:
                    _v13_add_tree_cluster(p)

func _v10_add_road(p: Vector2i, cell: int) -> void:
    super._v10_add_road(p, cell)
    var world: Vector3 = _v10_world_position(p, 0.052)
    var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
    var vertical: bool = _v04_is_road(p + Vector2i(0, 1)) or _v04_is_road(p + Vector2i(0, -1))
    var road_half: float = 0.38 if cell == Cell.ARTERIAL else 0.29
    var curb_offset: float = road_half + 0.07

    if horizontal or not vertical:
        _v10_add_box(v10_static_root, world + Vector3(0.0, -0.01, curb_offset), Vector3(0.96, 0.035, 0.10), v10_materials["sidewalk"] as Material, false)
        _v10_add_box(v10_static_root, world + Vector3(0.0, -0.01, -curb_offset), Vector3(0.96, 0.035, 0.10), v10_materials["sidewalk"] as Material, false)
    if vertical:
        _v10_add_box(v10_static_root, world + Vector3(curb_offset, -0.01, 0.0), Vector3(0.10, 0.035, 0.96), v10_materials["sidewalk"] as Material, false)
        _v10_add_box(v10_static_root, world + Vector3(-curb_offset, -0.01, 0.0), Vector3(0.10, 0.035, 0.96), v10_materials["sidewalk"] as Material, false)

func _v10_add_building(p: Vector2i, cell: int) -> void:
    var root: Node3D = Node3D.new()
    root.position = _v10_world_position(p, 0.0)
    root.name = "Building_%d_%d" % [p.x, p.y]
    v10_static_root.add_child(root)
    v10_building_nodes[_key(p)] = root

    var seed: int = abs(p.x * 31 + p.y * 47 + cell * 13)
    _v10_add_box(root, Vector3(0.0, 0.025, 0.0), Vector3(0.86, 0.05, 0.86), v10_materials["sidewalk"] as Material, false)

    if cell == Cell.RESIDENTIAL:
        _v13_add_residential(root, seed)
    elif cell == Cell.COMMERCIAL:
        _v13_add_commercial(root, seed)
    else:
        _v13_add_industrial(root, seed)

func _v13_add_residential(root: Node3D, seed: int) -> void:
    var variant: int = seed % 4
    var wall: Material = v10_materials["home_wall"] as Material if variant % 2 == 0 else v10_materials["home_wall_alt"] as Material
    var roof: Material = v10_materials["home_roof"] as Material if variant < 2 else v10_materials["home_roof_alt"] as Material

    if variant == 0:
        _v10_add_box(root, Vector3(-0.13, 0.36, 0.0), Vector3(0.52, 0.66, 0.64), wall)
        _v10_add_box(root, Vector3(-0.13, 0.73, 0.0), Vector3(0.58, 0.12, 0.70), roof)
        _v10_add_box(root, Vector3(0.24, 0.23, 0.15), Vector3(0.20, 0.40, 0.28), wall)
    elif variant == 1:
        _v10_add_box(root, Vector3(0.0, 0.43, 0.0), Vector3(0.68, 0.80, 0.62), wall)
        _v10_add_box(root, Vector3(0.0, 0.87, 0.0), Vector3(0.72, 0.10, 0.66), roof)
        _v10_add_box(root, Vector3(0.0, 0.46, 0.321), Vector3(0.32, 0.15, 0.018), v10_materials["window"] as Material, false)
    elif variant == 2:
        _v10_add_box(root, Vector3(0.0, 0.31, -0.12), Vector3(0.72, 0.56, 0.42), wall)
        _v10_add_box(root, Vector3(0.0, 0.63, -0.12), Vector3(0.77, 0.12, 0.47), roof)
        _v10_add_box(root, Vector3(-0.20, 0.24, 0.24), Vector3(0.24, 0.42, 0.24), wall)
        _v10_add_box(root, Vector3(0.21, 0.18, 0.25), Vector3(0.22, 0.30, 0.20), wall)
    else:
        _v10_add_box(root, Vector3(-0.17, 0.40, 0.0), Vector3(0.36, 0.74, 0.66), wall)
        _v10_add_box(root, Vector3(0.20, 0.30, 0.02), Vector3(0.30, 0.54, 0.58), wall)
        _v10_add_box(root, Vector3(-0.17, 0.80, 0.0), Vector3(0.42, 0.10, 0.72), roof)
        _v10_add_box(root, Vector3(0.20, 0.59, 0.02), Vector3(0.36, 0.10, 0.64), roof)

    _v10_add_box(root, Vector3(0.0, 0.055, 0.38), Vector3(0.24, 0.03, 0.28), v10_materials["curb"] as Material, false)

func _v13_add_commercial(root: Node3D, seed: int) -> void:
    var variant: int = seed % 4
    var h: float = 1.30 + float(seed % 5) * 0.23
    var body: Material = v10_materials["commercial"] as Material if variant % 2 == 0 else v10_materials["commercial_light"] as Material
    var trim: Material = v10_materials["commercial_dark"] as Material

    if variant == 0:
        _v10_add_box(root, Vector3(0.0, h * 0.5 + 0.04, 0.0), Vector3(0.70, h, 0.70), body)
        _v10_add_box(root, Vector3(0.0, h + 0.10, 0.0), Vector3(0.76, 0.16, 0.76), trim)
    elif variant == 1:
        _v10_add_box(root, Vector3(-0.15, h * 0.46, 0.0), Vector3(0.43, h * 0.88, 0.68), body)
        _v10_add_box(root, Vector3(0.20, h * 0.34, 0.02), Vector3(0.28, h * 0.64, 0.58), trim)
    elif variant == 2:
        _v10_add_box(root, Vector3(0.0, h * 0.43, 0.0), Vector3(0.74, h * 0.82, 0.62), body)
        _v10_add_box(root, Vector3(0.0, h * 0.86, 0.0), Vector3(0.54, 0.24, 0.48), trim)
        _v10_add_box(root, Vector3(0.0, h + 0.12, 0.0), Vector3(0.32, 0.18, 0.30), body)
    else:
        _v10_add_box(root, Vector3(0.0, h * 0.50, 0.0), Vector3(0.62, h, 0.62), trim)
        _v10_add_box(root, Vector3(0.0, h * 0.50, 0.315), Vector3(0.47, h * 0.82, 0.018), body, false)

    for band: int in range(3):
        var wy: float = 0.38 + float(band) * minf(0.42, h / 4.0)
        if wy < h - 0.12:
            _v10_add_box(root, Vector3(0.0, wy, 0.356), Vector3(0.44, 0.08, 0.016), v10_materials["window"] as Material, false)

func _v13_add_industrial(root: Node3D, seed: int) -> void:
    var variant: int = seed % 3
    var h: float = 0.60 + float(seed % 4) * 0.12
    var body: Material = v10_materials["industrial"] as Material
    var dark: Material = v10_materials["industrial_dark"] as Material

    _v10_add_box(root, Vector3(0.0, h * 0.5 + 0.04, 0.0), Vector3(0.82, h, 0.74), body)
    _v10_add_box(root, Vector3(0.0, h + 0.08, 0.0), Vector3(0.86, 0.14, 0.78), dark)
    if variant == 0:
        _v10_add_box(root, Vector3(0.24, h + 0.31, -0.19), Vector3(0.15, 0.48, 0.15), dark)
        _v10_add_box(root, Vector3(-0.21, h + 0.20, 0.17), Vector3(0.24, 0.24, 0.20), v10_materials["roof_detail"] as Material)
    elif variant == 1:
        _v10_add_box(root, Vector3(-0.23, h + 0.27, -0.16), Vector3(0.13, 0.40, 0.13), dark)
        _v10_add_box(root, Vector3(0.20, h + 0.27, -0.16), Vector3(0.13, 0.40, 0.13), dark)
    else:
        _v10_add_box(root, Vector3(0.0, h + 0.20, 0.0), Vector3(0.46, 0.24, 0.36), v10_materials["roof_detail"] as Material)
        _v10_add_box(root, Vector3(0.26, h + 0.32, -0.18), Vector3(0.12, 0.48, 0.12), dark)

func _v10_add_tree(p: Vector2i) -> void:
    var root: Node3D = Node3D.new()
    var seed: int = abs(p.x * 19 + p.y * 43)
    var jitter_x: float = (float(seed % 5) - 2.0) * 0.045
    var jitter_z: float = (float((seed / 5) % 5) - 2.0) * 0.045
    root.position = _v10_world_position(p, 0.0) + Vector3(jitter_x, 0.0, jitter_z)
    v10_static_root.add_child(root)
    _v10_add_box(root, Vector3(0.0, 0.18, 0.0), Vector3(0.085, 0.36, 0.085), v10_materials["tree_trunk"] as Material)
    _v13_add_leaf(root, Vector3(0.0, 0.48, 0.0), 0.22, seed % 3)
    if seed % 4 == 0:
        _v13_add_leaf(root, Vector3(0.12, 0.42, 0.02), 0.16, (seed + 1) % 3)

func _v13_add_tree_cluster(p: Vector2i) -> void:
    var base: Vector3 = _v10_world_position(p, 0.0)
    for i: int in range(3):
        var root: Node3D = Node3D.new()
        root.position = base + Vector3(-0.20 + float(i) * 0.19, 0.0, 0.08 * float((i % 2) * 2 - 1))
        v10_static_root.add_child(root)
        _v10_add_box(root, Vector3(0.0, 0.13, 0.0), Vector3(0.07, 0.26, 0.07), v10_materials["tree_trunk"] as Material)
        _v13_add_leaf(root, Vector3(0.0, 0.36, 0.0), 0.17 + float(i) * 0.018, i % 3)

func _v13_add_leaf(parent: Node3D, position: Vector3, radius: float, variant: int) -> void:
    var crown: SphereMesh = SphereMesh.new()
    crown.radius = radius
    crown.height = radius * 1.75
    crown.radial_segments = 8
    crown.rings = 4
    var leaves: MeshInstance3D = MeshInstance3D.new()
    leaves.mesh = crown
    var key: String = "tree_leaf"
    if variant == 1:
        key = "tree_leaf2"
    elif variant == 2:
        key = "tree_leaf3"
    leaves.material_override = v10_materials[key] as Material
    leaves.position = position
    parent.add_child(leaves)
