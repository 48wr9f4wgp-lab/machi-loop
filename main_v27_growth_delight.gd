extends "res://main_v26_urban_hierarchy.gd"

# MACHI LOOP v0.27 — Growth Delight pass.
# The simulation still owns every road/building decision. This layer makes the
# resulting city birth and autonomous growth feel causal, immediate and joyful:
# buildings rise in a short road-outward wave, the first settlement receives a
# compact in-world birth pulse, and every newly grown parcel gets a deterministic
# spring-in animation. No save fields or simulation values are changed.

var v27_growth_schedule: Dictionary = {}
var v27_birth_anchor: Vector2i = Vector2i(-1, -1)
var v27_birth_started_at: float = -1000.0
var v27_growth_sequence_count: int = 0
var v27_birth_pulse_count: int = 0

func _process(delta: float) -> void:
    super._process(delta)
    _v27_cleanup_growth_schedule()

# The legacy first-road response already seeds one residential parcel immediately.
# Capture that authoritative result and turn it into the hero "city born" beat.
func _v04_seed_first_growth() -> void:
    var before: Dictionary = _v27_building_positions()
    super._v04_seed_first_growth()
    var added: Array[Vector2i] = _v27_new_buildings(before)
    for p: Vector2i in added:
        _v27_schedule_growth(p, true)
    if not added.is_empty():
        v27_birth_anchor = added[0]
        v27_birth_started_at = v04_time
        v27_birth_pulse_count += 1
        v23_birth_announced = true
        v23_birth_population = population
        v23_alert_text = "街が生まれました"
        queue_redraw()

# Existing simulation growth may create more than one parcel in a tick. Track all
# of them instead of only the first visual FX entry, so autonomous growth reads as
# a coherent wave rather than silent state changes.
func _auto_grow_buildings() -> void:
    var before: Dictionary = _v27_building_positions()
    super._auto_grow_buildings()
    var added: Array[Vector2i] = _v27_new_buildings(before)
    for p: Vector2i in added:
        _v27_schedule_growth(p, false)

func _v27_building_positions() -> Dictionary:
    var positions: Dictionary = {}
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var cell: int = int(grid[y][x])
            if cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
                positions[_key(Vector2i(x, y))] = true
    return positions

func _v27_new_buildings(before: Dictionary) -> Array[Vector2i]:
    var added: Array[Vector2i] = []
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            var cell: int = int(grid[y][x])
            if cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL] and not before.has(_key(p)):
                added.append(p)
    added.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var da: int = _v27_nearest_arterial_distance(a)
        var db: int = _v27_nearest_arterial_distance(b)
        if da == db:
            return (a.y * GRID_W + a.x) < (b.y * GRID_W + b.x)
        return da < db
    )
    return added

func _v27_schedule_growth(p: Vector2i, first_birth: bool) -> void:
    var k: String = _key(p)
    if v27_growth_schedule.has(k):
        return

    var delay: float = 0.0
    if not first_birth:
        var road_distance: int = _v27_nearest_arterial_distance(p)
        var organic_offset: float = float(abs(p.x * 31 + p.y * 47) % 4) * 0.025
        delay = minf(0.34, float(road_distance) * 0.055) + organic_offset

    var duration: float = 0.92 if first_birth else 0.72
    v27_growth_schedule[k] = {
        "p": p,
        "start": v04_time + delay,
        "duration": duration,
        "first": first_birth
    }
    v27_growth_sequence_count += 1

func _v27_nearest_arterial_distance(p: Vector2i) -> int:
    var best: int = GRID_W + GRID_H
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) != Cell.ARTERIAL:
                continue
            best = mini(best, abs(p.x - x) + abs(p.y - y))
    return best

