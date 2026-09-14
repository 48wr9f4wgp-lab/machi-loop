extends "res://main_v21_assets.gd"

# MACHI LOOP — Production Visual / World Pass 2.
# Safe pre-integration layer built above v0.21 while v0.22A Feedback remains reserved locally.
# Goals: road hierarchy, lower HUD occlusion, stronger silhouettes, tier landmark,
# organic ground/vegetation, and clearer miniature vehicles without changing simulation.

var v22_tree_count: int = 0
var v22_landmark_node: Node3D

func _v10_create_materials() -> void:
    super._v10_create_materials()
    v10_materials["v22_ground"] = _v10_material(Color("#789D70"), 0.99)
    v10_materials["v22_ground_soft"] = _v10_material(Color("#82A879"), 0.99)
    v10_materials["v22_ground_dark"] = _v10_material(Color("#6F9469"), 0.99)
    v10_materials["v22_arterial"] = _v10_material(Color("#222A28"), 0.94)
    v10_materials["v22_local"] = _v10_material(Color("#65706C"), 0.96)
    v10_materials["v22_curb"] = _v10_material(Color("#BEC8BE"), 0.98)
    v10_materials["v22_lane"] = _v10_material(Color("#E4C96F"), 0.82)
    v10_materials["v22_stop"] = _v10_material(Color("#E8E7DC"), 0.88)
    v10_materials["v22_heat"] = _v10_material(Color("#D9654E"), 0.86)
    v10_materials["v22_tree_light"] = _v10_material(Color("#79B86E"), 0.98)
    v10_materials["v22_tree_mid"] = _v10_material(Color("#5FA05E"), 0.98)
    v10_materials["v22_tree_dark"] = _v10_material(Color("#477F50"), 0.99)
    v10_materials["v22_civic_stone"] = _v10_material(Color("#E7E1D2"), 0.90)
    v10_materials["v22_civic_gold"] = _v10_material(Color("#D2A34F"), 0.76)
    v10_materials["v22_civic_glass"] = _v10_material(Color("#78AFC0"), 0.44)
    v10_materials["v22_vehicle_glass"] = _v10_material(Color("#38515A"), 0.42)

# Rebuild the world without the old checker-carpet. Geometry remains capped and deterministic.
func _v10_rebuild_static_city() -> void:
    _v10_clear_children(v10_static_root)
    v10_building_nodes.clear()
    v22_tree_count = 0
    v22_landmark_node = null

    var open_width: float = float(unlocked_cols)
    if open_width > 0.0:
        var open_center_x: float = -float(GRID_W) * 0.5 + open_width * 0.5
        _v10_add_box(v10_static_root, Vector3(open_center_x, -0.045, 0.0), Vector3(open_width, 0.09, float(GRID_H)), v10_materials["v22_ground"] as Material, false)
        _v22_add_ground_variation()

    var locked_width: float = float(GRID_W - unlocked_cols)
    if locked_width > 0.0:
        var locked_center_x: float = -float(GRID_W) * 0.5 + float(unlocked_cols) + locked_width * 0.5
        _v10_add_box(v10_static_root, Vector3(locked_center_x, -0.04, 0.0), Vector3(locked_width, 0.08, float(GRID_H)), v10_materials["locked"] as Material, false)

    if unlocked_cols < GRID_W:
        var boundary_x: float = -float(GRID_W) * 0.5 + float(unlocked_cols)
        _v10_add_box(v10_static_root, Vector3(boundary_x, 0.055, 0.0), Vector3(0.075, 0.11, float(GRID_H)), v10_materials["boundary"] as Material, false)

    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            var cell: int = int(grid[y][x])
            if cell == Cell.ARTERIAL or cell == Cell.LOCAL:
                _v10_add_road(p, cell)
            elif cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
                _v10_add_building(p, cell)
            elif _v22_should_add_tree(p):
                _v10_add_tree(p)

    _v14_add_street_furniture()
    _v21_add_public_realm_accents()
    _v22_add_city_landmark()

