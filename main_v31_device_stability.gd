extends "res://main_v30_fresh_test_mode.gd"

# AXIVA v0.31 — physical-iPhone frame stability pass.
# Device evidence showed repeated whole-city visual "twitch" while the simulation
# was growing. The causes addressed here are presentation-only:
# 1) congestion-only changes no longer rebuild static geometry;
# 2) structural rebuilds are double-buffered so the old city stays visible until
#    the replacement tree is complete;
# 3) vehicle nodes are reconciled instead of destroyed/recreated on every sync;
# 4) the FTUE camera snaps exactly to rest once its eased motion is effectively
#    complete, preventing long-tail sub-pixel drift.
#
# Simulation, save schema, economy, traffic authority and player actions are
# unchanged.

const V31_CAMERA_POSITION_EPS: float = 0.025
const V31_CAMERA_SIZE_EPS: float = 0.025

var v31_static_swap_count: int = 0
var v31_vehicle_reconcile_count: int = 0
var v31_camera_snap_count: int = 0

# Static city geometry depends on topology / parcel state / widening / progression,
# not on the current congestion percentage. Congestion remains visible through
# vehicle speed and the v0.29 world-space hotspot/recovery presentation.
func _v10_scene_hash() -> int:
    var signature: String = (
        JSON.stringify(grid)
        + "|" + JSON.stringify(widened)
        + "|" + str(unlocked_cols)
        + "|" + str(city_level)
        + "|" + str(v09_policy)
    )
    return signature.hash()

# Rebuilding the production city can create many nodes. Previously the live root
# was cleared first, so a simulation tick could expose a transient empty/partial
# city and read as a full-screen twitch. Build into a replacement root, then swap.
func _v10_rebuild_static_city() -> void:
    if not is_instance_valid(v10_world_root) or not is_instance_valid(v10_static_root):
        super._v10_rebuild_static_city()
        return

    # Initial renderer construction has no visible city to preserve.
    if v10_static_root.get_child_count() == 0:
        super._v10_rebuild_static_city()
        return

    var old_root: Node3D = v10_static_root
    var replacement: Node3D = Node3D.new()
    replacement.name = "StaticCityNext"
    v10_world_root.add_child(replacement)
    v10_static_root = replacement

    # The inherited renderer writes all road/building/public-realm content into
    # v10_static_root, which now points at the hidden replacement tree.
    replacement.visible = false
    super._v10_rebuild_static_city()

    # One atomic presentation swap after the replacement is complete.
    replacement.visible = true
    replacement.name = "StaticCity"
    old_root.visible = false
    old_root.queue_free()
    v31_static_swap_count += 1

# v0.26 rebuilt every vehicle node whenever static city state changed, even when
# only a building had grown. Preserve existing nodes and only add/remove the
# delta required by the current target count.
func _v10_rebuild_vehicles() -> void:
    if not is_instance_valid(v10_vehicle_root):
        return

    var roads: Array = _v22_vehicle_roads()
    var target: int = 0
    if not roads.is_empty():
        var activity: int = int(population / 52) + int(jobs / 70)
        var pressure: int = int(clampf(congestion / 38.0, 0.0, 4.0))
        target = clampi(2 + int(roads.size() / 3) + activity + pressure, 2, 16)

    while v10_vehicle_nodes.size() > target:
        var node: Node3D = v10_vehicle_nodes.pop_back() as Node3D
        if is_instance_valid(node):
            node.queue_free()

    while v10_vehicle_nodes.size() < target:
        var index: int = v10_vehicle_nodes.size()
        v10_vehicle_nodes.append(_v31_create_vehicle(index))

    v26_vehicle_target_count = target
    v31_vehicle_reconcile_count += 1
    _v10_update_vehicles()

func _v31_create_vehicle(index: int) -> Node3D:
    var car: Node3D = Node3D.new()
    car.name = "V31Car_%d" % index
    v10_vehicle_root.add_child(car)

    var body_keys: Array[String] = [
        "car_light",
        "car_blue",
        "car_gold",
        "v26_car_red",
        "v26_car_green"
    ]
    var body: Material = v10_materials[body_keys[index % body_keys.size()]] as Material
    _v10_add_box(car, Vector3(0.0, 0.025, 0.0), Vector3(0.31, 0.11, 0.16), body, false)
    _v10_add_box(car, Vector3(0.015, 0.105, 0.0), Vector3(0.17, 0.075, 0.135), v10_materials["v22_vehicle_glass"] as Material, false)
    _v10_add_box(car, Vector3(-0.09, -0.035, 0.075), Vector3(0.06, 0.055, 0.025), v10_materials["v26_wheel"] as Material, false)
    _v10_add_box(car, Vector3(0.09, -0.035, -0.075), Vector3(0.06, 0.055, 0.025), v10_materials["v26_wheel"] as Material, false)
    return car

func _v28_update_camera(delta: float) -> void:
    super._v28_update_camera(delta)
    _v31_snap_camera_if_settled()

func _v31_snap_camera_if_settled() -> bool:
    if v28_sequence_active or not is_instance_valid(v10_camera):
        return false

    var target: Vector3 = _v28_base_camera_target()
    var target_size: float = _v28_base_camera_size()
    if v28_camera_target.distance_to(target) > V31_CAMERA_POSITION_EPS:
        return false
    if absf(v28_camera_size - target_size) > V31_CAMERA_SIZE_EPS:
        return false

    var already_exact: bool = (
        v28_camera_target.is_equal_approx(target)
        and is_equal_approx(v28_camera_size, target_size)
    )
    v28_camera_target = target
    v28_camera_size = target_size
    v10_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    v10_camera.size = target_size
    v10_camera.position = target + Vector3(14.0, 19.0, 16.0)
    v10_camera.look_at(target, Vector3.UP)
    if not already_exact:
        v31_camera_snap_count += 1
    return true
