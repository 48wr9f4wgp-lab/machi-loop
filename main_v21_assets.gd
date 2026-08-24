extends "res://main_v20_ftue.gd"

# MACHI LOOP v0.21 — Production 3D Asset Pass.
# Renderer-only replacement: richer modular silhouettes with tier-aware skyline growth.

const AssetCatalog = preload("res://domain/asset_catalog.gd")

func _v10_create_materials() -> void:
    super._v10_create_materials()

    # Production palette: warm residential, cool commercial, grounded industry.
    v10_materials["v21_stucco_white"] = _v10_material(Color("#F2EEE4"), 0.90)
    v10_materials["v21_stucco_warm"] = _v10_material(Color("#E9DCCB"), 0.92)
    v10_materials["v21_stucco_sage"] = _v10_material(Color("#DCE7D8"), 0.92)
    v10_materials["v21_roof_terracotta"] = _v10_material(Color("#D87355"), 0.86)
    v10_materials["v21_roof_green"] = _v10_material(Color("#6BAA74"), 0.88)
    v10_materials["v21_roof_gold"] = _v10_material(Color("#CC9B58"), 0.88)
    v10_materials["v21_trim_dark"] = _v10_material(Color("#43504B"), 0.86)
    v10_materials["v21_window_dark"] = _v10_material(Color("#527984"), 0.42)
    v10_materials["v21_window_blue"] = _v10_material(Color("#73B6C9"), 0.38)
    v10_materials["v21_glass_light"] = _v10_material(Color("#CFE7EA"), 0.34)
    v10_materials["v21_glass_dark"] = _v10_material(Color("#4D839B"), 0.40)
    v10_materials["v21_commercial_frame"] = _v10_material(Color("#E4E8E2"), 0.72)
    v10_materials["v21_industrial_body"] = _v10_material(Color("#D5B688"), 0.92)
    v10_materials["v21_industrial_dark"] = _v10_material(Color("#9C7750"), 0.94)
    v10_materials["v21_industrial_metal"] = _v10_material(Color("#6D7975"), 0.74)
    v10_materials["v21_awning_red"] = _v10_material(Color("#C95D52"), 0.72)
    v10_materials["v21_awning_blue"] = _v10_material(Color("#4D8EA9"), 0.70)
    v10_materials["v21_awning_gold"] = _v10_material(Color("#D5A84B"), 0.74)
    v10_materials["v21_plaza"] = _v10_material(Color("#D5D8D0"), 0.98)
    v10_materials["v21_hedge"] = _v10_material(Color("#3E744A"), 0.98)
    v10_materials["v21_water"] = _v10_material(Color("#78BCD0"), 0.30)
    v10_materials["v21_fountain_stone"] = _v10_material(Color("#C9CEC6"), 0.94)

func _v10_add_building(p: Vector2i, cell: int) -> void:
    var root: Node3D = Node3D.new()
    root.position = _v10_world_position(p, 0.0)
    root.name = "Building_%d_%d" % [p.x, p.y]
    v10_static_root.add_child(root)
    v10_building_nodes[_key(p)] = root

    var seed: int = abs(p.x * 67 + p.y * 43 + cell * 29)
    _v10_add_box(root, Vector3(0.0, 0.025, 0.0), Vector3(0.88, 0.05, 0.88), v10_materials["sidewalk"] as Material, false)
    _v21_face_road(root, p)

    if cell == Cell.RESIDENTIAL:
        _v21_add_residential(root, seed, AssetCatalog.residential_variant(seed, city_level))
    elif cell == Cell.COMMERCIAL:
        _v21_add_commercial(root, seed, AssetCatalog.commercial_variant(seed, city_level))
    else:
        _v21_add_industrial(root, seed, AssetCatalog.industrial_variant(seed, city_level))

func _v10_rebuild_static_city() -> void:
    super._v10_rebuild_static_city()
    if not is_instance_valid(v10_static_root):
        return
    _v21_add_public_realm_accents()

func _v21_face_road(root: Node3D, p: Vector2i) -> void:
    var dir: Vector2i = _v14_adjacent_road_dir(p)
    if dir == Vector2i(1, 0):
        root.rotation.y = PI * 0.5
    elif dir == Vector2i(-1, 0):
        root.rotation.y = -PI * 0.5
    elif dir == Vector2i(0, -1):
        root.rotation.y = PI
    else:
        root.rotation.y = 0.0

# --- Residential kit -------------------------------------------------------