func _v22_add_ground_variation() -> void:
    # Broad low-contrast patches replace the repetitive 4x4 checker read.
    var patch_count: int = 6 if unlocked_cols >= 12 else 4
    for i: int in range(patch_count):
        var px: float = -float(GRID_W) * 0.5 + 1.6 + fmod(float(i * 37 + unlocked_cols * 5), maxf(2.0, float(unlocked_cols) - 3.2))
        var pz: float = -float(GRID_H) * 0.5 + 2.1 + fmod(float(i * 53 + unlocked_cols * 3), float(GRID_H) - 4.2)
        var sx: float = 2.4 + float((i * 3) % 4) * 0.55
        var sz: float = 2.1 + float((i * 5) % 4) * 0.60
        var material: Material = v10_materials["v22_ground_soft"] as Material if i % 2 == 0 else v10_materials["v22_ground_dark"] as Material
        _v10_add_box(v10_static_root, Vector3(px, 0.002, pz), Vector3(sx, 0.006, sz), material, false)

# Road hierarchy: arterial roads dominate; local roads are deliberately quiet.
func _v10_add_road(p: Vector2i, cell: int) -> void:
    var is_arterial: bool = cell == Cell.ARTERIAL
    var world: Vector3 = _v10_world_position(p, 0.0)
    var width: float = 0.72 if is_arterial else 0.46
    var curb_width: float = width + (0.12 if is_arterial else 0.08)
    var surface: Material = v10_materials["v22_arterial"] as Material if is_arterial else v10_materials["v22_local"] as Material

    _v10_add_box(v10_static_root, world + Vector3(0.0, 0.030, 0.0), Vector3(curb_width, 0.038, curb_width), v10_materials["v22_curb"] as Material, false)
    _v10_add_box(v10_static_root, world + Vector3(0.0, 0.055, 0.0), Vector3(width, 0.060, width), surface, false)

    var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
    var neighbors: int = 0
    for d: Vector2i in dirs:
        if not _v04_is_road(p + d):
            continue
        neighbors += 1
        if d.x != 0:
            _v10_add_box(v10_static_root, world + Vector3(float(d.x) * 0.28, 0.030, 0.0), Vector3(0.58, 0.038, curb_width), v10_materials["v22_curb"] as Material, false)
            _v10_add_box(v10_static_root, world + Vector3(float(d.x) * 0.28, 0.055, 0.0), Vector3(0.58, 0.060, width), surface, false)
        else:
            _v10_add_box(v10_static_root, world + Vector3(0.0, 0.030, float(d.y) * 0.28), Vector3(curb_width, 0.038, 0.58), v10_materials["v22_curb"] as Material, false)
            _v10_add_box(v10_static_root, world + Vector3(0.0, 0.055, float(d.y) * 0.28), Vector3(width, 0.060, 0.58), surface, false)

    if not is_arterial:
        return

    var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
    var vertical: bool = _v04_is_road(p + Vector2i(0, 1)) or _v04_is_road(p + Vector2i(0, -1))
    if horizontal or not vertical:
        _v10_add_box(v10_static_root, world + Vector3(0.0, 0.090, 0.0), Vector3(0.92, 0.010, 0.028), v10_materials["v22_lane"] as Material, false)
    if vertical:
        _v10_add_box(v10_static_root, world + Vector3(0.0, 0.090, 0.0), Vector3(0.028, 0.010, 0.92), v10_materials["v22_lane"] as Material, false)

    # Crosswalk noise is intentionally reduced to a pair of stop bars on selected major junctions.
    if neighbors >= 3 and (p.x * 11 + p.y * 7) % 2 == 0:
        _v10_add_box(v10_static_root, world + Vector3(0.0, 0.096, 0.25), Vector3(0.46, 0.012, 0.055), v10_materials["v22_stop"] as Material, false)
        _v10_add_box(v10_static_root, world + Vector3(0.25, 0.096, 0.0), Vector3(0.055, 0.012, 0.46), v10_materials["v22_stop"] as Material, false)

    if widened.has(_key(p)):
        var edge: float = 0.43
        _v10_add_box(v10_static_root, world + Vector3(edge, 0.092, 0.0), Vector3(0.022, 0.018, 0.92), v10_materials["widen"] as Material, false)
        _v10_add_box(v10_static_root, world + Vector3(-edge, 0.092, 0.0), Vector3(0.022, 0.018, 0.92), v10_materials["widen"] as Material, false)

    var heat: float = clampf(_road_load(p) / maxf(0.1, _road_capacity(p)), 0.0, 1.5)
    if heat > 1.02:
        _v10_add_box(v10_static_root, world + Vector3(0.0, 0.098, -0.42), Vector3(0.62, 0.014, 0.025), v10_materials["v22_heat"] as Material, false)

