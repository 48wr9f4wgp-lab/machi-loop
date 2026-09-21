extends RefCounted

# Pure, bounded ZERO C experiment model. Cell IDs match main_mobile.Cell.
# Arterials form the strategic graph; local roads only feed accessible parcels.
const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const ANCHORS: Array[Vector2i] = [Vector2i(1, 5), Vector2i(14, 8), Vector2i(10, 20)]
const KINDS: Array[int] = [3, 4, 5]
const LARGE_CITY: int = 40
const EDGE_CAPACITY: float = 1.55
const STABLE_TICKS: int = 12

static func path(roads: Dictionary, start: Vector2i, goal: Vector2i, blocked: Dictionary = {}) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not roads.has(start) or not roads.has(goal):
        return result
    var queue: Array[Vector2i] = [start]
    var parent: Dictionary = {start: start}
    var cursor: int = 0
    while cursor < queue.size():
        var p: Vector2i = queue[cursor]
        cursor += 1
        if p == goal:
            while p != start:
                result.push_front(p)
                p = parent[p]
            result.push_front(start)
            return result
        for d: Vector2i in DIRS:
            var q: Vector2i = p + d
            if roads.has(q) and not parent.has(q) and not blocked.has(q):
                parent[q] = p
                queue.append(q)
    return result

static func flood(roads: Dictionary, seeds: Array) -> Dictionary:
    var visited: Dictionary = {}
    var queue: Array[Vector2i] = []
    for value: Variant in seeds:
        var p: Vector2i = value
        if roads.has(p) and not visited.has(p):
            visited[p] = true
            queue.append(p)
    var cursor: int = 0
    while cursor < queue.size():
        var p: Vector2i = queue[cursor]
        cursor += 1
        for d: Vector2i in DIRS:
            var q: Vector2i = p + d
            if roads.has(q) and not visited.has(q):
                visited[q] = true
                queue.append(q)
    return visited

static func edge_key(a: Vector2i, b: Vector2i) -> String:
    var aa: String = "%d:%d" % [a.x, a.y]
    var bb: String = "%d:%d" % [b.x, b.y]
    return aa + "/" + bb if aa < bb else bb + "/" + aa

static func alternate(roads: Dictionary, primary: Array[Vector2i]) -> Array[Vector2i]:
    var empty: Array[Vector2i] = []
    if primary.size() < 9:
        return empty
    # Prefer fully independent approaches. Only fall back to short terminal
    # stubs when necessary; shared approach load still counts against capacity.
    var blocked: Dictionary = {}
    for i: int in range(1, primary.size() - 1):
        blocked[primary[i]] = true
    var candidate: Array[Vector2i] = path(roads, primary[0], primary[-1], blocked)
    if candidate.is_empty():
        blocked.clear()
        for i: int in range(3, primary.size() - 3):
            blocked[primary[i]] = true
        candidate = path(roads, primary[0], primary[-1], blocked)
    if candidate.is_empty() or candidate.size() > primary.size() * 2 + 8:
        return empty
    var separation: int = 0
    for p: Vector2i in candidate:
        var nearest: int = 1000
        for q: Vector2i in primary:
            nearest = mini(nearest, absi(p.x - q.x) + absi(p.y - q.y))
        separation = maxi(separation, nearest)
    return candidate if separation >= 2 else empty

