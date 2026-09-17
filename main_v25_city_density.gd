extends "res://main_v24_visual_north_star.gd"

# MACHI LOOP v0.25 — Visual North Star density / streetscape pass.
# Purpose: push the Vertical Slice toward the locked Art Bible by making the
# city read denser, greener and more authored without changing simulation,
# save data, growth rules or player authority.

var v25_infill_count: int = 0
var v25_vegetation_cluster_count: int = 0
var v25_arterial_detail_count: int = 0

func _v10_create_materials() -> void:
    super._v10_create_materials()
    v10_materials["v25_walk"] = _v10_material(Color("#D8D2C3"), 0.96)
    v10_materials["v25_facade_light"] = _v10_material(Color("#F1EBDD"), 0.90)
    v10_materials["v25_facade_warm"] = _v10_material(Color("#DCCAB4"), 0.92)
    v10_materials["v25_facade_dark"] = _v10_material(Color("#7C8A82"), 0.88)
    v10_materials["v25_roof"] = _v10_material(Color("#A65E4B"), 0.86)
    v10_materials["v25_leaf_light"] = _v10_material(Color("#7FAE68"), 0.98)
    v10_materials["v25_leaf_mid"] = _v10_material(Color("#5D8E54"), 0.98)
    v10_materials["v25_leaf_dark"] = _v10_material(Color("#3F7047"), 0.99)
    v10_materials["v25_planter"] = _v10_material(Color("#B8A98D"), 0.98)

func _v10_rebuild_static_city() -> void:
    v25_infill_count = 0
    v25_vegetation_cluster_count = 0
    v25_arterial_detail_count = 0
    super._v10_rebuild_static_city()
    _v25_add_open_land_vegetation()

# Strengthen the arterial as the player-authored city spine. The underlying
# road mesh remains authoritative; this adds thin pedestrian edges only on
# straight segments so intersections stay visually clean.
func _v10_add_road(p: Vector2i, cell: int) -> void:
    super._v10_add_road(p, cell)
    if cell != Cell.ARTERIAL:
        return

    var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
    var vertical: bool = _v04_is_road(p + Vector2i(0, 1)) or _v04_is_road(p + Vector2i(0, -1))
    if horizontal == vertical:
        return

    var world: Vector3 = _v10_world_position(p, 0.0)
    var walk: Material = v10_materials["v25_walk"] as Material
    if horizontal:
        _v10_add_box(v10_static_root, world + Vector3(0.0, 0.105, 0.47), Vector3(1.02, 0.022, 0.10), walk, false)
        _v10_add_box(v10_static_root, world + Vector3(0.0, 0.105, -0.47), Vector3(1.02, 0.022, 0.10), walk, false)
    else:
        _v10_add_box(v10_static_root, world + Vector3(0.47, 0.105, 0.0), Vector3(0.10, 0.022, 1.02), walk, false)
        _v10_add_box(v10_static_root, world + Vector3(-0.47, 0.105, 0.0), Vector3(0.10, 0.022, 1.02), walk, false)
    v25_arterial_detail_count += 1

# Keep the simulation's one-cell zoning semantics, but enrich mature parcels
# with deterministic secondary massing. This creates the visual impression of
# denser blocks without pretending the player placed extra buildings.
func _v10_add_building(p: Vector2i, cell: int) -> void:
    super._v10_add_building(p, cell)
    if city_level < 2 and population < 26:
        return
    var k: String = _key(p)
    if not v10_building_nodes.has(k):
        return
    var root: Node3D = v10_building_nodes[k] as Node3D
    if root == null:
        return
    _v25_add_parcel_infill(root, p, cell)

