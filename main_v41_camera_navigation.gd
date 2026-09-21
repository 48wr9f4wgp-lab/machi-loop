extends "res://main_v40_land_acquisition.gd"

# AXIVA touch arbitration. Every edit is cancellable until one finger releases.
# HUD taps and WIDEN/REMOVE never mutate on pointer-down. Two fingers exclusively
# own navigation until all contacts are lifted. Mouse emulation is disabled in
# project.godot; real mouse input remains useful for development.
const V41_MIN_ZOOM_FACTOR: float = 0.55
const V41_MAX_ZOOM_FACTOR: float = 1.65
const V41_MIN_PINCH_DISTANCE: float = 8.0
const V41_TAP_SLOP: float = 12.0
const V41_OVERVIEW: int = 90
const V41_RESET: int = 91

var v41_touches: Dictionary = {}
var v41_touch_eligible: Dictionary = {}
var v41_navigation_gesture_active: bool = false
var v41_multi_latched: bool = false
var v41_pair_reference_valid: bool = false
var v41_last_pair_center: Vector2 = Vector2.ZERO
var v41_last_pair_distance: float = 0.0
var v41_manual_camera: bool = false
var v41_camera_target: Vector3 = Vector3.ZERO
var v41_camera_size: float = 0.0
var v41_pan_update_count: int = 0
var v41_zoom_update_count: int = 0
var v41_single_down: bool = false
var v41_single_origin: Vector2 = Vector2.ZERO
var v41_single_action: int = -1
var v41_single_cell: Vector2i = Vector2i(-1, -1)
var v41_single_is_ui: bool = false
var v41_single_moved: bool = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.canceled:
            _v41_cancel_all_input()
        elif touch.pressed:
            v41_touches[touch.index] = touch.position
            v41_touch_eligible[touch.index] = _v41_world_area().has_point(touch.position)
            if v41_touches.size() >= 2:
                v41_multi_latched = true
                _v41_cancel_edit()
                if _v41_pair_is_eligible():
                    _v41_begin_navigation_gesture()
            elif not v41_multi_latched:
                _v41_begin_single(touch.position)
        elif v41_touches.has(touch.index):
            v41_touches.erase(touch.index)
            v41_touch_eligible.erase(touch.index)
            if not v41_multi_latched:
                _v41_finish_single(touch.position)
            v41_pair_reference_valid = false
            if v41_touches.is_empty():
                v41_multi_latched = false
                v41_navigation_gesture_active = false
        get_viewport().set_input_as_handled()
        return
    if event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        if not v41_touches.has(drag.index):
            return
        v41_touches[drag.index] = drag.position
        if v41_multi_latched:
            if v41_navigation_gesture_active and v41_touches.size() >= 2:
                _v41_apply_navigation_gesture()
        else:
            _v41_move_single(drag.position)
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseButton:
        if event.device < 0 or not v41_touches.is_empty():
            return
        var mouse: InputEventMouseButton = event
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed:
                _v41_begin_single(mouse.position)
            else:
                _v41_finish_single(mouse.position)
            get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseMotion and v41_single_down:
        if event.device >= 0 and v41_touches.is_empty():
            _v41_move_single(event.position)

func _v41_begin_single(pos: Vector2) -> void:
    v41_single_down = true
    v41_single_origin = pos
    v41_single_moved = false
    v41_single_action = _v41_ui_action(pos)
    v41_single_is_ui = v41_single_action >= 0
    if v41_single_is_ui:
        return
    if not _v41_world_area().has_point(pos):
        v41_single_action = -1
        return
    v41_single_cell = _screen_to_cell(pos)
    v41_single_action = current_tool
    if current_tool == Tool.ROAD:
        _pointer_down(pos)

func _v41_move_single(pos: Vector2) -> void:
    if not v41_single_down:
        return
    if pos.distance_to(v41_single_origin) > V41_TAP_SLOP:
        v41_single_moved = true
    if not v41_single_is_ui and v41_single_action == Tool.ROAD and dragging:
        if _v41_world_area().has_point(pos):
            _pointer_move(pos)