static func directed_path(graph: Dictionary, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
    var queue: Array[Vector2i] = [start]
    var parent: Dictionary = {start: start}
    var cursor: int = 0
    while cursor < queue.size():
        var p: Vector2i = queue[cursor]
        cursor += 1
        if p == goal:
            var route: Array[Vector2i] = [p]
            while p != start:
                p = parent[p]
                route.push_front(p)
            return route
        for value: Variant in graph.get(p, {}):
            var q: Vector2i = value
            if int(graph[p][q]) > 0 and not parent.has(q):
                parent[q] = p
                queue.append(q)
    return []

static func route_pair(roads: Dictionary, start: Vector2i, goal: Vector2i) -> Array:
    var primary: Array[Vector2i] = path(roads, start, goal)
    if primary.size() < 9:
        return [primary]
    # Two-unit residual flow can undo the first shortest path. Merely blocking
    # that path falsely rejects a ring when its shortest route uses a chord.
    var residual: Dictionary = {}
    for value: Variant in roads:
        var p: Vector2i = value
        residual[p] = {}
        for d: Vector2i in DIRS:
            if roads.has(p + d):
                residual[p][p + d] = 1
    for unit: int in range(2):
        var augment: Array[Vector2i] = directed_path(residual, start, goal)
        if augment.is_empty():
            var secondary: Array[Vector2i] = alternate(roads, primary)
            return [primary] if secondary.is_empty() else [primary, secondary]
        for i: int in range(augment.size() - 1):
            residual[augment[i]][augment[i + 1]] -= 1
            residual[augment[i + 1]][augment[i]] += 1
    var flow: Dictionary = {}
    for p: Vector2i in residual:
        flow[p] = {}
        for q: Vector2i in residual[p]:
            flow[p][q] = maxi(0, 1 - int(residual[p][q]))
    var result: Array = []
    for unit: int in range(2):
        var route: Array[Vector2i] = directed_path(flow, start, goal)
        if route.is_empty() or route.size() > primary.size() * 2 + 8:
            return [primary]
        result.append(route)
        for i: int in range(route.size() - 1):
            flow[route[i]][route[i + 1]] -= 1
    var separation: int = 0
    for p: Vector2i in result[1]:
        var nearest: int = 1000
        for q: Vector2i in result[0]:
            nearest = mini(nearest, absi(p.x - q.x) + absi(p.y - q.y))
        separation = maxi(separation, nearest)
    return result if separation >= 2 else [primary]

static func analyze(grid: Array) -> Dictionary:
    var arterials: Dictionary = {}
    var roads: Dictionary = {}
    for y: int in range(grid.size()):
        for x: int in range(grid[y].size()):
            var kind: int = int(grid[y][x])
            var p: Vector2i = Vector2i(x, y)
            if kind in [1, 2]:
                roads[p] = true
            if kind == 1:
                arterials[p] = true
    # Largest connected arterial network; deterministic ties use grid order.
    var main: Dictionary = {}
    var visited: Dictionary = {}
    for value: Variant in arterials:
        var p: Vector2i = value
        if visited.has(p):
            continue
        var component: Dictionary = flood(arterials, [p])
        visited.merge(component)
        if component.size() > main.size():
            main = component
    var accessible: Dictionary = flood(roads, main.keys())
    var ports: Array[Vector2i] = []
    var connected: int = 0
    for anchor: Vector2i in ANCHORS:
        var port: Vector2i = Vector2i(-1, -1)
        for d: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            if main.has(anchor + d):
                port = anchor + d
                break
        ports.append(port)
        if port.x >= 0:
            connected += 1
    var buildings: Dictionary = {}
    var districts: Array[int] = [0, 0, 0]
    for y: int in range(grid.size()):
        for x: int in range(grid[y].size()):
            var kind: int = int(grid[y][x])
            if kind < 3 or kind > 5:
                continue
            var p: Vector2i = Vector2i(x, y)
            var reached: bool = false
            for d: Vector2i in DIRS:
                reached = reached or accessible.has(p + d)
            if not reached:
                continue
            buildings[p] = kind
            for i: int in range(3):
                var anchor: Vector2i = ANCHORS[i]
                if ports[i].x >= 0 and kind == KINDS[i] and absi(p.x - anchor.x) + absi(p.y - anchor.y) <= 5:
                    districts[i] += 1
    var routes: Array = []
    var loads: Dictionary = {}
    var edge_cells: Dictionary = {}
    var redundant_pairs: int = 0
    for i: int in range(3):
        for j: int in range(i + 1, 3):
            if ports[i].x < 0 or ports[j].x < 0:
                continue
            var pair_routes: Array = route_pair(main, ports[i], ports[j])
            if pair_routes.size() == 2:
                redundant_pairs += 1
            # Bounded trip demand grows with actual functional district activity.
            var demand: float = clampf(0.35 + float(districts[i] + districts[j]) * 0.065, 0.35, 1.0)
            for route: Array[Vector2i] in pair_routes:
                routes.append(route)
                for k: int in range(route.size() - 1):
                    var edge: String = edge_key(route[k], route[k + 1])
                    loads[edge] = float(loads.get(edge, 0.0)) + demand / pair_routes.size()
                    edge_cells[edge] = [route[k], route[k + 1]]
    var peak: float = 0.0
    var hotspots: Dictionary = {}
    for edge: String in loads:
        var ratio: float = float(loads[edge]) / EDGE_CAPACITY
        peak = maxf(peak, ratio)
        if ratio > 1.0:
            for p: Vector2i in edge_cells[edge]:
                hotspots[p] = true
    var centers: int = 0
    for count: int in districts:
        if count >= 4:
            centers += 1
    var ready: bool = connected == 3 and centers >= 2 and redundant_pairs >= 2 and peak <= 1.0
    return {"main": main, "accessible": accessible, "ports": ports,
        "connected": connected, "buildings": buildings, "districts": districts,
        "centers": centers, "routes": routes, "loads": loads, "peak": peak,
        "hotspots": hotspots, "redundant_pairs": redundant_pairs, "ready": ready}

static func stage(buildings: int, metropolis: bool) -> int:
    if metropolis:
        return 5
    if buildings >= LARGE_CITY:
        return 4
    if buildings >= 24:
        return 3
    if buildings >= 14:
        return 2
    if buildings >= 6:
        return 1
    return 0