func _v21_add_residential(root: Node3D, seed: int, variant: int) -> void:
    var wall: Material = [
        v10_materials["v21_stucco_white"],
        v10_materials["v21_stucco_warm"],
        v10_materials["v21_stucco_sage"]
    ][seed % 3] as Material
    var roof: Material = [
        v10_materials["v21_roof_terracotta"],
        v10_materials["v21_roof_green"],
        v10_materials["v21_roof_gold"]
    ][seed % 3] as Material

    match variant:
        0:
            _v21_house_gable(root, wall, roof, 0.66, 0.58, 0.60, seed)
        1:
            _v21_split_house(root, wall, roof, seed)
        2:
            _v21_townhouses(root, wall, roof, seed)
        3:
            _v21_narrow_house(root, wall, roof, seed)
        4:
            _v21_courtyard_house(root, wall, roof, seed)
        5:
            _v21_apartment(root, wall, roof, 1.18, 3, seed)
        6:
            _v21_apartment(root, wall, roof, 1.62, 4, seed)
        _:
            _v21_premium_apartment(root, wall, roof, seed)

func _v21_house_gable(root: Node3D, wall: Material, roof: Material, width: float, depth: float, height: float, seed: int) -> void:
    _v10_add_box(root, Vector3(0.0, 0.08 + height * 0.5, 0.0), Vector3(width, height, depth), wall)
    _v21_add_gable_roof(root, Vector3(0.0, height + 0.12, 0.0), width + 0.08, depth + 0.10, roof)
    _v21_add_front_windows(root, width, height, 2, 0.14, v10_materials["v21_window_dark"] as Material)
    _v21_add_door(root, -0.18 if seed % 2 == 0 else 0.18, 0.08, 0.31)
    if seed % 3 == 0:
        _v10_add_box(root, Vector3(0.20, height + 0.25, -0.10), Vector3(0.10, 0.34, 0.10), v10_materials["v21_trim_dark"] as Material)
    _v21_add_residential_lot(root, seed)

func _v21_split_house(root: Node3D, wall: Material, roof: Material, seed: int) -> void:
    _v10_add_box(root, Vector3(-0.15, 0.36, -0.04), Vector3(0.46, 0.62, 0.60), wall)
    _v21_add_gable_roof(root, Vector3(-0.15, 0.72, -0.04), 0.53, 0.68, roof)
    _v10_add_box(root, Vector3(0.23, 0.27, 0.10), Vector3(0.28, 0.44, 0.42), wall)
    _v21_add_gable_roof(root, Vector3(0.23, 0.53, 0.10), 0.34, 0.49, roof)
    _v21_add_front_windows(root, 0.46, 0.62, 2, 0.14, v10_materials["v21_window_dark"] as Material, -0.15)
    _v21_add_door(root, 0.23, 0.08, 0.32)
    _v21_add_residential_lot(root, seed)

func _v21_townhouses(root: Node3D, wall: Material, roof: Material, seed: int) -> void:
    for i: int in range(3):
        var x: float = -0.28 + float(i) * 0.28
        var local_wall: Material = wall if i != 1 else v10_materials["v21_stucco_warm"] as Material
        _v10_add_box(root, Vector3(x, 0.36, 0.0), Vector3(0.25, 0.62, 0.60), local_wall)
        _v21_add_gable_roof(root, Vector3(x, 0.72, 0.0), 0.29, 0.67, roof)
        _v10_add_box(root, Vector3(x, 0.39, 0.307), Vector3(0.12, 0.13, 0.016), v10_materials["v21_window_dark"] as Material, false)
        _v10_add_box(root, Vector3(x, 0.15, 0.309), Vector3(0.07, 0.20, 0.018), v10_materials["v21_trim_dark"] as Material, false)
    _v21_add_residential_lot(root, seed)

func _v21_narrow_house(root: Node3D, wall: Material, roof: Material, seed: int) -> void:
    _v10_add_box(root, Vector3(0.0, 0.48, -0.02), Vector3(0.48, 0.86, 0.62), wall)
    _v21_add_gable_roof(root, Vector3(0.0, 0.94, -0.02), 0.54, 0.69, roof)
    _v21_add_front_windows(root, 0.48, 0.86, 3, 0.13, v10_materials["v21_window_dark"] as Material)
    _v21_add_door(root, 0.0, 0.08, 0.32)
    _v21_add_residential_lot(root, seed)

