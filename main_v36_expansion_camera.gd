extends "res://main_v35_road_draw_map_scale.gd"

# AXIVA v0.36 — expansion camera polish.
# Physical iPhone validation showed the old 0.85 s twitch is gone, but the
# 12 -> 14 -> 16 column unlocks still snap the orthographic camera instantly.
# This layer intercepts only runtime unlock reframing and turns it into a short,
# deterministic smooth reveal. Simulation, save data and map authority stay intact.

const V36_EXPANSION_CAMERA_SECONDS: float = 0.72

var v36_in_simulation_tick: bool = false
var v36_tick_before_cols: int = -1

var v36_expansion_camera_active: bool = false
var v36_expansion_elapsed: float = 0.0
var v36_expansion_from_target: Vector3 = Vector3.ZERO
var v36_expansion_to_target: Vector3 = Vector3.ZERO
var v36_expansion_from_size: float = 0.0
var v36_expansion_to_size: float = 0.0
var v36_expansion_from_cols: int = -1
var v36_expansion_to_cols: int = -1

var v36_expansion_started_count: int = 0
var v36_expansion_completed_count: int = 0

func _simulation_tick() -> void:
    v36_tick_before_cols = unlocked_cols
    v36_in_simulation_tick = true
    super._simulation_tick()
    v36_in_simulation_tick = false

    if unlocked_cols > v36_tick_before_cols and not v36_expansion_camera_active:
        _v36_begin_expansion_camera(v36_tick_before_cols, unlocked_cols)

# v0.24 used an immediate camera apply whenever unlocked_cols changed. Dynamic
# dispatch lets this layer intercept only that runtime path while preserving
# immediate setup/reflow behavior outside simulation ticks.
func _v24_apply_camera() -> void:
    if _v36_should_defer_camera_apply():
        _v36_begin_expansion_camera(v36_tick_before_cols, unlocked_cols)
        return
    super._v24_apply_camera()

func _v36_should_defer_camera_apply() -> bool:
    return (
        v36_in_simulation_tick
        and v28_camera_initialized
        and is_instance_valid(v10_camera)
        and unlocked_cols > v36_tick_before_cols
    )

func _v36_begin_expansion_camera(from_cols: int, to_cols: int) -> void:
    if to_cols <= from_cols:
        return
    if not is_instance_valid(v10_camera):
        return

    # The FTUE city-birth choreography already owns the camera. Suppressing the
    # immediate v0.24 snap is enough there; v0.28 will naturally ease to its
    # updated base framing on subsequent frames.
    if v28_sequence_active:
        return

    v36_expansion_camera_active = true
    v36_expansion_elapsed = 0.0
    v36_expansion_from_cols = from_cols
    v36_expansion_to_cols = to_cols

    if v28_camera_initialized:
        v36_expansion_from_target = v28_camera_target
        v36_expansion_from_size = v28_camera_size
    else:
        v36_expansion_from_target = _v28_base_camera_target()
        v36_expansion_from_size = v10_camera.size
        v28_camera_initialized = true

    v36_expansion_to_target = _v28_base_camera_target()
    v36_expansion_to_size = _v28_base_camera_size()
    v36_expansion_started_count += 1

# During the short unlock reveal, this layer owns the camera directly. Outside
# that window the inherited FTUE / stability camera logic remains authoritative.
func _v28_update_camera(delta: float) -> void:
    if not v36_expansion_camera_active:
        super._v28_update_camera(delta)
        return

    if not is_instance_valid(v10_camera):
        v36_expansion_camera_active = false
        return

    v36_expansion_elapsed = minf(
        V36_EXPANSION_CAMERA_SECONDS,
        v36_expansion_elapsed + maxf(0.0, delta)
    )
    var t: float = _v36_expansion_progress(v36_expansion_elapsed)
    v28_camera_target = v36_expansion_from_target.lerp(v36_expansion_to_target, t)
    v28_camera_size = lerpf(v36_expansion_from_size, v36_expansion_to_size, t)

    v10_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    v10_camera.size = v28_camera_size
    v10_camera.position = v28_camera_target + Vector3(14.0, 19.0, 16.0)
    v10_camera.look_at(v28_camera_target, Vector3.UP)

    if v36_expansion_elapsed >= V36_EXPANSION_CAMERA_SECONDS:
        v28_camera_target = v36_expansion_to_target
        v28_camera_size = v36_expansion_to_size
        v10_camera.size = v28_camera_size
        v10_camera.position = v28_camera_target + Vector3(14.0, 19.0, 16.0)
        v10_camera.look_at(v28_camera_target, Vector3.UP)
        v36_expansion_camera_active = false
        v36_expansion_completed_count += 1

func _v36_expansion_progress(elapsed: float) -> float:
    var raw: float = clampf(elapsed / V36_EXPANSION_CAMERA_SECONDS, 0.0, 1.0)
    # Smoothstep: zero velocity at both ends, avoiding a visible kick on unlock.
    return raw * raw * (3.0 - 2.0 * raw)
