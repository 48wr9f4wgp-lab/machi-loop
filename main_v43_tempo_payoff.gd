extends "res://main_v42_playable_loop.gd"

# AXIVA v0.43 — Tempo & Payoff pass.
# Preserve the fast first 15 seconds and road-caused response, but slow passive
# background growth so the player has time to read the city and choose the next
# arterial. Structural pressure is not allowed to become the authored problem
# before two minutes. Recovery gets a short payoff window before growth resumes.
#
# Working Vertical Slice tuning only. No save-schema or release changes.

const V43_GRACE_TICKS: int = 18
const V43_BUILDING_INTERVAL: int = 3
const V43_LOCAL_ROAD_INTERVAL: int = 2
const V43_MIN_PROBLEM_TICKS: int = 142
const V43_MAX_PROBLEM_TICKS: int = 300
const V43_RECOVERY_RESTART_TICKS: int = 4
const V43_RECOVERY_CALLOUT_SECONDS: float = 3.6

var v43_first_road_tick: int = -1
var v43_recovery_tick: int = -1
var v43_recovery_started_at: float = -1000.0
var v43_recovery_from: float = 0.0
var v43_recovery_to: float = 0.0
var v43_last_recovery_drop: float = 0.0

func _v42_build_label() -> String:
    return "v0.43"

func _commit_arterial() -> void:
    var first_before: bool = _count_cells(Cell.ARTERIAL) == 0
    var before_commits: int = v40_commit_count
    super._commit_arterial()

    if first_before and v40_commit_count > before_commits:
        v43_first_road_tick = tick_count

    # A recovery can begin inside the inherited commit and v0.42 may then
    # refresh its response queue. Re-apply the payoff delay at the outer edge.
    _v43_enforce_recovery_delay()

func _v43_city_age_ticks() -> int:
    if _all_road_cells().is_empty():
        return 0
    if v43_first_road_tick >= 0:
        return maxi(0, tick_count - v43_first_road_tick)
    # tick_count is persisted, so old saves still use the slower background
    # cadence without adding a save field solely for presentation timing.
    return maxi(0, tick_count)

func _v43_background_slot(interval: int) -> bool:
    var age: int = _v43_city_age_ticks()
    if age < V43_GRACE_TICKS:
        return true
    return ((age - V43_GRACE_TICKS) % maxi(1, interval)) == 0

func _auto_generate_local_roads() -> void:
    if not _v43_background_slot(V43_LOCAL_ROAD_INTERVAL):
        return
    super._auto_generate_local_roads()

func _auto_grow_buildings() -> void:
    # During recovery, keep the visual cause-and-effect readable. v0.42's
    # route-attributed response resumes growth after the payoff beat. If no
    # attributed candidate exists, normal growth becomes available afterwards.
    if v29_recovery_stage == V29_STAGE_RECOVERY:
        var since_recovery: int = tick_count - v43_recovery_tick
        if since_recovery < V43_RECOVERY_RESTART_TICKS:
            return
        if not v42_arrivals.is_empty():
            return

    if not _v43_background_slot(V43_BUILDING_INTERVAL):
        return
    super._auto_grow_buildings()

func _v29_should_begin_problem() -> bool:
    if _v43_city_age_ticks() < V43_MIN_PROBLEM_TICKS:
        return false
    return super._v29_should_begin_problem()

func _v29_begin_recovery() -> void:
    var from_pressure: float = v29_problem_congestion
    super._v29_begin_recovery()

    v43_recovery_tick = tick_count
    v43_recovery_started_at = v04_time
    v43_recovery_from = from_pressure
    v43_recovery_to = congestion
    v43_last_recovery_drop = maxf(0.0, v43_recovery_from - v43_recovery_to)
    _v43_enforce_recovery_delay()

func _v43_enforce_recovery_delay() -> void:
    if v29_recovery_stage != V29_STAGE_RECOVERY or v43_recovery_tick < 0:
        return
    # v0.42 releases an attributed response when tick - arrival_tick >= 2.
    # Moving the reference two ticks forward yields a four-tick (~3.4 s) payoff
    # window before the first recovery growth response.
    v42_arrival_tick = maxi(v42_arrival_tick, v43_recovery_tick + 2)

