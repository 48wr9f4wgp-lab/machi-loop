extends "res://main_v36_expansion_camera.gd"

# AXIVA v0.36.1 — synchronized land reveal.
# v0.36 smoothed the camera, but physical iPhone still showed a one-frame "gak"
# because the static city widened instantly before the 0.72 s camera reveal.
#
# This layer keeps the authoritative unlock immediate, but defers the static-city
# rebuild for the reveal window and morphs only the existing ground / locked land
# / boundary meshes in place. At the end, one final static sync lands on geometry
# that already matches the final framing.
#
# No simulation, economy, traffic, save or map authority changes.

var v361_land_reveal_active: bool = false
var v361_from_cols: int = -1
var v361_to_cols: int = -1
var v361_open_ground: MeshInstance3D
var v361_locked_ground: MeshInstance3D
var v361_boundary: MeshInstance3D
var v361_reveal_started_count: int = 0
var v361_reveal_completed_count: int = 0

func _check_unlocks() -> void:
    var before_cols: int = unlocked_cols
    super._check_unlocks()
    if unlocked_cols <= before_cols:
        return
    _v361_begin_land_reveal(before_cols, unlocked_cols)

# v0.32 normally performs a full static rebuild when unlocked_cols changes.
# During the <1 s reveal, keep the existing static city alive and morph its land
# boundary instead. A forced sync is still allowed for explicit callers.
func _v10_sync_scene(force: bool = false) -> void:
    if v361_land_reveal_active and not force:
        _v10_rebuild_vehicles()
        _v10_sync_preview()
        queue_redraw()
        return
    super._v10_sync_scene(force)

func _process(delta: float) -> void:
    super._process(delta)
    if not v361_land_reveal_active:
        return

    var t: float = _v36_expansion_progress(v36_expansion_elapsed)
    _v361_apply_presented_cols(lerpf(float(v361_from_cols), float(v361_to_cols), t))

    if v36_expansion_camera_active:
        return

    # Camera reveal has reached the exact final target. Match the land geometry
    # first, then perform one authoritative static sync. The swap should now be
    # visually equivalent instead of a full-frame jump.
    _v361_apply_presented_cols(float(v361_to_cols))
    v361_land_reveal_active = false
    _v10_sync_scene(true)
    v361_reveal_completed_count += 1
    queue_redraw()

func _v361_begin_land_reveal(from_cols: int, to_cols: int) -> void:
    if to_cols <= from_cols:
        return
    if not is_instance_valid(v10_static_root):
        return

    v361_from_cols = from_cols
    v361_to_cols = to_cols
    _v361_capture_land_meshes()
    if not is_instance_valid(v361_open_ground):
        return

    v361_land_reveal_active = true
    v361_reveal_started_count += 1
    _v361_apply_presented_cols(float(from_cols))

func _v361_capture_land_meshes() -> void:
    v361_open_ground = null
    v361_locked_ground = null
    v361_boundary = null

    var open_material: Material = v10_materials.get("v22_ground") as Material
    var locked_material: Material = v10_materials.get("locked") as Material
    var boundary_material: Material = v10_materials.get("boundary") as Material

    for child: Node in v10_static_root.get_children():
        if not child is MeshInstance3D:
            continue
        var mesh_instance: MeshInstance3D = child as MeshInstance3D
        if mesh_instance.material_override == open_material and not is_instance_valid(v361_open_ground):
            v361_open_ground = mesh_instance
        elif mesh_instance.material_override == locked_material and not is_instance_valid(v361_locked_ground):
            v361_locked_ground = mesh_instance
        elif mesh_instance.material_override == boundary_material and not is_instance_valid(v361_boundary):
            v361_boundary = mesh_instance

func _v361_apply_presented_cols(cols: float) -> void:
    var geometry: Dictionary = _v361_land_geometry(cols)

    if is_instance_valid(v361_open_ground):
        _v361_set_box_x(
            v361_open_ground,
            float(geometry["open_center_x"]),
            maxf(0.01, float(geometry["open_width"]))
        )

    if is_instance_valid(v361_locked_ground):
        var locked_width: float = float(geometry["locked_width"])
        v361_locked_ground.visible = locked_width > 0.01
        if v361_locked_ground.visible:
            _v361_set_box_x(
                v361_locked_ground,
                float(geometry["locked_center_x"]),
                maxf(0.01, locked_width)
            )

    if is_instance_valid(v361_boundary):
        var has_locked_land: bool = float(geometry["locked_width"]) > 0.01
        v361_boundary.visible = has_locked_land
        if has_locked_land:
            v361_boundary.position.x = float(geometry["boundary_x"])

func _v361_set_box_x(instance: MeshInstance3D, center_x: float, width: float) -> void:
    var box: BoxMesh = instance.mesh as BoxMesh
    if box == null:
        return
    var size: Vector3 = box.size
    size.x = width
    box.size = size
    instance.position.x = center_x

func _v361_land_geometry(cols: float) -> Dictionary:
    var presented: float = clampf(cols, 0.0, float(GRID_W))
    var open_width: float = presented
    var locked_width: float = maxf(0.0, float(GRID_W) - presented)
    var open_center_x: float = -float(GRID_W) * 0.5 + open_width * 0.5
    var locked_center_x: float = -float(GRID_W) * 0.5 + presented + locked_width * 0.5
    var boundary_x: float = -float(GRID_W) * 0.5 + presented
    return {
        "open_width": open_width,
        "open_center_x": open_center_x,
        "locked_width": locked_width,
        "locked_center_x": locked_center_x,
        "boundary_x": boundary_x
    }