func _v41_finish_single(pos: Vector2) -> void:
    if not v41_single_down:
        return
    v41_single_down = false
    if v41_single_is_ui:
        if not v41_single_moved and _v41_ui_action(pos) == v41_single_action:
            _v41_execute_ui(v41_single_action)
        return
    if not _v41_world_area().has_point(pos):
        _v41_cancel_edit()
        return
    if v41_single_action == Tool.ROAD and dragging:
        _pointer_move(pos)
        _pointer_up(pos)
    elif not v41_single_moved and _screen_to_cell(pos) == v41_single_cell:
        if not _in_bounds(v41_single_cell) or v41_single_cell.x >= unlocked_cols:
            return
        if v41_single_action == Tool.WIDEN:
            _widen(v41_single_cell)
        elif v41_single_action == Tool.BULLDOZE:
            _bulldoze(v41_single_cell)

func _v41_ui_action(pos: Vector2) -> int:
    if _v33_reset_rect().has_point(pos):
        return V41_RESET
    if _v41_overview_rect().has_point(pos):
        return V41_OVERVIEW
    for value: Variant in tool_rects:
        var rect: Rect2 = tool_rects[value]
        if rect.has_point(pos):
            return int(value)
    return -1

func _v41_execute_ui(action: int) -> void:
    _v41_cancel_edit()
    if action == V41_RESET:
        _v33_request_reset()
    elif action == V41_OVERVIEW:
        _v41_show_overview()
    elif action in [Tool.ROAD, Tool.WIDEN, Tool.BULLDOZE]:
        current_tool = action
        queue_redraw()

func _v41_overview_rect() -> Rect2:
    return Rect2(board_rect.end.x - 78.0, _v34_context_rect().end.y + 7.0, 68.0, 44.0)

func _v41_world_area() -> Rect2:
    # Exclude the entire HUD band, not just the painted RESET label.
    var top: float = _v41_overview_rect().end.y + 5.0
    return Rect2(board_rect.position.x, top, board_rect.size.x,
        maxf(1.0, board_rect.end.y - top - 50.0))

func _v41_cancel_edit() -> void:
    v41_single_down = false
    v41_single_action = -1
    dragging = false
    drag_path.clear()
    v35_drag_origin = Vector2i(-1, -1)
    v35_drag_axis = V35Axis.NONE
    _v10_sync_preview()
    queue_redraw()

func _v41_cancel_all_input() -> void:
    _v41_cancel_edit()
    v41_touches.clear()
    v41_touch_eligible.clear()
    v41_multi_latched = false
    v41_navigation_gesture_active = false
    v41_pair_reference_valid = false
    v33_reset_armed_for = 0.0

func _notification(what: int) -> void:
    if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
        _v41_cancel_all_input()

func _v41_pair_is_eligible() -> bool:
    var keys: Array = v41_touches.keys()
    keys.sort()
    return keys.size() >= 2 and bool(v41_touch_eligible.get(keys[0], false)) and bool(v41_touch_eligible.get(keys[1], false))

func _v41_pair_points() -> Array[Vector2]:
    var pair: Array[Vector2] = []
    var keys: Array = v41_touches.keys()
    keys.sort()
    if keys.size() >= 2:
        pair.append(v41_touches[keys[0]])
        pair.append(v41_touches[keys[1]])
    return pair

func _v41_begin_navigation_gesture() -> void:
    v41_navigation_gesture_active = true
    if not v41_manual_camera:
        v41_camera_target = v28_camera_target if v28_camera_initialized else _v28_base_camera_target()
        v41_camera_size = v10_camera.size if is_instance_valid(v10_camera) else _v28_base_camera_size()
        v41_manual_camera = true
    v36_expansion_camera_active = false
    _v41_clamp_camera()
    _v41_apply_manual_camera()
    _v41_capture_pair_reference()

func _v41_capture_pair_reference() -> void:
    var pair: Array[Vector2] = _v41_pair_points()
    v41_pair_reference_valid = pair.size() == 2
    if v41_pair_reference_valid:
        v41_last_pair_center = (pair[0] + pair[1]) * 0.5
        v41_last_pair_distance = pair[0].distance_to(pair[1])

func _v41_ground_at(screen: Vector2) -> Vector3:
    if not is_instance_valid(v10_camera) or not is_instance_valid(v10_viewport):
        return Vector3(INF, INF, INF)
    var local: Vector2 = screen - board_rect.position
    var point: Vector2 = local / board_rect.size * Vector2(v10_viewport.size)
    var origin: Vector3 = v10_camera.project_ray_origin(point)
    var direction: Vector3 = v10_camera.project_ray_normal(point)
    if absf(direction.y) < 0.00001:
        return Vector3(INF, INF, INF)
    return origin + direction * (-origin.y / direction.y)

