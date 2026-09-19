extends "res://main_v40_land_acquisition.gd"

# AXIVA v0.41 — touch camera navigation.
#
# Goal:
# - keep one-finger authority for strategic road input;
# - use two-finger drag to pan the fixed-angle city camera;
# - use pinch to zoom without adding free rotation;
# - keep every unlocked map area inspectable and touch-accessible on iPhone.
#
# Input contract:
# - one finger: inherited gameplay input;
# - two fingers: camera navigation only;
# - once a multi-touch gesture begins, gameplay input stays suppressed until
#   every participating finger is released so a remaining finger cannot
#   accidentally commit a road.

const V41_MIN_ZOOM_FACTOR: float = 0.55
const V41_MAX_ZOOM_FACTOR: float = 1.65
const V41_MIN_PINCH_DISTANCE: float = 8.0

var v41_touches: Dictionary = {}
var v41_navigation_gesture_active: bool = false
var v41_pair_reference_valid: bool = false
var v41_last_pair_center: Vector2 = Vector2.ZERO
var v41_last_pair_distance: float = 0.0

var v41_manual_camera: bool = false
var v41_camera_target: Vector3 = Vector3.ZERO
var v41_camera_size: float = 0.0

var v41_pan_update_count: int = 0
var v41_zoom_update_count: int = 0

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed:
            v41_touches[touch.index] = touch.position
            if v41_touches.size() >= 2:
                if not v41_navigation_gesture_active:
                    _v41_begin_navigation_gesture()
                else:
                    _v41_capture_pair_reference()
                get_viewport().set_input_as_handled()
                return

            if v41_navigation_gesture_active:
                get_viewport().set_input_as_handled()
                return

            super._unhandled_input(event)
            return

        if v41_navigation_gesture_active:
            v41_touches.erase(touch.index)
            v41_pair_reference_valid = false
            if v41_touches.is_empty():
                v41_navigation_gesture_active = false
            get_viewport().set_input_as_handled()
            return

        v41_touches.erase(touch.index)
        super._unhandled_input(event)
        return

    if event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        if v41_touches.has(drag.index):
            v41_touches[drag.index] = drag.position

        if v41_navigation_gesture_active:
            if v41_touches.size() >= 2:
                _v41_apply_navigation_gesture()
            get_viewport().set_input_as_handled()
            return

        super._unhandled_input(event)
        return

    super._unhandled_input(event)

func _v41_begin_navigation_gesture() -> void:
    v41_navigation_gesture_active = true

    # A second finger converts the interaction into camera navigation. Cancel
    # any one-finger road preview that may have begun on the first touch.
    dragging = false
    drag_path.clear()
    v35_drag_origin = Vector2i(-1, -1)
    v35_drag_axis = V35Axis.NONE
    _v10_sync_preview()

    if not v41_manual_camera:
        if v28_camera_initialized:
            v41_camera_target = v28_camera_target
            v41_camera_size = v28_camera_size
        else:
            v41_camera_target = _v28_base_camera_target()
            v41_camera_size = v10_camera.size if is_instance_valid(v10_camera) else _v28_base_camera_size()
        if v41_camera_size <= 0.0:
            v41_camera_size = _v28_base_camera_size()
        v41_manual_camera = true

    # Manual navigation becomes camera authority immediately. The automatic
    # expansion reveal remains available until the player first navigates.
    v36_expansion_camera_active = false
    _v41_clamp_camera()
    _v41_apply_manual_camera()
    _v41_capture_pair_reference()

func _v41_capture_pair_reference() -> void:
    var pair: Array[Vector2] = _v41_pair_points()
    if pair.size() < 2:
        v41_pair_reference_valid = false
        return
    v41_last_pair_center = (pair[0] + pair[1]) * 0.5
    v41_last_pair_distance = pair[0].distance_to(pair[1])
    v41_pair_reference_valid = true