func _v21_courtyard_house(root: Node3D, wall: Material, roof: Material, seed: int) -> void:
    _v10_add_box(root, Vector3(-0.18, 0.31, -0.10), Vector3(0.40, 0.52, 0.52), wall)
    _v10_add_box(root, Vector3(0.18, 0.26, 0.14), Vector3(0.30, 0.42, 0.38), wall)
    _v21_add_gable_roof(root, Vector3(-0.18, 0.61, -0.10), 0.46, 0.59, roof)
    _v21_add_gable_roof(root, Vector3(0.18, 0.50, 0.14), 0.35, 0.44, roof)
    _v10_add_box(root, Vector3(0.22, 0.12, -0.25), Vector3(0.24, 0.18, 0.08), v10_materials["v21_hedge"] as Material, false)
    _v21_add_door(root, 0.18, 0.08, 0.34)
    _v21_add_residential_lot(root, seed)

func _v21_apartment(root: Node3D, wall: Material, roof: Material, height: float, floors: int, seed: int) -> void:
    var width: float = 0.70
    var depth: float = 0.68
    _v10_add_box(root, Vector3(0.0, 0.06 + height * 0.5, 0.0), Vector3(width, height, depth), wall)
    _v10_add_box(root, Vector3(0.0, height + 0.10, 0.0), Vector3(width + 0.06, 0.12, depth + 0.06), roof)
    _v21_add_front_windows(root, width, height, floors, 0.11, v10_materials["v21_window_blue"] as Material)
    for floor: int in range(1, floors):
        if floor % 2 == seed % 2:
            var y: float = 0.20 + float(floor) * (height / float(floors))
            _v10_add_box(root, Vector3(0.0, y, 0.37), Vector3(0.48, 0.04, 0.10), v10_materials["v21_trim_dark"] as Material, false)
    _v21_add_door(root, 0.0, 0.08, 0.35)
    _v21_add_residential_lot(root, seed)

func _v21_premium_apartment(root: Node3D, wall: Material, roof: Material, seed: int) -> void:
    _v10_add_box(root, Vector3(-0.10, 0.83, 0.0), Vector3(0.58, 1.55, 0.66), wall)
    _v10_add_box(root, Vector3(0.22, 0.52, 0.03), Vector3(0.24, 0.92, 0.54), v10_materials["v21_stucco_sage"] as Material)
    _v10_add_box(root, Vector3(-0.10, 1.64, 0.0), Vector3(0.64, 0.14, 0.72), roof)
    _v21_add_front_windows(root, 0.58, 1.55, 5, 0.10, v10_materials["v21_window_blue"] as Material, -0.10)
    _v10_add_box(root, Vector3(0.21, 1.05, 0.31), Vector3(0.18, 0.38, 0.018), v10_materials["v21_window_dark"] as Material, false)
    _v21_add_residential_lot(root, seed)

func _v21_add_residential_lot(root: Node3D, seed: int) -> void:
    var side: float = -0.37 if seed % 2 == 0 else 0.37
    _v10_add_box(root, Vector3(side, 0.11, 0.18), Vector3(0.09, 0.17, 0.40), v10_materials["v21_hedge"] as Material, false)
    if seed % 3 != 0:
        _v10_add_box(root, Vector3(-side, 0.053, 0.30), Vector3(0.20, 0.025, 0.30), v10_materials["parking"] as Material, false)

# --- Commercial kit --------------------------------------------------------

func _v21_add_commercial(root: Node3D, seed: int, variant: int) -> void:
    match variant:
        0:
            _v21_retail_block(root, seed, 0.46)
        1:
            _v21_corner_shop(root, seed)
        2:
            _v21_office_slab(root, seed, 1.12, 3)
        3:
            _v21_stepped_office(root, seed)
        4:
            _v21_office_slab(root, seed, 1.62, 4)
        5:
            _v21_glass_tower(root, seed, 2.10, 5)
        6:
            _v21_podium_tower(root, seed)
        _:
            _v21_crown_tower(root, seed)
    _v21_add_commercial_frontage(root, seed)

func _v21_retail_block(root: Node3D, seed: int, height: float) -> void:
    var body: Material = v10_materials["v21_stucco_white"] as Material
    var awning: Material = _v21_awning_material(seed)
    _v10_add_box(root, Vector3(0.0, 0.08 + height * 0.5, -0.03), Vector3(0.76, height, 0.66), body)
    _v10_add_box(root, Vector3(0.0, height + 0.11, -0.03), Vector3(0.80, 0.12, 0.70), v10_materials["v21_trim_dark"] as Material)
    _v10_add_box(root, Vector3(0.0, 0.31, 0.312), Vector3(0.56, 0.20, 0.018), v10_materials["v21_glass_light"] as Material, false)
    _v10_add_box(root, Vector3(0.0, 0.43, 0.34), Vector3(0.58, 0.07, 0.10), awning, false)

