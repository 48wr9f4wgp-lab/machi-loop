extends "res://main_v25_city_density.gd"

# MACHI LOOP v0.26 — Urban hierarchy / motion pass.
# Visual North Star implementation: let road structure visibly create a center,
# make arterials greener and more authored, and make traffic density / speed
# communicate congestion without adding dashboard UI. Simulation and save state
# remain authoritative in inherited layers.

var v26_core_tower_count: int = 0
var v26_street_tree_count: int = 0
var v26_vehicle_target_count: int = 0
var v26_vehicle_flow_multiplier: float = 1.0

func _v10_create_materials() -> void:
    super._v10_create_materials()
    v10_materials["v26_core_stone"] = _v10_material(Color("#E7E1D5"), 0.88)
    v10_materials["v26_core_warm"] = _v10_material(Color("#D8BFA8"), 0.90)
    v10_materials["v26_core_glass"] = _v10_material(Color("#73AFC0"), 0.38)
    v10_materials["v26_core_roof"] = _v10_material(Color("#7D6254"), 0.84)
    v10_materials["v26_tree_leaf"] = _v10_material(Color("#4F854D"), 0.98)
    v10_materials["v26_tree_leaf_light"] = _v10_material(Color("#75A761"), 0.98)
    v10_materials["v26_tree_trunk"] = _v10_material(Color("#786146"), 1.0)
    v10_materials["v26_car_red"] = _v10_material(Color("#B85E52"), 0.48)
    v10_materials["v26_car_green"] = _v10_material(Color("#638B72"), 0.48)
    v10_materials["v26_wheel"] = _v10_material(Color("#303634"), 0.96)

func _v10_rebuild_static_city() -> void:
    v26_core_tower_count = 0
    v26_street_tree_count = 0
    super._v10_rebuild_static_city()

# Urban hierarchy is derived from player-authored road structure. Commercial
# parcels close to a meaningful arterial junction receive a taller visual crown,
# making the road network visibly shape where the center emerges.
func _v10_add_building(p: Vector2i, cell: int) -> void:
    super._v10_add_building(p, cell)
    if cell != Cell.COMMERCIAL or city_level < 3:
        return
    if not _v26_is_core_parcel(p):
        return
    var k: String = _key(p)
    if not v10_building_nodes.has(k):
        return
    var root: Node3D = v10_building_nodes[k] as Node3D
    if root == null:
        return
    _v26_add_core_crown(root, p)

func _v26_is_core_parcel(p: Vector2i) -> bool:
    for dy: int in range(-2, 3):
        for dx: int in range(-2, 3):
            if abs(dx) + abs(dy) > 2:
                continue
            var q: Vector2i = p + Vector2i(dx, dy)
            if not _in_bounds(q) or q.x >= unlocked_cols:
                continue
            if int(grid[q.y][q.x]) != Cell.ARTERIAL:
                continue
            if _v26_road_degree(q) >= 3:
                return true
    return false

func _v26_road_degree(p: Vector2i) -> int:
    var degree: int = 0
    for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        if _v04_is_road(p + d):
            degree += 1
    return degree

func _v26_add_core_crown(root: Node3D, p: Vector2i) -> void:
    var seed: int = abs(p.x * 89 + p.y * 131 + city_level * 17)
    var height: float = 1.25 + float(clampi(city_level - 3, 0, 3)) * 0.28 + float(seed % 3) * 0.12
    var body: Material = v10_materials["v26_core_stone"] as Material if seed % 2 == 0 else v10_materials["v26_core_warm"] as Material
    var x: float = -0.12 if seed % 2 == 0 else 0.12
    _v10_add_box(root, Vector3(x, height * 0.5 + 0.34, -0.05), Vector3(0.42, height, 0.46), body)
    _v10_add_box(root, Vector3(x, height + 0.39, -0.05), Vector3(0.48, 0.10, 0.52), v10_materials["v26_core_roof"] as Material)

    var floors: int = clampi(int(height / 0.24), 4, 8)
    for floor_index: int in range(floors):
        var y: float = 0.53 + float(floor_index) * (height / float(floors))
        _v10_add_box(root, Vector3(x, y, 0.185), Vector3(0.27, 0.085, 0.016), v10_materials["v26_core_glass"] as Material, false)

    if seed % 3 == 0:
        _v10_add_box(root, Vector3(-x * 1.35, 0.67, -0.11), Vector3(0.25, 0.66, 0.30), body)
        _v10_add_box(root, Vector3(-x * 1.35, 1.02, -0.11), Vector3(0.29, 0.07, 0.34), v10_materials["v26_core_roof"] as Material)
    v26_core_tower_count += 1

