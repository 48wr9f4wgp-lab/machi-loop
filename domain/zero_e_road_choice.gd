extends RefCounted

const Graph = preload("res://domain/zero_c_network.gd")
const WEST: Vector2i = Vector2i(3, 10)
const EAST: Vector2i = Vector2i(12, 10)
const CAPACITY: float = 1.20

static func analyze(grid: Array) -> Dictionary:
    var roads: Dictionary = {}
    var occupied: int = 0
    for y: int in range(grid.size()):
        for x: int in range(grid[y].size()):
            var kind: int = int(grid[y][x])
            if kind == 1:
                roads[Vector2i(x, y)] = true
            elif kind in [3, 4, 5]:
                occupied += 1
    var routes: Array = Graph.route_pair(roads, WEST, EAST)
    var demand: float = clampf(0.4 + occupied * 0.055, 1.6, 2.1)
    var loads: Dictionary = {}
    var edge_cells: Dictionary = {}
    for route: Array[Vector2i] in routes:
        for i: int in range(route.size() - 1):
            var key: String = Graph.edge_key(route[i], route[i + 1])
            loads[key] = float(loads.get(key, 0.0)) + demand / routes.size()
            edge_cells[key] = [route[i], route[i + 1]]
    var peak: float = 0.0
    var hotspots: Dictionary = {}
    for key: String in loads:
        var ratio: float = float(loads[key]) / CAPACITY
        peak = maxf(peak, ratio)
        if ratio > 1.0:
            for p: Vector2i in edge_cells[key]:
                hotspots[p] = true
    return {"routes": routes, "loads": loads, "peak": peak,
        "hotspots": hotspots, "occupied": occupied, "demand": demand}