func _v41_apply_navigation_gesture() -> void:
    var pair: Array[Vector2] = _v41_pair_points()
    if pair.size() < 2:
        v41_pair_reference_valid = false
        return

    var center: Vector2 = (pair[0] + pair[1]) * 0.5
    var distance: float = pair[0].distance_to(pair[1])

    if not v41_pair_reference_valid:
        v41_last_pair_center = center
        v41_last_pair_distance = distance
        v41_pair_reference_valid = true
        return

    var center_delta: Vector2 = center - v41_last_pair_center
    if center_delta.length_squared() > 0.01:
        _v41_pan_by_screen_delta(center_delta)
        v41_pan_update_count += 1

    if v41_last_pair_distance >= V41_MIN_PINCH_DISTANCE and distance >= V41_MIN_PINCH_DISTANCE:
        var zoom_factor: float = v41_last_pair_distance / distance
        if absf(zoom_factor - 1.0) > 0.001:
            v41_camera_size = clampf(
                v41_camera_size * zoom_factor,
                _v41_min_camera_size(),
                _v41_max_camera_size()
            )
            v41_zoom_update_count += 1

    v41_last_pair_center = center
    v41_last_pair_distance = distance
    _v41_clamp_camera()
    _v41_apply_manual_camera()
    queue_redraw()

func _v41_pair_points() -> Array[Vector2]:
    var result: Array[Vector2] = []
    if v41_touches.size() < 2:
        return result

    var keys: Array = v41_touches.keys()
    keys.sort()
    result.append(v41_touches[keys[0]] as Vector2)
    result.append(v41_touches[keys[1]] as Vector2)
    return result

func _v41_pan_by_screen_delta(delta: Vector2) -> void:
    if not is_instance_valid(v10_camera) or not is_instance_valid(v10_viewport):
        return

    var vp_height: float = maxf(1.0, float(v10_viewport.size.y))
    var world_per_pixel: float = v41_camera_size / vp_height

    var basis: Basis = v10_camera.global_transform.basis
    var screen_right: Vector3 = Vector3(basis.x.x, 0.0, basis.x.z)
    var screen_down: Vector3 = Vector3(-basis.y.x, 0.0, -basis.y.z)
    if screen_right.length_squared() < 0.0001 or screen_down.length_squared() < 0.0001:
        return

    screen_right = screen_right.normalized()
    screen_down = screen_down.normalized()

    # Dragging the map right/down should make the world follow the fingers, so
    # the camera target moves in the opposite projected direction.
    var camera_shift: Vector3 = -(
        screen_right * delta.x
        + screen_down * delta.y
    ) * world_per_pixel

    v41_camera_target += camera_shift
    v41_camera_target.y = 0.0

func _v41_min_camera_size() -> float:
    return _v28_base_camera_size() * V41_MIN_ZOOM_FACTOR

func _v41_max_camera_size() -> float:
    return _v28_base_camera_size() * V41_MAX_ZOOM_FACTOR

func _v41_clamp_camera() -> void:
    var min_size: float = _v41_min_camera_size()
    var max_size: float = _v41_max_camera_size()
    v41_camera_size = clampf(v41_camera_size, min_size, max_size)

    var base_target: Vector3 = _v28_base_camera_target()

    # At full zoom-out the whole city should stay near center. As the player
    # zooms in, progressively more pan range becomes available.
    var pan_factor: float = clampf(1.0 - v41_camera_size / max_size, 0.0, 0.78)
    var max_pan_x: float = maxf(0.75, float(unlocked_cols) * 0.48 * pan_factor)
    var max_pan_z: float = maxf(0.75, float(GRID_H) * 0.48 * pan_factor)

    v41_camera_target.x = clampf(
        v41_camera_target.x,
        base_target.x - max_pan_x,
        base_target.x + max_pan_x
    )
    v41_camera_target.z = clampf(
        v41_camera_target.z,
        base_target.z - max_pan_z,
        base_target.z + max_pan_z
    )
    v41_camera_target.y = 0.0

func _v41_apply_manual_camera() -> void:
    if not v41_manual_camera or not is_instance_valid(v10_camera):
        return

    v10_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    v10_camera.size = v41_camera_size
    v10_camera.position = v41_camera_target + Vector3(14.0, 19.0, 16.0)
    v10_camera.look_at(v41_camera_target, Vector3.UP)

    # Keep inherited camera state coherent for any later subsystem that reads it.
    v28_camera_initialized = true
    v28_camera_target = v41_camera_target
    v28_camera_size = v41_camera_size

func _v24_apply_camera() -> void:
    if v41_manual_camera:
        _v41_clamp_camera()
        _v41_apply_manual_camera()
        return
    super._v24_apply_camera()

func _v28_update_camera(delta: float) -> void:
    if not v41_manual_camera:
        super._v28_update_camera(delta)
        return

    v36_expansion_camera_active = false
    _v41_clamp_camera()
    _v41_apply_manual_camera()
