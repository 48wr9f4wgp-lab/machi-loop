extends "res://main_v27_growth_delight.gd"

# MACHI LOOP v0.28 — City Birth Sequence / camera choreography.
# Presentation-only Vertical Slice work: turn the authoritative simulation beats
# (first home -> local road -> commercial response -> recognizable settlement)
# into one readable causal sequence. Simulation, economy, traffic and save data
# remain owned by inherited layers.

const V28_STAGE_NONE: int = 0
const V28_STAGE_HOME: int = 1
const V28_STAGE_LOCAL: int = 2
const V28_STAGE_COMMERCIAL: int = 3
const V28_STAGE_REVEAL: int = 4

var v28_sequence_active: bool = false
var v28_sequence_stage: int = V28_STAGE_NONE
var v28_sequence_started_at: float = -1000.0
var v28_stage_started_at: float = -1000.0
var v28_reveal_started_at: float = -1000.0
var v28_home_anchor: Vector2i = Vector2i(-1, -1)
var v28_local_anchor: Vector2i = Vector2i(-1, -1)
var v28_commercial_anchor: Vector2i = Vector2i(-1, -1)
var v28_milestone_count: int = 0
var v28_reveal_count: int = 0
var v28_camera_initialized: bool = false
var v28_camera_target: Vector3 = Vector3.ZERO
var v28_camera_size: float = 0.0

func _process(delta: float) -> void:
    super._process(delta)
    _v28_update_camera(delta)
    if v28_sequence_active and v28_sequence_stage == V28_STAGE_REVEAL:
        if v04_time - v28_reveal_started_at > 2.80:
            v28_sequence_active = false
            if v23_alert_text == "街が生まれました":
                v23_alert_text = ""
            queue_redraw()

# The first residential seed is still created by the inherited simulation.
# v0.28 only records it as the first beat of the city-birth sequence.
func _v04_seed_first_growth() -> void:
    super._v04_seed_first_growth()
    if v27_birth_anchor.x >= 0 and not v28_sequence_active and v28_sequence_stage == V28_STAGE_NONE:
        _v28_begin_sequence(v27_birth_anchor)

func _v28_begin_sequence(anchor: Vector2i) -> void:
    v28_sequence_active = true
    v28_sequence_stage = V28_STAGE_HOME
    v28_sequence_started_at = v04_time
    v28_stage_started_at = v04_time
    v28_home_anchor = anchor
    v28_milestone_count += 1
    # v23/v27 already mark internal birth state. The v0.28 presentation delays the
    # final "city born" wording until the wider settlement visibly exists.
    v23_alert_text = "最初の家が建ちました"
    queue_redraw()

func _auto_generate_local_roads() -> void:
    var before: Dictionary = _v28_positions_of(Cell.LOCAL)
    super._auto_generate_local_roads()
    if not v28_sequence_active:
        return
    var added: Array[Vector2i] = _v28_added_positions(before, Cell.LOCAL)
    if not added.is_empty():
        _v28_note_local_road(added[0])

func _auto_grow_buildings() -> void:
    var before_commercial: Dictionary = _v28_positions_of(Cell.COMMERCIAL)
    super._auto_grow_buildings()
    if not v28_sequence_active:
        return
    var added_commercial: Array[Vector2i] = _v28_added_positions(before_commercial, Cell.COMMERCIAL)
    if not added_commercial.is_empty():
        _v28_note_commercial(added_commercial[0])

func _simulation_tick() -> void:
    super._simulation_tick()
    _v28_maybe_reveal()

func _v28_positions_of(cell_type: int) -> Dictionary:
    var result: Dictionary = {}
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) == cell_type:
                result[_key(Vector2i(x, y))] = true
    return result

func _v28_added_positions(before: Dictionary, cell_type: int) -> Array[Vector2i]:
    var added: Array[Vector2i] = []
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            if int(grid[y][x]) == cell_type and not before.has(_key(p)):
                added.append(p)
    added.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var da: int = _v28_distance_to_home(a)
        var db: int = _v28_distance_to_home(b)
        if da == db:
            return (a.y * GRID_W + a.x) < (b.y * GRID_W + b.x)
        return da < db
    )
    return added

func _v28_distance_to_home(p: Vector2i) -> int:
    if v28_home_anchor.x < 0:
        return 0
    return abs(p.x - v28_home_anchor.x) + abs(p.y - v28_home_anchor.y)

func _v28_note_local_road(p: Vector2i) -> void:
    if v28_local_anchor.x < 0:
        v28_local_anchor = p
    if v28_sequence_stage < V28_STAGE_LOCAL:
        v28_sequence_stage = V28_STAGE_LOCAL
        v28_stage_started_at = v04_time
        v28_milestone_count += 1
        v23_alert_text = "生活道路が伸びています"
        queue_redraw()

