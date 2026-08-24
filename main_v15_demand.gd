extends "res://main_v14_polish.gd"

# MACHI LOOP v0.15 — Functional Build FB-1: explicit city demand.
# Demand is derived domain state (0–100), not persisted. It drives both growth rate and building mix.

const DemandModel = preload("res://domain/demand_model.gd")

var v15_residential_demand: int = 0
var v15_commercial_demand: int = 0
var v15_industrial_demand: int = 0

func _ready() -> void:
    super._ready()
    _v15_update_demand()
    queue_redraw()

func _draw() -> void:
    super._draw()
    if not v09_policy_panel_open and not _all_road_cells().is_empty():
        _v15_draw_demand_panel()

func _recalculate_city() -> void:
    super._recalculate_city()
    _v15_update_demand()

func _v15_update_demand() -> void:
    var demand: Dictionary = DemandModel.calculate(
        population,
        jobs,
        happiness,
        congestion,
        _count_cells(Cell.RESIDENTIAL),
        _count_cells(Cell.COMMERCIAL),
        _count_cells(Cell.INDUSTRIAL)
    )
    v15_residential_demand = int(demand.get("residential", 0))
    v15_commercial_demand = int(demand.get("commercial", 0))
    v15_industrial_demand = int(demand.get("industrial", 0))

func _auto_grow_buildings() -> void:
    if _all_road_cells().is_empty():
        return

    var highest_demand: int = maxi(v15_residential_demand, maxi(v15_commercial_demand, v15_industrial_demand))
    var demand_factor: float = lerpf(0.38, 1.15, clampf(float(highest_demand) / 100.0, 0.0, 1.0))
    var traffic_factor: float = clampf(1.20 - congestion / 120.0, 0.18, 1.0)
    var growth_chance: float = clampf(0.48 * demand_factor * traffic_factor, 0.10, 0.64)
    if rng.randf() > growth_chance:
        return

    var candidates: Array = []
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            if int(grid[y][x]) == Cell.EMPTY and _adjacent_road_count(p) > 0:
                candidates.append(p)
    if candidates.is_empty():
        return

    var index: int = rng.randi_range(0, candidates.size() - 1)
    var p: Vector2i = candidates[index] as Vector2i
    grid[p.y][p.x] = _choose_building_type()

func _choose_building_type() -> int:
    var homes: int = _count_cells(Cell.RESIDENTIAL)
    if homes < 2:
        return Cell.RESIDENTIAL

    var residential_weight: float = maxf(4.0, float(v15_residential_demand))
    var commercial_weight: float = maxf(4.0, float(v15_commercial_demand))
    var industrial_weight: float = maxf(4.0, float(v15_industrial_demand))

    match v09_policy:
        V09Policy.HOMES:
            residential_weight *= 1.35
            commercial_weight *= 0.88
            industrial_weight *= 0.88
        V09Policy.JOBS:
            residential_weight *= 0.88
            commercial_weight *= 1.22
            industrial_weight *= 1.22
        V09Policy.FLOW:
            # FLOW affects demand indirectly through road capacity/congestion.
            pass

    var total: float = residential_weight + commercial_weight + industrial_weight
    var roll: float = rng.randf() * total
    if roll < residential_weight:
        return Cell.RESIDENTIAL
    roll -= residential_weight
    if roll < commercial_weight:
        return Cell.COMMERCIAL
    return Cell.INDUSTRIAL

func _v15_draw_demand_panel() -> void:
    var rect: Rect2 = Rect2(board_rect.position.x + 8.0, board_rect.position.y + 62.0, 156.0, 43.0)
    draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.03, 0.08, 0.06, 0.12))
    draw_rect(rect, Color(0.055, 0.14, 0.105, 0.94))
    draw_rect(rect, Color("#456D5B"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(8.0, 12.0), "都市需要", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 7, Color("#8FBCA5"))
    draw_string(
        v11_font,
        rect.position + Vector2(8.0, 29.0),
        "住 %d   商 %d   工 %d" % [v15_residential_demand, v15_commercial_demand, v15_industrial_demand],
        HORIZONTAL_ALIGNMENT_LEFT,
        rect.size.x - 16.0,
        9,
        Color("#F3FFF7")
    )

    var bar_y: float = rect.end.y - 6.0
    var gap: float = 4.0
    var bar_w: float = (rect.size.x - 16.0 - gap * 2.0) / 3.0
    var values: Array[int] = [v15_residential_demand, v15_commercial_demand, v15_industrial_demand]
    var colors: Array[Color] = [Color("#74C98A"), Color("#65AFD0"), Color("#D2A65C")]
    for i: int in range(3):
        var x: float = rect.position.x + 8.0 + float(i) * (bar_w + gap)
        draw_rect(Rect2(x, bar_y, bar_w, 2.0), Color("#29463A"))
        draw_rect(Rect2(x, bar_y, bar_w * clampf(float(values[i]) / 100.0, 0.0, 1.0), 2.0), colors[i])