# Buildings now rise from the ground with a restrained spring overshoot. When a
# parcel is not part of the v0.27 schedule, preserve the earlier animation path.
func _v04_growth_scale(p: Vector2i) -> float:
    var k: String = _key(p)
    if not v27_growth_schedule.has(k):
        return super._v04_growth_scale(p)

    var state: Dictionary = v27_growth_schedule[k] as Dictionary
    var start: float = float(state["start"])
    var duration: float = maxf(0.001, float(state["duration"]))
    if v04_time < start:
        return 0.06

    var t: float = clampf((v04_time - start) / duration, 0.0, 1.0)
    if t >= 1.0:
        return 1.0

    # Ease-out-back with a mild overshoot; enough to feel alive without toy-like bounce.
    var c1: float = 1.32
    var c3: float = c1 + 1.0
    var q: float = t - 1.0
    var eased: float = 1.0 + c3 * q * q * q + c1 * q * q
    return clampf(0.06 + 0.94 * eased, 0.06, 1.075)

func _v27_cleanup_growth_schedule() -> void:
    if v27_growth_schedule.is_empty():
        return
    var remove_keys: Array[String] = []
    for key: Variant in v27_growth_schedule.keys():
        var state: Dictionary = v27_growth_schedule[key] as Dictionary
        var end_time: float = float(state["start"]) + float(state["duration"]) + 0.28
        if v04_time > end_time:
            remove_keys.append(str(key))
    for key: String in remove_keys:
        v27_growth_schedule.erase(key)

# Keep all existing projected action feedback, then add compact world-space
# growth sparkles and the one-time first-settlement pulse. This is deliberately
# not a dashboard overlay: it is anchored to the city itself.
func _v10_draw_projected_effects() -> void:
    super._v10_draw_projected_effects()
    _v27_draw_growth_sparkles()
    _v27_draw_birth_pulse()

func _v27_draw_growth_sparkles() -> void:
    if v27_growth_schedule.is_empty():
        return
    for key: Variant in v27_growth_schedule.keys():
        var state: Dictionary = v27_growth_schedule[key] as Dictionary
        var start: float = float(state["start"])
        var duration: float = maxf(0.001, float(state["duration"]))
        var age: float = v04_time - start
        if age < 0.0 or age > duration:
            continue
        var p: Vector2i = state["p"] as Vector2i
        var screen: Vector2 = _v27_project_cell(p, 0.55)
        if screen.x < -100.0:
            continue
        var t: float = clampf(age / duration, 0.0, 1.0)
        var alpha: float = sin(t * PI) * 0.52
        var radius: float = 2.0 + (1.0 - t) * 2.5
        var seed: int = abs(p.x * 41 + p.y * 67)
        for i: int in range(3):
            var angle: float = float((seed + i * 109) % 360) * PI / 180.0
            var reach: float = 7.0 + float(i) * 4.0 + t * 6.0
            var offset: Vector2 = Vector2(cos(angle), sin(angle)) * reach
            draw_circle(screen + offset, radius, Color(1.0, 0.91, 0.60, alpha))

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
        var pill: Rect2 = Rect2(screen.x - 74.0, screen.y - 54.0, 148.0, 27.0)
        draw_rect(pill, Color(0.055, 0.15, 0.105, 0.88 * alpha))
        draw_string(font, pill.position + Vector2(6.0, 18.0), "街が生まれました", HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 12.0, 9, Color(0.97, 1.0, 0.97, alpha))

func _v27_project_cell(p: Vector2i, y: float) -> Vector2:
    if not is_instance_valid(v10_camera) or not is_instance_valid(v10_viewport):
        return Vector2(-999.0, -999.0)
    var vp_size: Vector2 = Vector2(v10_viewport.size)
    if vp_size.x <= 1.0 or vp_size.y <= 1.0:
        return Vector2(-999.0, -999.0)
    var projected: Vector2 = v10_camera.unproject_position(_v10_world_position(p, y))
    if projected.x < 0.0 or projected.y < 0.0 or projected.x > vp_size.x or projected.y > vp_size.y:
        return Vector2(-999.0, -999.0)
    return board_rect.position + Vector2(
        projected.x / vp_size.x * board_rect.size.x,
        projected.y / vp_size.y * board_rect.size.y
    )