func _v28_note_commercial(p: Vector2i) -> void:
    if v28_commercial_anchor.x < 0:
        v28_commercial_anchor = p
    if v28_sequence_stage < V28_STAGE_COMMERCIAL:
        v28_sequence_stage = V28_STAGE_COMMERCIAL
        v28_stage_started_at = v04_time
        v28_milestone_count += 1
        v23_alert_text = "人の流れに商業が反応しています"
        queue_redraw()

func _v28_maybe_reveal() -> void:
    if not v28_sequence_active or v28_sequence_stage >= V28_STAGE_REVEAL:
        return
    if v28_home_anchor.x < 0 or v28_local_anchor.x < 0 or v28_commercial_anchor.x < 0:
        return
    if population < 26:
        return
    v28_sequence_stage = V28_STAGE_REVEAL
    v28_stage_started_at = v04_time
    v28_reveal_started_at = v04_time
    v28_reveal_count += 1
    v28_milestone_count += 1
    v23_alert_text = "街が生まれました"
    queue_redraw()

# Hide the inherited early "city born" copy while the city is still only one
# house. The final wording is reserved for the wider settlement reveal.
func _v23_context_message() -> String:
    if v28_sequence_active:
        match v28_sequence_stage:
            V28_STAGE_HOME:
                return "最初の家から、街が広がります"
            V28_STAGE_LOCAL:
                return "生活道路が自動で伸びています"
            V28_STAGE_COMMERCIAL:
                return "人の流れに商業が反応しています"
            V28_STAGE_REVEAL:
                return "街が生まれました"
    return super._v23_context_message()

# v0.27's pulse remains, but its copy now describes the actual first beat rather
# than claiming the whole city already exists.
func _v27_draw_birth_pulse() -> void:
    if v27_birth_anchor.x < 0:
        return
    var age: float = v04_time - v27_birth_started_at
    if age < 0.0 or age > 2.35:
        return
    var screen: Vector2 = _v27_project_cell(v27_birth_anchor, 0.38)
    if screen.x < -100.0:
        return

    for i: int in range(3):
        var local_age: float = age - float(i) * 0.17
        if local_age < 0.0:
            continue
        var t: float = clampf(local_age / 1.35, 0.0, 1.0)
        if t >= 1.0:
            continue
        var radius: float = lerpf(8.0, 58.0, t)
        var alpha: float = (1.0 - t) * 0.48
        draw_circle(screen, radius, Color(0.58, 0.93, 0.70, alpha), false, 2.0)

    if age >= 0.42 and age <= 1.85:
        var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
        var alpha: float = minf(1.0, (age - 0.42) / 0.18) * minf(1.0, (1.85 - age) / 0.30)
        var pill: Rect2 = Rect2(screen.x - 82.0, screen.y - 54.0, 164.0, 27.0)
        draw_rect(pill, Color(0.055, 0.15, 0.105, 0.88 * alpha))
        draw_string(font, pill.position + Vector2(6.0, 18.0), "最初の家が建ちました", HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 12.0, 9, Color(0.97, 1.0, 0.97, alpha))

func _v10_draw_projected_effects() -> void:
    super._v10_draw_projected_effects()
    _v28_draw_milestone_callout()
    _v28_draw_reveal()

func _v28_draw_milestone_callout() -> void:
    if not v28_sequence_active or v28_sequence_stage in [V28_STAGE_NONE, V28_STAGE_HOME, V28_STAGE_REVEAL]:
        return
    var age: float = v04_time - v28_stage_started_at
    if age < 0.0 or age > 1.45:
        return

    var anchor: Vector2i = v28_local_anchor if v28_sequence_stage == V28_STAGE_LOCAL else v28_commercial_anchor
    if anchor.x < 0:
        return
    var text: String = "生活道路が伸びる" if v28_sequence_stage == V28_STAGE_LOCAL else "商業が反応"
    var screen: Vector2 = _v27_project_cell(anchor, 0.46)
    if screen.x < -100.0:
        return

    var alpha: float = minf(1.0, age / 0.18) * minf(1.0, (1.45 - age) / 0.28)
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var pill: Rect2 = Rect2(screen.x - 62.0, screen.y - 43.0, 124.0, 24.0)
    draw_rect(pill, Color(0.06, 0.16, 0.12, 0.82 * alpha))
    draw_string(font, pill.position + Vector2(6.0, 16.0), text, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 12.0, 8, Color(0.97, 1.0, 0.97, alpha))