# Selected straight arterial segments receive small street trees outside the
# carriageway. This visually reinforces the player's road as a civic spine while
# keeping junctions clear and preserving every simulation cell.
func _v10_add_road(p: Vector2i, cell: int) -> void:
    super._v10_add_road(p, cell)
    if cell != Cell.ARTERIAL or v26_street_tree_count >= 20:
        return
    var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
    var vertical: bool = _v04_is_road(p + Vector2i(0, 1)) or _v04_is_road(p + Vector2i(0, -1))
    if horizontal == vertical:
        return
    var marker: int = abs(p.x * 37 + p.y * 59)
    if marker % 3 != 0:
        return
    _v26_add_street_tree_pair(p, horizontal, marker)

func _v26_add_street_tree_pair(p: Vector2i, horizontal: bool, seed: int) -> void:
    var world: Vector3 = _v10_world_position(p, 0.0)
    var leaf: Material = v10_materials["v26_tree_leaf"] as Material if seed % 2 == 0 else v10_materials["v26_tree_leaf_light"] as Material
    var offsets: Array[Vector3]
    if horizontal:
        offsets = [Vector3(-0.22, 0.0, 0.60), Vector3(0.22, 0.0, -0.60)]
    else:
        offsets = [Vector3(0.60, 0.0, -0.22), Vector3(-0.60, 0.0, 0.22)]

    for off: Vector3 in offsets:
        _v14_add_cylinder(v10_static_root, world + off + Vector3(0.0, 0.18, 0.0), 0.024, 0.32, v10_materials["v26_tree_trunk"] as Material)
        _v10_add_box(v10_static_root, world + off + Vector3(0.0, 0.43, 0.0), Vector3(0.22, 0.24, 0.22), leaf, false)
    v26_street_tree_count += 2

# Traffic becomes a visual diagnostic. Vehicle count rises with city activity
# and congestion, while motion visibly slows under pressure. No traffic model
# values are changed here; this only presents the inherited state.
func _v10_rebuild_vehicles() -> void:
    _v10_clear_children(v10_vehicle_root)
    v10_vehicle_nodes.clear()
    var roads: Array = _v22_vehicle_roads()
    if roads.is_empty():
        v26_vehicle_target_count = 0
        return

    var activity: int = int(population / 52) + int(jobs / 70)
    var pressure: int = int(clampf(congestion / 38.0, 0.0, 4.0))
    v26_vehicle_target_count = clampi(2 + int(roads.size() / 3) + activity + pressure, 2, 16)

    var body_keys: Array[String] = ["car_light", "car_blue", "car_gold", "v26_car_red", "v26_car_green"]
    for i: int in range(v26_vehicle_target_count):
        var car: Node3D = Node3D.new()
        car.name = "V26Car_%d" % i
        v10_vehicle_root.add_child(car)
        var body: Material = v10_materials[body_keys[i % body_keys.size()]] as Material
        _v10_add_box(car, Vector3(0.0, 0.025, 0.0), Vector3(0.31, 0.11, 0.16), body, false)
        _v10_add_box(car, Vector3(0.015, 0.105, 0.0), Vector3(0.17, 0.075, 0.135), v10_materials["v22_vehicle_glass"] as Material, false)
        _v10_add_box(car, Vector3(-0.09, -0.035, 0.075), Vector3(0.06, 0.055, 0.025), v10_materials["v26_wheel"] as Material, false)
        _v10_add_box(car, Vector3(0.09, -0.035, -0.075), Vector3(0.06, 0.055, 0.025), v10_materials["v26_wheel"] as Material, false)
        v10_vehicle_nodes.append(car)
    _v10_update_vehicles()

func _v10_update_vehicles() -> void:
    if v10_vehicle_nodes.is_empty():
        return
    var roads: Array = _v22_vehicle_roads()
    if roads.is_empty():
        return

    var pressure: float = clampf(congestion / 140.0, 0.0, 1.0)
    v26_vehicle_flow_multiplier = lerpf(1.0, 0.28, pressure)
    var route_speed: float = 0.72 * v26_vehicle_flow_multiplier
    var local_speed: float = 0.42 * v26_vehicle_flow_multiplier

    for i: int in range(v10_vehicle_nodes.size()):
        var car: Node3D = v10_vehicle_nodes[i] as Node3D
        if car == null:
            continue
        var idx: int = (int(floor(v04_time * route_speed)) + i * 3) % roads.size()
        var p: Vector2i = roads[idx] as Vector2i
        var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
        var phase: float = fmod(v04_time * (local_speed + float(i % 3) * 0.022) + float(i) * 0.19, 1.0) - 0.5
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