func _v21_corner_shop(root: Node3D, seed: int) -> void:
    var body: Material = v10_materials["v21_stucco_warm"] as Material
    _v10_add_box(root, Vector3(-0.12, 0.34, 0.0), Vector3(0.52, 0.58, 0.66), body)
    _v10_add_box(root, Vector3(0.24, 0.25, 0.12), Vector3(0.24, 0.40, 0.42), v10_materials["v21_commercial_frame"] as Material)
    _v10_add_box(root, Vector3(-0.12, 0.66, 0.0), Vector3(0.58, 0.12, 0.72), _v21_awning_material(seed))
    _v10_add_box(root, Vector3(-0.12, 0.33, 0.338), Vector3(0.38, 0.18, 0.018), v10_materials["v21_glass_light"] as Material, false)

func _v21_office_slab(root: Node3D, seed: int, height: float, floors: int) -> void:
    var frame: Material = v10_materials["v21_commercial_frame"] as Material
    var glass: Material = v10_materials["v21_window_blue"] as Material if seed % 2 == 0 else v10_materials["v21_glass_light"] as Material
    _v10_add_box(root, Vector3(0.0, 0.07 + height * 0.5, 0.0), Vector3(0.70, height, 0.66), frame)
    _v21_add_front_windows(root, 0.70, height, floors, 0.10, glass)
    _v21_add_side_glass(root, height, floors, glass)
    _v10_add_box(root, Vector3(0.0, height + 0.10, 0.0), Vector3(0.74, 0.12, 0.70), v10_materials["v21_glass_dark"] as Material)

func _v21_stepped_office(root: Node3D, seed: int) -> void:
    var frame: Material = v10_materials["v21_commercial_frame"] as Material
    _v10_add_box(root, Vector3(-0.12, 0.66, 0.0), Vector3(0.48, 1.20, 0.68), frame)
    _v10_add_box(root, Vector3(0.22, 0.45, 0.04), Vector3(0.24, 0.78, 0.56), v10_materials["v21_glass_dark"] as Material)
    _v21_add_front_windows(root, 0.48, 1.20, 4, 0.09, v10_materials["v21_window_blue"] as Material, -0.12)
    _v10_add_box(root, Vector3(-0.12, 1.32, 0.0), Vector3(0.54, 0.12, 0.74), _v21_awning_material(seed))

func _v21_glass_tower(root: Node3D, seed: int, height: float, floors: int) -> void:
    var glass: Material = v10_materials["v21_window_blue"] as Material if seed % 2 == 0 else v10_materials["v21_glass_light"] as Material
    _v10_add_box(root, Vector3(0.0, 0.30, 0.0), Vector3(0.78, 0.50, 0.72), v10_materials["v21_commercial_frame"] as Material)
    _v10_add_box(root, Vector3(0.0, 0.35 + height * 0.5, 0.0), Vector3(0.52, height, 0.52), v10_materials["v21_glass_dark"] as Material)
    _v21_add_front_windows(root, 0.52, height, floors, 0.08, glass, 0.0, 0.35)
    _v21_add_side_glass(root, height, floors, glass, 0.35)
    _v10_add_box(root, Vector3(0.0, height + 0.40, 0.0), Vector3(0.58, 0.10, 0.58), v10_materials["v21_trim_dark"] as Material)

func _v21_podium_tower(root: Node3D, seed: int) -> void:
    _v10_add_box(root, Vector3(0.0, 0.30, 0.0), Vector3(0.82, 0.50, 0.74), v10_materials["v21_commercial_frame"] as Material)
    _v10_add_box(root, Vector3(-0.10, 1.44, 0.0), Vector3(0.48, 2.18, 0.52), v10_materials["v21_glass_dark"] as Material)
    _v10_add_box(root, Vector3(0.23, 0.94, 0.02), Vector3(0.20, 1.18, 0.42), v10_materials["v21_window_blue"] as Material)
    _v21_add_front_windows(root, 0.48, 2.18, 6, 0.07, v10_materials["v21_glass_light"] as Material, -0.10, 0.35)
    _v10_add_box(root, Vector3(-0.10, 2.58, 0.0), Vector3(0.54, 0.12, 0.58), _v21_awning_material(seed))