func _v25_add_parcel_infill(root: Node3D, p: Vector2i, cell: int) -> void:
    var seed: int = abs(p.x * 73 + p.y * 97 + cell * 41)
    var facade: Material = v10_materials["v25_facade_light"] as Material
    if seed % 3 == 1:
        facade = v10_materials["v25_facade_warm"] as Material
    elif seed % 3 == 2:
        facade = v10_materials["v25_facade_dark"] as Material

    if cell == Cell.RESIDENTIAL:
        var side: float = -0.27 if seed % 2 == 0 else 0.27
        _v10_add_box(root, Vector3(side, 0.20, -0.20), Vector3(0.24, 0.34, 0.28), facade)
        _v10_add_box(root, Vector3(side, 0.39, -0.20), Vector3(0.28, 0.07, 0.32), v10_materials["v25_roof"] as Material)
    elif cell == Cell.COMMERCIAL:
        var side: float = -0.23 if seed % 2 == 0 else 0.23
        _v10_add_box(root, Vector3(side, 0.43, -0.18), Vector3(0.30, 0.76, 0.34), facade)
        _v10_add_box(root, Vector3(side, 0.48, 0.005), Vector3(0.21, 0.42, 0.014), v10_materials["v21_window_blue"] as Material, false)
    else:
        _v10_add_box(root, Vector3(0.27, 0.18, -0.20), Vector3(0.28, 0.28, 0.32), facade)
        _v14_add_cylinder(root, Vector3(-0.25, 0.28, -0.18), 0.055, 0.44, v10_materials["v21_industrial_metal"] as Material)

    v25_infill_count += 1

# More vegetation is rendered as lightweight decorative clusters on empty
# simulation cells. The grid remains untouched, so buildability and save data
# are unchanged. Clusters are deliberately sparse and deterministic.
func _v25_add_open_land_vegetation() -> void:
    if not is_instance_valid(v10_static_root):
        return
    var cap: int = 18
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if v25_vegetation_cluster_count >= cap:
                return
            if int(grid[y][x]) != Cell.EMPTY:
                continue
            var marker: int = abs(x * 43 + y * 71 + unlocked_cols * 17)
            if marker % 19 != 0:
                continue
            var p: Vector2i = Vector2i(x, y)
            _v25_add_vegetation_cluster(p, marker)

func _v25_add_vegetation_cluster(p: Vector2i, seed: int) -> void:
    var root: Node3D = Node3D.new()
    root.name = "V25Vegetation_%d_%d" % [p.x, p.y]
    root.position = _v10_world_position(p, 0.0)
    v10_static_root.add_child(root)

    var leaf_keys: Array[String] = ["v25_leaf_light", "v25_leaf_mid", "v25_leaf_dark"]
    var leaf: Material = v10_materials[leaf_keys[seed % leaf_keys.size()]] as Material
    var offsets: Array[Vector3] = [
        Vector3(-0.12, 0.0, 0.06),
        Vector3(0.12, 0.0, -0.06)
    ]
    if seed % 3 == 0:
        offsets.append(Vector3(0.02, 0.0, 0.18))

    for i: int in range(offsets.size()):
        var off: Vector3 = offsets[i]
        var h: float = 0.30 + float((seed + i * 7) % 4) * 0.05
        _v14_add_cylinder(root, off + Vector3(0.0, h * 0.45, 0.0), 0.024, h * 0.64, v10_materials["tree_trunk"] as Material)
        _v10_add_box(root, off + Vector3(0.0, h, 0.0), Vector3(0.24, 0.23, 0.24), leaf, false)
        _v10_add_box(root, off + Vector3(0.05, h + 0.08, -0.03), Vector3(0.17, 0.16, 0.17), leaf, false)

    if seed % 2 == 0:
        _v10_add_box(root, Vector3(0.0, 0.045, 0.0), Vector3(0.44, 0.06, 0.18), v10_materials["v25_planter"] as Material, false)
    v25_vegetation_cluster_count += 1

# Slightly stronger key light and lower ambient flattening make building height
# and street canyons read more clearly while retaining the warm North Star look.
func _v24_apply_lighting() -> void:
    super._v24_apply_lighting()
    if not is_instance_valid(v10_world_root):
        return
    for child: Node in v10_world_root.get_children():
        if child is WorldEnvironment:
            var world_environment: WorldEnvironment = child as WorldEnvironment
            if world_environment.environment != null:
                world_environment.environment.ambient_light_energy = 0.60
                world_environment.environment.background_color = Color("#DDE7D3")
        elif child is DirectionalLight3D:
            var light: DirectionalLight3D = child as DirectionalLight3D
            if light.shadow_enabled:
                light.light_energy = 1.38
                light.light_color = Color("#FFF0D4")