func _v14_add_street_furniture() -> void:
    var lamp_count: int = 0
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if lamp_count >= 16:
                return
            var p: Vector2i = Vector2i(x, y)
            if int(grid[y][x]) != Cell.ARTERIAL:
                continue
            var marker: int = abs(x * 19 + y * 31 + x * y * 5)
            if marker % 7 != 0:
                continue
            var world: Vector3 = _v10_world_position(p, 0.0)
            var side: float = 0.48 if marker % 2 == 0 else -0.48
            var pole_pos: Vector3 = world + Vector3(side, 0.29, 0.34)
            _v14_add_cylinder(v10_static_root, pole_pos, 0.022, 0.52, v10_materials["lamp"] as Material)
            _v10_add_box(v10_static_root, pole_pos + Vector3(0.0, 0.27, 0.0), Vector3(0.08, 0.05, 0.08), v10_materials["lamp_glow"] as Material, false)
            lamp_count += 1

func _v22_should_add_tree(p: Vector2i) -> bool:
    if v22_tree_count >= 24:
        return false
    var marker: int = abs(p.x * 31 + p.y * 47 + p.x * p.y * 7)
    return marker % 13 == 0

func _v10_add_tree(p: Vector2i) -> void:
    if v22_tree_count >= 24:
        return
    var root: Node3D = Node3D.new()
    root.name = "V22Tree_%d_%d" % [p.x, p.y]
    root.position = _v10_world_position(p, 0.0)
    v10_static_root.add_child(root)
    var seed: int = abs(p.x * 41 + p.y * 67)
    var variant: int = seed % 4
    var crown_mat: Material = [v10_materials["v22_tree_light"], v10_materials["v22_tree_mid"], v10_materials["v22_tree_dark"]][seed % 3] as Material

    if variant == 0:
        _v22_tree_stem(root, Vector3.ZERO, 0.34, 0.22, crown_mat)
    elif variant == 1:
        _v22_tree_stem(root, Vector3(-0.12, 0.0, 0.03), 0.30, 0.18, crown_mat)
        _v22_tree_stem(root, Vector3(0.12, 0.0, -0.05), 0.40, 0.21, crown_mat)
    elif variant == 2:
        _v22_tree_stem(root, Vector3(0.0, 0.0, 0.0), 0.46, 0.19, crown_mat)
        _v10_add_box(root, Vector3(0.0, 0.69, 0.0), Vector3(0.30, 0.12, 0.30), crown_mat, false)
    else:
        _v22_tree_stem(root, Vector3(-0.14, 0.0, 0.08), 0.31, 0.16, crown_mat)
        _v22_tree_stem(root, Vector3(0.11, 0.0, 0.10), 0.36, 0.18, crown_mat)
        _v22_tree_stem(root, Vector3(0.02, 0.0, -0.13), 0.28, 0.15, crown_mat)
    v22_tree_count += 1

func _v22_tree_stem(parent: Node3D, offset: Vector3, height: float, radius: float, crown_mat: Material) -> void:
    _v14_add_cylinder(parent, offset + Vector3(0.0, height * 0.42, 0.0), 0.035, height * 0.62, v10_materials["tree_trunk"] as Material)
    var crown: SphereMesh = SphereMesh.new()
    crown.radius = radius
    crown.height = radius * 1.75
    var leaves: MeshInstance3D = MeshInstance3D.new()
    leaves.mesh = crown
    leaves.material_override = crown_mat
    leaves.position = offset + Vector3(0.0, height, 0.0)
    parent.add_child(leaves)