func _v21_crown_tower(root: Node3D, seed: int) -> void:
    var glass: Material = v10_materials["v21_window_blue"] as Material
    _v10_add_box(root, Vector3(0.0, 0.28, 0.0), Vector3(0.82, 0.46, 0.76), v10_materials["v21_commercial_frame"] as Material)
    _v10_add_box(root, Vector3(0.0, 1.55, 0.0), Vector3(0.50, 2.42, 0.50), v10_materials["v21_glass_dark"] as Material)
    _v21_add_front_windows(root, 0.50, 2.42, 7, 0.065, glass, 0.0, 0.34)
    _v21_add_side_glass(root, 2.42, 7, v10_materials["v21_glass_light"] as Material, 0.34)
    _v10_add_box(root, Vector3(0.0, 2.82, 0.0), Vector3(0.36, 0.18, 0.36), _v21_awning_material(seed))
    _v10_add_box(root, Vector3(0.0, 3.02, 0.0), Vector3(0.08, 0.32, 0.08), v10_materials["v21_trim_dark"] as Material)

func _v21_add_commercial_frontage(root: Node3D, seed: int) -> void:
    _v10_add_box(root, Vector3(0.0, 0.052, 0.35), Vector3(0.56, 0.026, 0.20), v10_materials["v21_plaza"] as Material, false)
    if seed % 2 == 0:
        _v14_add_parked_car(root, Vector3(0.22, 0.12, 0.35), Vector2i(0, 1), seed)

# --- Industrial kit --------------------------------------------------------

func _v21_add_industrial(root: Node3D, seed: int, variant: int) -> void:
    var body: Material = v10_materials["v21_industrial_body"] as Material
    var dark: Material = v10_materials["v21_industrial_dark"] as Material
    match variant:
        0:
            _v21_warehouse(root, body, dark, seed)
        1:
            _v21_utility_hall(root, body, dark, seed)
        2:
            _v21_processing_plant(root, body, dark, seed, false)
        3:
            _v21_logistics_shed(root, body, dark, seed)
        4:
            _v21_processing_plant(root, body, dark, seed, true)
        _:
            _v21_tank_plant(root, body, dark, seed)

func _v21_warehouse(root: Node3D, body: Material, dark: Material, seed: int) -> void:
    _v10_add_box(root, Vector3(0.0, 0.34, -0.03), Vector3(0.82, 0.58, 0.68), body)
    _v21_add_gable_roof(root, Vector3(0.0, 0.68, -0.03), 0.88, 0.74, dark, 0.24)
    _v10_add_box(root, Vector3(0.0, 0.29, 0.318), Vector3(0.40, 0.30, 0.018), v10_materials["v21_industrial_metal"] as Material, false)
    _v21_industrial_yard(root, seed)

func _v21_utility_hall(root: Node3D, body: Material, dark: Material, seed: int) -> void:
    _v10_add_box(root, Vector3(-0.10, 0.38, 0.0), Vector3(0.62, 0.66, 0.70), body)
    _v10_add_box(root, Vector3(-0.10, 0.75, 0.0), Vector3(0.68, 0.12, 0.76), dark)
    _v14_add_cylinder(root, Vector3(0.28, 0.63, -0.20), 0.11, 0.92, v10_materials["v21_industrial_metal"] as Material)
    _v21_industrial_yard(root, seed)

func _v21_processing_plant(root: Node3D, body: Material, dark: Material, seed: int, twin: bool) -> void:
    _v10_add_box(root, Vector3(-0.08, 0.36, 0.02), Vector3(0.66, 0.60, 0.62), body)
    _v10_add_box(root, Vector3(-0.08, 0.70, 0.02), Vector3(0.72, 0.12, 0.68), dark)
    var stack_count: int = 2 if twin else 1
    for i: int in range(stack_count):
        var x: float = 0.22 - float(i) * 0.24
        _v14_add_cylinder(root, Vector3(x, 0.90, -0.18), 0.07, 1.02, v10_materials["v21_industrial_dark"] as Material)
    _v21_industrial_yard(root, seed)

func _v21_logistics_shed(root: Node3D, body: Material, dark: Material, seed: int) -> void:
    _v10_add_box(root, Vector3(0.0, 0.28, -0.08), Vector3(0.84, 0.46, 0.52), body)
    _v21_add_gable_roof(root, Vector3(0.0, 0.55, -0.08), 0.90, 0.58, dark, 0.20)
    for i: int in range(3):
        _v10_add_box(root, Vector3(-0.25 + float(i) * 0.25, 0.22, 0.19), Vector3(0.16, 0.22, 0.018), v10_materials["v21_industrial_metal"] as Material, false)
    _v21_industrial_yard(root, seed)

