extends "res://main_v28_city_birth_sequence.gd"

# MACHI LOOP v0.29 — Congestion -> Bypass Recovery sequence.
# The inherited traffic model remains authoritative. This layer turns its
# structural congestion / redundancy change into a readable city-first loop:
# hotspot -> player adds another arterial route -> traffic pressure falls ->
# autonomous growth resumes. No save schema or economy values are changed.

const V29_STAGE_NONE: int = 0
const V29_STAGE_PROBLEM: int = 1
const V29_STAGE_INTERVENTION: int = 2
const V29_STAGE_RECOVERY: int = 3
const V29_STAGE_RESUMED: int = 4

var v29_recovery_stage: int = V29_STAGE_NONE
var v29_problem_started_at: float = -1000.0
var v29_intervention_started_at: float = -1000.0
var v29_recovery_started_at: float = -1000.0
var v29_final_started_at: float = -1000.0
var v29_problem_congestion: float = 0.0
var v29_recovery_congestion: float = 0.0
var v29_problem_cycles: int = 0
var v29_problem_anchor: Vector2i = Vector2i(-1, -1)
var v29_hotspot_cells: Array[Vector2i] = []
var v29_bypass_cells: Array[Vector2i] = []
var v29_intervention_count: int = 0
var v29_recovery_count: int = 0
var v29_growth_resume_count: int = 0
var v29_completion_count: int = 0

func _process(delta: float) -> void:
    super._process(delta)
    if v29_recovery_stage == V29_STAGE_RESUMED and v04_time - v29_final_started_at > 3.40:
        v29_recovery_stage = V29_STAGE_NONE
        v29_hotspot_cells.clear()
        v29_bypass_cells.clear()
        if v23_alert_text == "道一本で街の流れが変わった":
            v23_alert_text = ""
        queue_redraw()

func _recalculate_city() -> void:
    super._recalculate_city()
    _v29_observe_traffic_state()

func _v29_observe_traffic_state() -> void:
    if v29_recovery_stage == V29_STAGE_NONE:
        if _v29_should_begin_problem():
            _v29_begin_problem()
        return

    if v29_recovery_stage != V29_STAGE_INTERVENTION:
        return

    var cycle_gain: bool = v16_cycles > v29_problem_cycles
    var drop: float = v29_problem_congestion - congestion
    var meaningfully_better: bool = drop >= maxf(12.0, v29_problem_congestion * 0.12)
    var status_recovered: bool = v16_traffic_status != "severe"
    if cycle_gain and (meaningfully_better or status_recovered):
        _v29_begin_recovery()

func _v29_should_begin_problem() -> bool:
    if v28_sequence_active:
        return false
    if population < 90:
        return false
    if _count_cells(Cell.ARTERIAL) < 6:
        return false
    if v16_traffic_status != "severe":
        return false
    return v16_traffic_cause in ["no_redundancy", "capacity", "dead_ends"]

func _v29_begin_problem() -> void:
    v29_recovery_stage = V29_STAGE_PROBLEM
    v29_problem_started_at = v04_time
    v29_problem_congestion = congestion
    v29_problem_cycles = v16_cycles
    v29_problem_anchor = _v29_find_worst_arterial()
    v29_hotspot_cells = _v29_find_hotspot_cells(5)
    v29_bypass_cells.clear()
    v23_alert_text = "この道に交通が集中しています"
    queue_redraw()

func _commit_arterial() -> void:
    var intended: Array[Vector2i] = []
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if _in_bounds(p) and p.x < unlocked_cols and int(grid[p.y][p.x]) == Cell.EMPTY:
            intended.append(p)

    super._commit_arterial()

    var committed: Array[Vector2i] = []
    for p: Vector2i in intended:
        if int(grid[p.y][p.x]) == Cell.ARTERIAL:
            committed.append(p)
    if committed.is_empty():
        return
    if v29_recovery_stage in [V29_STAGE_PROBLEM, V29_STAGE_INTERVENTION]:
        _v29_register_intervention(committed)

func _v29_register_intervention(cells: Array[Vector2i]) -> void:
    if cells.is_empty():
        return
    if v29_recovery_stage == V29_STAGE_PROBLEM:
        v29_recovery_stage = V29_STAGE_INTERVENTION
        v29_intervention_started_at = v04_time
    elif v29_recovery_stage != V29_STAGE_INTERVENTION:
        return

    for p: Vector2i in cells:
        if not v29_bypass_cells.has(p):
            v29_bypass_cells.append(p)
    v29_intervention_count += 1
    v23_alert_text = "新しい道へ交通が流れ始めています"
    _v29_observe_traffic_state()
    queue_redraw()

func _v29_begin_recovery() -> void:
    v29_recovery_stage = V29_STAGE_RECOVERY
    v29_recovery_started_at = v04_time
    v29_recovery_congestion = congestion
    v29_recovery_count += 1
    v23_alert_text = "交通が分散しました"
    queue_redraw()

func _auto_grow_buildings() -> void:
    var before_count: int = _v29_building_count()
    super._auto_grow_buildings()
    _v29_note_growth_resume(before_count)

func _v29_note_growth_resume(before_count: int) -> void:
    if v29_recovery_stage != V29_STAGE_RECOVERY:
        return
    if _v29_building_count() <= before_count:
        return
    v29_recovery_stage = V29_STAGE_RESUMED
    v29_final_started_at = v04_time
    v29_growth_resume_count += 1
    v29_completion_count += 1
    v23_alert_text = "道一本で街の流れが変わった"
    queue_redraw()

func _v29_building_count() -> int:
    return _count_cells(Cell.RESIDENTIAL) + _count_cells(Cell.COMMERCIAL) + _count_cells(Cell.INDUSTRIAL)