# Keep public-space accents rare and progression-aware so they read as authored places, not noise.
func _v21_add_public_realm_accents() -> void:
    var target: int = 0
    if city_level >= 2:
        target = 1
    if city_level >= 4:
        target = 2
    if v18_green and city_level >= 3:
        target = mini(3, target + 1)
    var count: int = 0
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if count >= target:
                return
            if int(grid[y][x]) != Cell.EMPTY:
                continue
            var marker: int = abs(x * 71 + y * 97 + x * y * 13)
            if marker % 149 != 0:
                continue
            var pos: Vector3 = _v10_world_position(Vector2i(x, y), 0.0)
            _v10_add_box(v10_static_root, pos + Vector3(0.0, 0.028, 0.0), Vector3(0.68, 0.040, 0.68), v10_materials["park"] as Material, false)
            _v14_add_cylinder(v10_static_root, pos + Vector3(0.0, 0.075, 0.0), 0.20, 0.09, v10_materials["v21_fountain_stone"] as Material)
            _v14_add_cylinder(v10_static_root, pos + Vector3(0.0, 0.125, 0.0), 0.14, 0.035, v10_materials["v21_water"] as Material)
            count += 1

# Stronger silhouette differences on top of the existing 8/8/6 catalog.
func _v21_add_residential(root: Node3D, seed: int, variant: int) -> void:
    super._v21_add_residential(root, seed, variant)
    if variant == 5:
        _v10_add_box(root, Vector3(0.31, 0.34, -0.10), Vector3(0.24, 0.52, 0.44), v10_materials["v21_stucco_sage"] as Material)
    elif variant == 6:
        _v10_add_box(root, Vector3(-0.29, 0.52, 0.08), Vector3(0.22, 0.88, 0.46), v10_materials["v21_stucco_warm"] as Material)
    elif variant >= 7:
        _v10_add_box(root, Vector3(0.26, 1.35, 0.02), Vector3(0.18, 0.40, 0.40), v10_materials["v21_window_blue"] as Material)

func _v21_add_commercial(root: Node3D, seed: int, variant: int) -> void:
    super._v21_add_commercial(root, seed, variant)
    if variant == 2:
        _v10_add_box(root, Vector3(0.32, 0.43, -0.08), Vector3(0.28, 0.72, 0.48), v10_materials["v21_commercial_frame"] as Material)
    elif variant == 3:
        _v10_add_box(root, Vector3(0.26, 0.92, 0.04), Vector3(0.20, 0.56, 0.42), v10_materials["v21_window_blue"] as Material)
    elif variant == 4:
        _v10_add_box(root, Vector3(-0.25, 1.24, 0.06), Vector3(0.18, 0.70, 0.42), v10_materials["v21_glass_dark"] as Material)
    elif variant == 5:
        _v10_add_box(root, Vector3(0.22, 1.32, -0.02), Vector3(0.18, 1.45, 0.36), v10_materials["v21_glass_light"] as Material)

func _v21_add_industrial(root: Node3D, seed: int, variant: int) -> void:
    super._v21_add_industrial(root, seed, variant)
    if variant == 0:
        _v10_add_box(root, Vector3(-0.30, 0.24, -0.10), Vector3(0.28, 0.38, 0.52), v10_materials["v21_industrial_body"] as Material)
    elif variant == 3:
        _v10_add_box(root, Vector3(0.0, 0.13, 0.36), Vector3(0.78, 0.16, 0.20), v10_materials["v21_industrial_metal"] as Material, false)
    elif variant >= 5:
        _v10_add_box(root, Vector3(-0.30, 0.25, 0.21), Vector3(0.20, 0.40, 0.28), v10_materials["v21_industrial_dark"] as Material)

