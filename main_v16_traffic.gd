extends "res://main_v15_demand.gd"

# MACHI LOOP v0.16 — Functional Build FB-2: strategic traffic pressure & recovery.
# Traffic now reacts to road-network structure as well as nominal capacity.

const TrafficModel = preload("res://domain/traffic_model.gd")

var v16_network_factor: float = 1.0
var v16_effective_capacity: float = 0.0
var v16_components: int = 0
var v16_dead_ends: int = 0
var v16_intersections: int = 0
var v16_cycles: int = 0
var v16_traffic_status: String = "none"
var v16_traffic_cause: String = "none"

func _draw() -> void:
    super._draw()
    if not v09_policy_panel_open and not _all_road_cells().is_empty():
        _v16_draw_traffic_diagnosis()

func _recalculate_city() -> void:
    var homes: int = _count_cells(Cell.RESIDENTIAL)
    var commerce: int = _count_cells(Cell.COMMERCIAL)
    var industry: int = _count_cells(Cell.INDUSTRIAL)
    population = homes * 13
    jobs = commerce * 8 + industry * 11

    var metrics: Dictionary = _v16_network_metrics()
    var traffic: Dictionary = TrafficModel.calculate(
        population,
        jobs,
        float(metrics["raw_capacity"]),
        int(metrics["road_count"]),
        int(metrics["arterial_count"]),
        int(metrics["widened_count"]),
        int(metrics["intersections"]),
        int(metrics["dead_ends"]),
        int(metrics["components"]),
        int(metrics["cycles"])
    )

    congestion = float(traffic["congestion"])
    v16_network_factor = float(traffic["network_factor"])
    v16_effective_capacity = float(traffic["effective_capacity"])
    v16_components = int(metrics["components"])
    v16_dead_ends = int(metrics["dead_ends"])
    v16_intersections = int(metrics["intersections"])
    v16_cycles = int(metrics["cycles"])
    v16_traffic_status = str(traffic["status"])
    v16_traffic_cause = str(traffic["cause"])

    var job_ratio: float = minf(1.0, float(jobs + 10) / float(maxi(population, 1)))
    happiness = int(clampf(100.0 - maxf(0.0, congestion - 45.0) * 0.62 - absf(0.72 - job_ratio) * 22.0, 35.0, 100.0))
    if v16_components > 1:
        happiness = maxi(35, happiness - mini(8, (v16_components - 1) * 2))

    tax_income = int(population * 0.08 + jobs * 0.05)
    match v09_policy:
        V09Policy.HOMES:
            happiness = mini(100, happiness + 5)
            tax_income = maxi(0, int(round(float(tax_income) * 0.92)))
        V09Policy.JOBS:
            happiness = maxi(35, happiness - 4)
            tax_income = maxi(0, int(round(float(tax_income) * 1.25)))
        V09Policy.FLOW:
            happiness = mini(100, happiness + 2)
            tax_income = maxi(0, int(round(float(tax_income) * 0.90)))

    tax_income = maxi(0, int(round(float(tax_income) * float(traffic["income_multiplier"]))))
    _v15_update_demand()

func _v16_network_metrics() -> Dictionary:
    var roads: Array = _all_road_cells()
    if roads.is_empty():
        return {
            "raw_capacity": 0.0,
            "road_count": 0,
            "arterial_count": 0,
            "widened_count": 0,
            "intersections": 0,
            "dead_ends": 0,
            "components": 0,
            "cycles": 0
        }

    var road_lookup: Dictionary = {}
    var raw_capacity: float = 0.0
    var arterial_count: int = 0
    var widened_count: int = 0
    for item: Variant in roads:
        var p: Vector2i = item as Vector2i
        road_lookup[_key(p)] = true
        raw_capacity += _road_capacity(p)
        if int(grid[p.y][p.x]) == Cell.ARTERIAL:
            arterial_count += 1
            if widened.has(_key(p)):
                widened_count += 1

    var intersections: int = 0
    var dead_ends: int = 0
    var degree_sum: int = 0
    for item: Variant in roads:
        var p: Vector2i = item as Vector2i
        var degree: int = 0
        for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            if road_lookup.has(_key(p + d)):
                degree += 1
        degree_sum += degree
        if degree >= 3:
            intersections += 1
        elif degree <= 1:
            dead_ends += 1

    var components: int = 0
    var visited: Dictionary = {}
    for item: Variant in roads:
        var start: Vector2i = item as Vector2i
        var start_key: String = _key(start)
        if visited.has(start_key):
            continue
        components += 1
        var queue: Array = [start]
        visited[start_key] = true
        var cursor: int = 0
        while cursor < queue.size():
            var current: Vector2i = queue[cursor] as Vector2i
            cursor += 1
            for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
                var next: Vector2i = current + d
                var next_key: String = _key(next)
                if road_lookup.has(next_key) and not visited.has(next_key):
                    visited[next_key] = true
                    queue.append(next)

    var edge_count: int = int(degree_sum / 2)
    var cycle_count: int = maxi(0, edge_count - roads.size() + components)
    return {
        "raw_capacity": raw_capacity,
        "road_count": roads.size(),
        "arterial_count": arterial_count,
        "widened_count": widened_count,
        "intersections": intersections,
        "dead_ends": dead_ends,
        "components": components,
        "cycles": cycle_count
    }

func _v16_draw_traffic_diagnosis() -> void:
    var rect: Rect2 = Rect2(board_rect.position.x + 8.0, board_rect.position.y + 110.0, 174.0, 49.0)
    var border: Color = Color("#4F8069")
    if v16_traffic_status == "warning":
        border = Color("#D0A655")
    elif v16_traffic_status == "severe":
        border = Color("#D86B55")

    draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.03, 0.08, 0.06, 0.12))
    draw_rect(rect, Color(0.055, 0.14, 0.105, 0.94))
    draw_rect(rect, border, false, 1.0)
    draw_string(v11_font, rect.position + Vector2(8.0, 12.0), "交通診断", HORIZONTAL_ALIGNMENT_LEFT, 62.0, 7, Color("#8FBCA5"))
    draw_string(v11_font, rect.position + Vector2(72.0, 12.0), _v16_status_text(), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 80.0, 8, border)
    draw_string(v11_font, rect.position + Vector2(8.0, 29.0), _v16_cause_text(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 8, Color("#F3FFF7"))
    draw_string(v11_font, rect.position + Vector2(8.0, 42.0), _v16_recovery_text(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 7, Color("#B9DDCB"))

func _v16_status_text() -> String:
    match v16_traffic_status:
        "severe":
            return "混雑"
        "warning":
            return "注意"
        _:
            return "良好"

func _v16_cause_text() -> String:
    match v16_traffic_cause:
        "disconnected":
            return "原因：道路網が分断"
        "dead_ends":
            return "原因：行き止まりが多い"
        "no_redundancy":
            return "原因：迂回路が不足"
        "capacity":
            return "原因：道路容量が不足"
        _:
            return "道路網は安定"

func _v16_recovery_text() -> String:
    match v16_traffic_cause:
        "disconnected":
            return "幹線道路をつないで回復"
        "dead_ends":
            return "迂回路・ループを追加"
        "no_redundancy":
            return "別ルートを作って分散"
        "capacity":
            return "拡幅か新しい幹線道路"
        _:
            return "現在は大きな対策不要"