func _v21_tank_plant(root: Node3D, body: Material, dark: Material, seed: int) -> void:
    _v10_add_box(root, Vector3(-0.18, 0.34, -0.08), Vector3(0.48, 0.58, 0.54), body)
    _v10_add_box(root, Vector3(-0.18, 0.67, -0.08), Vector3(0.54, 0.12, 0.60), dark)
    _v14_add_cylinder(root, Vector3(0.24, 0.31, 0.15), 0.16, 0.48, v10_materials["v21_industrial_metal"] as Material)
    _v14_add_cylinder(root, Vector3(0.24, 0.31, -0.20), 0.14, 0.48, v10_materials["v21_industrial_metal"] as Material)
    _v21_industrial_yard(root, seed)

func _v21_industrial_yard(root: Node3D, seed: int) -> void:
    _v10_add_box(root, Vector3(0.0, 0.052, 0.34), Vector3(0.72, 0.026, 0.22), v10_materials["parking"] as Material, false)
    var mat: Material = v10_materials["container_blue"] as Material if seed % 2 == 0 else v10_materials["container_red"] as Material
    _v10_add_box(root, Vector3(0.26, 0.14, 0.30), Vector3(0.24, 0.17, 0.16), mat)

# --- Shared modular parts --------------------------------------------------

func _v21_add_gable_roof(parent: Node, center: Vector3, width: float, depth: float, material: Material, slope: float = 0.30) -> void:
    var panel_w: float = width * 0.55
    var left: MeshInstance3D = _v10_add_box(parent, center + Vector3(-width * 0.23, 0.0, 0.0), Vector3(panel_w, 0.075, depth), material)
    left.rotation.z = slope
    var right: MeshInstance3D = _v10_add_box(parent, center + Vector3(width * 0.23, 0.0, 0.0), Vector3(panel_w, 0.075, depth), material)
    right.rotation.z = -slope

func _v21_add_front_windows(parent: Node, width: float, height: float, floors: int, band_h: float, material: Material, x_offset: float = 0.0, y_offset: float = 0.08) -> void:
    var floor_h: float = height / float(maxi(1, floors))
    for floor: int in range(floors):
        var y: float = y_offset + floor_h * (float(floor) + 0.58)
        _v10_add_box(parent, Vector3(x_offset, y, 0.345), Vector3(width * 0.68, band_h, 0.018), material, false)

func _v21_add_side_glass(parent: Node, height: float, floors: int, material: Material, y_offset: float = 0.08) -> void:
    var floor_h: float = height / float(maxi(1, floors))
    for floor: int in range(floors):
        var y: float = y_offset + floor_h * (float(floor) + 0.58)
        _v10_add_box(parent, Vector3(0.265, y, 0.0), Vector3(0.018, 0.075, 0.34), material, false)

func _v21_add_door(parent: Node, x: float, y: float, z: float) -> void:
    _v10_add_box(parent, Vector3(x, y + 0.10, z), Vector3(0.09, 0.20, 0.018), v10_materials["v21_trim_dark"] as Material, false)

func _v21_awning_material(seed: int) -> Material:
    match seed % 3:
        0:
            return v10_materials["v21_awning_red"] as Material
        1:
            return v10_materials["v21_awning_blue"] as Material
        _:
            return v10_materials["v21_awning_gold"] as Material

func _v21_add_public_realm_accents() -> void:
    var fountain_count: int = 0
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if fountain_count >= 3:
                return
            if int(grid[y][x]) != Cell.EMPTY:
                continue
            var marker: int = abs(x * 71 + y * 97 + x * y * 13)
            if marker % 127 != 0:
                continue
            var p: Vector2i = Vector2i(x, y)
            var pos: Vector3 = _v10_world_position(p, 0.0)
            _v10_add_box(v10_static_root, pos + Vector3(0.0, 0.025, 0.0), Vector3(0.72, 0.04, 0.72), v10_materials["park"] as Material, false)
            _v14_add_cylinder(v10_static_root, pos + Vector3(0.0, 0.07, 0.0), 0.23, 0.10, v10_materials["v21_fountain_stone"] as Material)
            _v14_add_cylinder(v10_static_root, pos + Vector3(0.0, 0.13, 0.0), 0.17, 0.04, v10_materials["v21_water"] as Material)
            fountain_count += 1