func _v22_add_city_landmark() -> void:
    if city_level < 3:
        return
    var best: Vector2i = Vector2i(-1, -1)
    var best_distance: float = 99999.0
    var center: Vector2 = Vector2(float(unlocked_cols - 1) * 0.5, float(GRID_H - 1) * 0.5)
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) != Cell.COMMERCIAL:
                continue
            var d: float = Vector2(float(x), float(y)).distance_squared_to(center)
            if d < best_distance:
                best_distance = d
                best = Vector2i(x, y)
    if best.x < 0:
        return
    var key: String = _key(best)
    if not v10_building_nodes.has(key):
        return
    var root: Node3D = v10_building_nodes[key] as Node3D
    var seed: int = abs(best.x * 67 + best.y * 43 + Cell.COMMERCIAL * 29)
    var variant: int = AssetCatalog.commercial_variant(seed, city_level)
    var base_y: float = _v22_commercial_roof_height(variant)
    var anchor: Node3D = Node3D.new()
    anchor.name = "V22CityLandmark"
    root.add_child(anchor)
    var tower_h: float = 0.36 + float(clampi(city_level - 3, 0, 3)) * 0.13
    _v10_add_box(anchor, Vector3(0.0, base_y + tower_h * 0.5 + 0.04, 0.0), Vector3(0.30, tower_h, 0.30), v10_materials["v22_civic_stone"] as Material)
    _v10_add_box(anchor, Vector3(0.0, base_y + tower_h + 0.07, 0.0), Vector3(0.36, 0.10, 0.36), v10_materials["v22_civic_gold"] as Material)
    _v10_add_box(anchor, Vector3(0.0, base_y + tower_h * 0.62, 0.158), Vector3(0.16, 0.16, 0.016), v10_materials["v22_civic_glass"] as Material, false)
    if city_level >= 5:
        _v10_add_box(anchor, Vector3(0.0, base_y + tower_h + 0.25, 0.0), Vector3(0.055, 0.34, 0.055), v10_materials["v22_civic_gold"] as Material)
    v22_landmark_node = anchor

func _v22_commercial_roof_height(variant: int) -> float:
    match variant:
        0: return 0.63
        1: return 0.73
        2: return 1.28
        3: return 1.40
        4: return 1.78
        5: return 2.58
        6: return 2.68
        _: return 3.20

# More legible miniature vehicles; prefer arterials so motion reinforces the road hierarchy.
func _v10_rebuild_vehicles() -> void:
    _v10_clear_children(v10_vehicle_root)
    v10_vehicle_nodes.clear()
    var roads: Array = _v22_vehicle_roads()
    var count: int = mini(8, maxi(0, int(roads.size() / 3)))
    for i: int in range(count):
        var car: Node3D = Node3D.new()
        car.name = "V22Car_%d" % i
        v10_vehicle_root.add_child(car)
        var body_mat: Material = [v10_materials["car_light"], v10_materials["car_blue"], v10_materials["car_gold"], v10_materials["car_red"], v10_materials["car_green"]][i % 5] as Material
        _v10_add_box(car, Vector3(0.0, 0.02, 0.0), Vector3(0.34, 0.12, 0.18), body_mat, false)
        _v10_add_box(car, Vector3(0.01, 0.105, 0.0), Vector3(0.18, 0.08, 0.15), v10_materials["v22_vehicle_glass"] as Material, false)
        v10_vehicle_nodes.append(car)
    _v10_update_vehicles()

func _v22_vehicle_roads() -> Array:
    var arterial: Array = []
    for item: Variant in _all_road_cells():
        var p: Vector2i = item as Vector2i
        if int(grid[p.y][p.x]) == Cell.ARTERIAL:
            arterial.append(p)
    return arterial if not arterial.is_empty() else _all_road_cells()