func _v29_find_worst_arterial() -> Vector2i:
    var worst: Vector2i = Vector2i(-1, -1)
    var worst_ratio: float = -1.0
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            if int(grid[y][x]) != Cell.ARTERIAL:
                continue
            var ratio: float = _road_load(p) / maxf(0.1, _road_capacity(p))
            if ratio > worst_ratio:
                worst_ratio = ratio
                worst = p
    return worst

func _v29_find_hotspot_cells(limit: int) -> Array[Vector2i]:
    var roads: Array[Vector2i] = []
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) == Cell.ARTERIAL:
                roads.append(Vector2i(x, y))
    roads.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var ra: float = _road_load(a) / maxf(0.1, _road_capacity(a))
        var rb: float = _road_load(b) / maxf(0.1, _road_capacity(b))
        if is_equal_approx(ra, rb):
            return (a.y * GRID_W + a.x) < (b.y * GRID_W + b.x)
        return ra > rb
    )
    var result: Array[Vector2i] = []
    for i: int in range(mini(limit, roads.size())):
        result.append(roads[i])
    return result

func _v23_context_message() -> String:
    if not v28_sequence_active:
        match v29_recovery_stage:
            V29_STAGE_PROBLEM:
                return "この道に交通が集中しています"
            V29_STAGE_INTERVENTION:
                return "新しい道へ交通が分散中"
            V29_STAGE_RECOVERY:
                return "交通が分散し、街が動き始めました"
            V29_STAGE_RESUMED:
                return "道一本で街の流れが変わった"
    return super._v23_context_message()

func _v10_draw_projected_effects() -> void:
    super._v10_draw_projected_effects()
    _v29_draw_congestion_hotspot()
    _v29_draw_bypass_flow()
    _v29_draw_recovery_callout()

func _v29_draw_congestion_hotspot() -> void:
    if v29_recovery_stage not in [V29_STAGE_PROBLEM, V29_STAGE_INTERVENTION]:
        return
    if v29_hotspot_cells.is_empty():
        return
    var pulse: float = 0.5 + 0.5 * sin(v04_time * 4.2)
    var color: Color = Color(0.93, 0.31, 0.20, 0.22 + pulse * 0.18)
    if v29_recovery_stage == V29_STAGE_INTERVENTION:
        color = Color(0.93, 0.64, 0.20, 0.18 + pulse * 0.14)
    for p: Vector2i in v29_hotspot_cells:
        var screen: Vector2 = _v27_project_cell(p, 0.14)
        if screen.x < -100.0:
            continue
        draw_circle(screen, 8.0 + pulse * 4.0, color, false, 2.2)

func _v29_draw_bypass_flow() -> void:
    if v29_recovery_stage not in [V29_STAGE_INTERVENTION, V29_STAGE_RECOVERY, V29_STAGE_RESUMED]:
        return
    if v29_bypass_cells.is_empty():
        return

    var glow_alpha: float = 0.34
    if v29_recovery_stage == V29_STAGE_RECOVERY:
        glow_alpha = 0.52
    elif v29_recovery_stage == V29_STAGE_RESUMED:
        glow_alpha = 0.42

    var points: Array[Vector2] = []
    for p: Vector2i in v29_bypass_cells:
        var screen: Vector2 = _v27_project_cell(p, 0.16)
        if screen.x < -100.0:
            continue
        points.append(screen)
        draw_circle(screen, 6.0, Color(0.31, 0.86, 0.67, glow_alpha), false, 1.6)

    for i: int in range(points.size() - 1):
        var a: Vector2 = points[i]
        var b: Vector2 = points[i + 1]
        if a.distance_to(b) > 90.0:
            continue
        draw_line(a, b, Color(0.31, 0.86, 0.67, glow_alpha * 0.62), 2.0)

    if points.size() < 2:
        return
    for marker: int in range(4):
        var phase: float = fmod(v04_time * 0.48 + float(marker) * 0.23, 1.0)
        var segment_f: float = phase * float(points.size() - 1)
        var segment: int = clampi(int(floor(segment_f)), 0, points.size() - 2)
        var local_t: float = segment_f - float(segment)
        var pos: Vector2 = points[segment].lerp(points[segment + 1], local_t)
        draw_circle(pos, 2.6, Color(0.90, 1.0, 0.93, 0.88))

func _v29_draw_recovery_callout() -> void:
    if v29_recovery_stage not in [V29_STAGE_RECOVERY, V29_STAGE_RESUMED]:
        return
    var anchor: Vector2i = v29_bypass_cells[int(v29_bypass_cells.size() / 2)] if not v29_bypass_cells.is_empty() else v29_problem_anchor
    if anchor.x < 0:
        return
    var screen: Vector2 = _v27_project_cell(anchor, 0.45)
    if screen.x < -100.0:
        return

    var started: float = v29_recovery_started_at if v29_recovery_stage == V29_STAGE_RECOVERY else v29_final_started_at
    var age: float = v04_time - started
    if age < 0.0 or age > 2.60:
        return
    var alpha: float = minf(1.0, age / 0.18) * minf(1.0, (2.60 - age) / 0.36)
    var text: String = "交通が分散" if v29_recovery_stage == V29_STAGE_RECOVERY else "街の流れが変わった"
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var width: float = 130.0 if v29_recovery_stage == V29_STAGE_RECOVERY else 168.0
    var pill: Rect2 = Rect2(screen.x - width * 0.5, screen.y - 46.0, width, 26.0)
    draw_rect(pill, Color(0.055, 0.16, 0.115, 0.88 * alpha))
    draw_string(font, pill.position + Vector2(6.0, 18.0), text, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 12.0, 9, Color(0.97, 1.0, 0.97, alpha))