func _v23_context_message() -> String:
    if (
        current_tool == Tool.ROAD
        and v42_pending_path.is_empty()
        and not v28_sequence_active
        and v29_recovery_stage == V29_STAGE_NONE
        and _v43_city_age_ticks() >= V43_GRACE_TICKS
    ):
        return "街は新しい道に反応します・次の一本を考えよう"
    return super._v23_context_message()

func _draw() -> void:
    super._draw()
    _v43_draw_recovery_payoff()

func _v43_draw_recovery_payoff() -> void:
    if v43_recovery_tick < 0:
        return
    var age: float = v04_time - v43_recovery_started_at
    if age < 0.0 or age > V43_RECOVERY_CALLOUT_SECONDS:
        return

    var alpha: float = minf(1.0, age / 0.18)
    alpha *= minf(1.0, (V43_RECOVERY_CALLOUT_SECONDS - age) / 0.42)

    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var w: float = minf(286.0, board_rect.size.x - 28.0)
    var rect: Rect2 = Rect2(
        board_rect.get_center().x - w * 0.5,
        _v41_world_area().position.y + 12.0,
        w,
        44.0
    )
    draw_rect(rect, Color(0.045, 0.16, 0.105, 0.94 * alpha))
    draw_rect(rect, Color(0.38, 0.88, 0.64, 0.95 * alpha), false, 2.0)

    var text: String = "交通 %d%% → %d%%・%dpt改善" % [
        int(round(v43_recovery_from)),
        int(round(v43_recovery_to)),
        int(round(v43_last_recovery_drop))
    ]
    draw_string(
        font,
        rect.position + Vector2(8.0, 28.0),
        text,
        HORIZONTAL_ALIGNMENT_CENTER,
        rect.size.x - 16.0,
        13,
        Color(0.97, 1.0, 0.97, alpha)
    )

func _v10_draw_projected_effects() -> void:
    super._v10_draw_projected_effects()
    _v43_draw_pressure_readability()

func _v43_draw_pressure_readability() -> void:
    if _all_road_cells().is_empty():
        return
    if v29_recovery_stage in [V29_STAGE_RECOVERY, V29_STAGE_RESUMED]:
        return
    if v16_traffic_status not in ["warning", "severe"]:
        return

    var hotspots: Array[Vector2i] = []
    if not v29_hotspot_cells.is_empty():
        for p: Vector2i in v29_hotspot_cells:
            hotspots.append(p)
    else:
        hotspots = _v29_find_hotspot_cells(3)

    var severe: bool = v16_traffic_status == "severe"
    var pulse: float = 0.5 + 0.5 * sin(v04_time * (4.6 if severe else 2.8))
    var ring: Color = (
        Color(0.94, 0.29, 0.18, 0.44 + pulse * 0.20)
        if severe
        else Color(0.92, 0.63, 0.18, 0.30 + pulse * 0.14)
    )
    var queue_color: Color = (
        Color(0.96, 0.38, 0.22, 0.92)
        if severe
        else Color(0.94, 0.72, 0.30, 0.80)
    )

    var count: int = mini(3, hotspots.size())
    for i: int in range(count):
        var screen: Vector2 = _v27_project_cell(hotspots[i], 0.22)
        if not _v41_world_area().has_point(screen):
            continue

        draw_circle(screen, 10.0 + pulse * 4.0, ring, false, 2.4 if severe else 1.8)

        # A compact queue silhouette makes congestion visible before the copy is
        # read. These are diagnostic overlays, not additional simulation cars.
        if severe:
            for car_index: int in range(3):
                var offset: Vector2 = Vector2(float(car_index - 1) * 7.0, 8.0 + float(i % 2) * 3.0)
                draw_rect(
                    Rect2(screen + offset - Vector2(2.7, 1.7), Vector2(5.4, 3.4)),
                    queue_color
                )