func _v10_update_vehicles() -> void:
    if v10_vehicle_nodes.is_empty():
        return
    var roads: Array = _v22_vehicle_roads()
    if roads.is_empty():
        return
    for i: int in range(v10_vehicle_nodes.size()):
        var car: Node3D = v10_vehicle_nodes[i] as Node3D
        var idx: int = (int(floor(v04_time * 0.72)) + i * 3) % roads.size()
        var p: Vector2i = roads[idx] as Vector2i
        var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
        var phase: float = fmod(v04_time * (0.42 + float(i % 3) * 0.045) + float(i) * 0.19, 1.0) - 0.5
        var world: Vector3 = _v10_world_position(p, 0.18)
        if horizontal:
            world.x += phase * 0.70
            world.z += 0.15 if i % 2 == 0 else -0.15
            car.rotation.y = 0.0
        else:
            world.z += phase * 0.70
            world.x += 0.15 if i % 2 == 0 else -0.15
            car.rotation.y = PI * 0.5
        car.position = world

# --- HUD compaction ---------------------------------------------------------

func _v09_policy_chip_rect() -> Rect2:
    return Rect2(board_rect.end.x - 101.0, board_rect.position.y + 62.0, 92.0, 28.0)

func _v18_service_chip_rect() -> Rect2:
    return Rect2(board_rect.end.x - 101.0, board_rect.position.y + 94.0, 92.0, 28.0)