func _v28_draw_reveal() -> void:
    if v28_sequence_stage != V28_STAGE_REVEAL:
        return
    var age: float = v04_time - v28_reveal_started_at
    if age < 0.0 or age > 2.55:
        return
    var anchor: Vector2i = v28_commercial_anchor if v28_commercial_anchor.x >= 0 else v28_home_anchor
    var screen: Vector2 = _v27_project_cell(anchor, 0.50)
    if screen.x < -100.0:
        return

    var t: float = clampf(age / 1.65, 0.0, 1.0)
    if t < 1.0:
        var radius: float = lerpf(18.0, 92.0, t)
        var alpha: float = (1.0 - t) * 0.34
        draw_circle(screen, radius, Color(0.68, 0.93, 0.72, alpha), false, 2.5)

    if age >= 0.35 and age <= 2.20:
        var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
        var alpha: float = minf(1.0, (age - 0.35) / 0.20) * minf(1.0, (2.20 - age) / 0.35)
        var w: float = minf(board_rect.size.x - 36.0, 230.0)
        var pill: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + 48.0, w, 35.0)
        draw_rect(pill, Color(0.05, 0.15, 0.105, 0.91 * alpha))
        draw_string(font, pill.position + Vector2(8.0, 23.0), "街が生まれました", HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 16.0, 12, Color(0.98, 1.0, 0.98, alpha))

# Camera choreography keeps the first home large enough to read, follows the
# emerging street/commercial response, then gently pulls back to the standard
# city-dominant framing. It never changes world state or input authority.
func _v28_update_camera(delta: float) -> void:
    if not is_instance_valid(v10_camera):
        return

    var base_target: Vector3 = _v28_base_camera_target()
    var base_size: float = _v28_base_camera_size()
    if not v28_camera_initialized:
        v28_camera_initialized = true
        v28_camera_target = base_target
        v28_camera_size = base_size

    var desired_target: Vector3 = base_target
    var desired_size: float = base_size

    if v28_sequence_active and v28_home_anchor.x >= 0:
        var home_target: Vector3 = _v28_world_target(v28_home_anchor)
        match v28_sequence_stage:
            V28_STAGE_HOME:
                desired_target = home_target
                desired_size = base_size * 0.72
            V28_STAGE_LOCAL:
                var local_target: Vector3 = _v28_world_target(v28_local_anchor) if v28_local_anchor.x >= 0 else home_target
                desired_target = home_target.lerp(local_target, 0.42)
                desired_size = base_size * 0.76
            V28_STAGE_COMMERCIAL:
                var commercial_target: Vector3 = _v28_world_target(v28_commercial_anchor) if v28_commercial_anchor.x >= 0 else home_target
                desired_target = home_target.lerp(commercial_target, 0.50)
                desired_size = base_size * 0.80
            V28_STAGE_REVEAL:
                var reveal_t: float = clampf((v04_time - v28_reveal_started_at) / 1.80, 0.0, 1.0)
                reveal_t = reveal_t * reveal_t * (3.0 - 2.0 * reveal_t)
                var settlement_target: Vector3 = _v28_settlement_target()
                desired_target = settlement_target.lerp(base_target, reveal_t)
                desired_size = lerpf(base_size * 0.80, base_size, reveal_t)

    var response: float = clampf(delta * 5.0, 0.0, 1.0)
    v28_camera_target = v28_camera_target.lerp(desired_target, response)
    v28_camera_size = lerpf(v28_camera_size, desired_size, response)
    v10_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    v10_camera.size = v28_camera_size
    v10_camera.position = v28_camera_target + Vector3(14.0, 19.0, 16.0)
    v10_camera.look_at(v28_camera_target, Vector3.UP)

func _v28_base_camera_target() -> Vector3:
    var open_center_x: float = -float(GRID_W) * 0.5 + float(unlocked_cols) * 0.5
    return Vector3(open_center_x, 0.0, 0.0)

func _v28_base_camera_size() -> float:
    var aspect: float = 0.56
    if board_rect.size.y > 1.0:
        aspect = maxf(0.40, board_rect.size.x / board_rect.size.y)
    var height_need: float = float(GRID_H) * 1.06
    var width_need: float = (float(unlocked_cols) / aspect) * 1.06
    return maxf(height_need, width_need)

func _v28_world_target(p: Vector2i) -> Vector3:
    var world: Vector3 = _v10_world_position(p, 0.0)
    return Vector3(world.x, 0.0, world.z)

func _v28_settlement_target() -> Vector3:
    var sum: Vector3 = Vector3.ZERO
    var count: float = 0.0
    for p: Vector2i in [v28_home_anchor, v28_local_anchor, v28_commercial_anchor]:
        if p.x < 0:
            continue
        sum += _v28_world_target(p)
        count += 1.0
    return sum / count if count > 0.0 else _v28_base_camera_target()