func _v41_apply_navigation_gesture() -> void:
    var pair: Array[Vector2] = _v41_pair_points()
    if pair.size() != 2:
        return
    if not v41_pair_reference_valid:
        _v41_capture_pair_reference()
        return
    var center: Vector2 = (pair[0] + pair[1]) * 0.5
    var distance: float = pair[0].distance_to(pair[1])
    var anchor: Vector3 = _v41_ground_at(v41_last_pair_center)
    if distance >= V41_MIN_PINCH_DISTANCE and v41_last_pair_distance >= V41_MIN_PINCH_DISTANCE:
        v41_camera_size = clampf(v41_camera_size * v41_last_pair_distance / distance,
            _v41_min_camera_size(), _v41_max_camera_size())
        if absf(distance - v41_last_pair_distance) > 0.1:
            v41_zoom_update_count += 1
    _v41_apply_manual_camera()
    var after: Vector3 = _v41_ground_at(center)
    if anchor.is_finite() and after.is_finite():
        v41_camera_target += anchor - after
        if center.distance_squared_to(v41_last_pair_center) > 0.01:
            v41_pan_update_count += 1
    _v41_clamp_camera()
    _v41_apply_manual_camera()
    v41_last_pair_center = center
    v41_last_pair_distance = distance
    queue_redraw()

func _v41_fit_camera_size() -> float:
    var z: Vector3 = Vector3(14.0, 19.0, 16.0).normalized()
    var right: Vector3 = Vector3.UP.cross(z).normalized()
    var up: Vector3 = z.cross(right).normalized()
    var width: float = absf(right.x) * unlocked_cols + absf(right.z) * GRID_H
    var height: float = absf(up.x) * unlocked_cols + absf(up.z) * GRID_H + 6.0
    var aspect: float = board_rect.size.x / maxf(1.0, board_rect.size.y)
    if is_instance_valid(v10_viewport):
        aspect = float(v10_viewport.size.x) / maxf(1.0, float(v10_viewport.size.y))
    var top_margin: float = _v41_world_area().position.y - board_rect.position.y
    var safe_fraction: float = maxf(0.3, 1.0 - 2.0 * top_margin / maxf(1.0, board_rect.size.y))
    return maxf(width / maxf(0.1, aspect), height / safe_fraction) * 1.08

func _v41_min_camera_size() -> float:
    return _v28_base_camera_size() * V41_MIN_ZOOM_FACTOR

func _v41_max_camera_size() -> float:
    return maxf(_v28_base_camera_size() * V41_MAX_ZOOM_FACTOR, _v41_fit_camera_size())

func _v41_clamp_camera() -> void:
    v41_camera_size = clampf(v41_camera_size, _v41_min_camera_size(), _v41_max_camera_size())
    # Each open cell may become the view center. Do not restrict close-up access
    # to corners using an arbitrary percentage of the map dimensions.
    v41_camera_target.x = clampf(v41_camera_target.x, -GRID_W * 0.5 + 0.5, -GRID_W * 0.5 + unlocked_cols - 0.5)
    v41_camera_target.z = clampf(v41_camera_target.z, -GRID_H * 0.5 + 0.5, GRID_H * 0.5 - 0.5)
    v41_camera_target.y = 0.0

func _v41_show_overview() -> void:
    v41_manual_camera = true
    v41_camera_target = _v28_base_camera_target()
    v41_camera_size = _v41_fit_camera_size()
    v36_expansion_camera_active = false
    _v41_apply_manual_camera()
    queue_redraw()

func _v41_apply_manual_camera() -> void:
    if not v41_manual_camera or not is_instance_valid(v10_camera):
        return
    v10_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    v10_camera.keep_aspect = Camera3D.KEEP_HEIGHT
    v10_camera.size = v41_camera_size
    v10_camera.position = v41_camera_target + Vector3(14.0, 19.0, 16.0)
    v10_camera.look_at(v41_camera_target, Vector3.UP)
    v28_camera_initialized = true
    v28_camera_target = v41_camera_target
    v28_camera_size = v41_camera_size

func _v24_apply_camera() -> void:
    if v41_manual_camera:
        _v41_clamp_camera()
        _v41_apply_manual_camera()
    else:
        super._v24_apply_camera()

func _v28_update_camera(delta: float) -> void:
    if dragging:
        return
    if v41_manual_camera:
        v36_expansion_camera_active = false
        _v41_clamp_camera()
        _v41_apply_manual_camera()
    else:
        super._v28_update_camera(delta)

func _v10_sync_scene(force: bool = false) -> void:
    super._v10_sync_scene(force)
    if v41_manual_camera:
        _v41_apply_manual_camera()