func _v09_draw_policy_chip() -> void:
    var rect: Rect2 = _v09_policy_chip_rect()
    draw_rect(rect, Color(0.05, 0.14, 0.10, 0.88))
    draw_rect(rect, Color("#4E806A"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(7.0, 10.0), "方針", HORIZONTAL_ALIGNMENT_LEFT, 28.0, 7, Color("#83B19B"))
    draw_string(v11_font, rect.position + Vector2(7.0, 22.0), _v09_policy_name(v09_policy), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14.0, 9, Color("#F3FFF7"))

func _v18_draw_service_chip() -> void:
    var rect: Rect2 = _v18_service_chip_rect()
    var active_count: int = int(v18_mobility) + int(v18_safety) + int(v18_education) + int(v18_green)
    draw_rect(rect, Color(0.05, 0.14, 0.10, 0.88))
    draw_rect(rect, Color("#4E806A"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(7.0, 10.0), "サービス", HORIZONTAL_ALIGNMENT_LEFT, 42.0, 7, Color("#83B19B"))
    draw_string(v11_font, rect.position + Vector2(7.0, 22.0), "%d / %d" % [active_count, ProgressionModel.service_slots(city_level)], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14.0, 9, Color("#F3FFF7"))

func _v15_draw_demand_panel() -> void:
    var rect: Rect2 = Rect2(board_rect.position.x + 8.0, board_rect.position.y + 62.0, 128.0, 34.0)
    draw_rect(rect, Color(0.05, 0.14, 0.10, 0.88))
    draw_rect(rect, Color("#456D5B"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(7.0, 10.0), "需要", HORIZONTAL_ALIGNMENT_LEFT, 30.0, 7, Color("#8FBCA5"))
    draw_string(v11_font, rect.position + Vector2(7.0, 24.0), "住%d  商%d  工%d" % [v15_residential_demand, v15_commercial_demand, v15_industrial_demand], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14.0, 8, Color("#F3FFF7"))
    var values: Array[int] = [v15_residential_demand, v15_commercial_demand, v15_industrial_demand]
    var colors: Array[Color] = [Color("#74C98A"), Color("#65AFD0"), Color("#D2A65C")]
    var bar_w: float = 34.0
    for i: int in range(3):
        var x: float = rect.position.x + 7.0 + float(i) * 39.0
        draw_rect(Rect2(x, rect.end.y - 4.0, bar_w, 2.0), Color("#29463A"))
        draw_rect(Rect2(x, rect.end.y - 4.0, bar_w * clampf(float(values[i]) / 100.0, 0.0, 1.0), 2.0), colors[i])

func _v16_draw_traffic_diagnosis() -> void:
    var compact: bool = v16_traffic_status == "healthy" or v16_traffic_status == "none"
    var rect: Rect2 = Rect2(board_rect.position.x + 8.0, board_rect.position.y + 100.0, 128.0 if compact else 166.0, 28.0 if compact else 43.0)
    var border: Color = Color("#4F8069")
    if v16_traffic_status == "warning": border = Color("#D0A655")
    elif v16_traffic_status == "severe": border = Color("#D86B55")
    draw_rect(rect, Color(0.05, 0.14, 0.10, 0.88))
    draw_rect(rect, border, false, 1.0)
    draw_string(v11_font, rect.position + Vector2(7.0, 11.0), "交通", HORIZONTAL_ALIGNMENT_LEFT, 28.0, 7, Color("#8FBCA5"))
    draw_string(v11_font, rect.position + Vector2(40.0, 11.0), _v16_status_text(), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 47.0, 8, border)
    if compact:
        draw_string(v11_font, rect.position + Vector2(7.0, 23.0), "道路網は安定", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14.0, 7, Color("#B9DDCB"))
    else:
        draw_string(v11_font, rect.position + Vector2(7.0, 25.0), _v16_cause_text(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14.0, 7, Color("#F3FFF7"))
        draw_string(v11_font, rect.position + Vector2(7.0, 38.0), _v16_recovery_text(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14.0, 7, Color("#B9DDCB"))

func _v08_draw_goal_card() -> void:
    var w: float = minf(board_rect.size.x - 36.0, 292.0)
    var h: float = 44.0
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.end.y - h - 8.0, w, h)
    draw_rect(rect, Color(0.05, 0.14, 0.10, 0.90))
    draw_rect(rect, Color("#42705B"), false, 1.0)
    if v08_goal_stage >= V08_GOAL_COUNT:
        draw_string(v11_font, rect.position + Vector2(10.0, 16.0), "街づくり", HORIZONTAL_ALIGNMENT_LEFT, 70.0, 7, Color("#86B89F"))
        draw_string(v11_font, rect.position + Vector2(10.0, 34.0), "都市の基礎完成", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 12, Color("#E9FFF2"))
        return
    var reward: int = int(V08_GOAL_REWARDS[v08_goal_stage])
    var stage_label: String = "最終目標" if v08_goal_stage == V08_GOAL_COUNT - 1 else "目標 %d / %d" % [v08_goal_stage + 1, V08_GOAL_COUNT]
    draw_string(v11_font, rect.position + Vector2(10.0, 13.0), stage_label, HORIZONTAL_ALIGNMENT_LEFT, 100.0, 7, Color("#86B89F"))
    draw_string(v11_font, rect.position + Vector2(rect.size.x - 68.0, 13.0), "+¥%d" % reward, HORIZONTAL_ALIGNMENT_RIGHT, 58.0, 8, Color("#FFE28C"))
    draw_string(v11_font, rect.position + Vector2(10.0, 30.0), _v08_goal_title(v08_goal_stage), HORIZONTAL_ALIGNMENT_LEFT, 160.0, 11, Color("#F4FFF8"))
    draw_string(v11_font, rect.position + Vector2(rect.size.x - 116.0, 30.0), _v08_goal_progress_text(v08_goal_stage), HORIZONTAL_ALIGNMENT_RIGHT, 106.0, 8, Color("#B9DDCB"))
    var bar: Rect2 = Rect2(rect.position.x + 10.0, rect.end.y - 4.0, rect.size.x - 20.0, 2.0)
    draw_rect(bar, Color("#28483A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * _v08_goal_progress(v08_goal_stage), bar.size.y)), Color("#71D0A2"))

func _draw_banner(size: Vector2) -> void:
    var w: float = minf(size.x - MARGIN * 2.0, 300.0)
    var rect: Rect2 = Rect2((size.x - w) * 0.5, board_origin.y + 10.0, w, 36.0)
    draw_rect(rect, Color(0.07, 0.13, 0.10, 0.90))
    draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), Color("#71D0A2"))
    draw_string(v11_font, rect.position + Vector2(8.0, 24.0), _v11_banner_text(banner), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 11, Color.WHITE)
