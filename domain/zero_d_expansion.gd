extends RefCounted

const Graph = preload("res://domain/zero_c_network.gd")
const SIZE: Vector2i = Vector2i(32, 44)
const HOME: Vector2i = Vector2i(8, 22)
const REGION_LIMIT: int = 32
const ANCHORS: Array[Vector2i] = [Vector2i(8,20), Vector2i(18,12), Vector2i(18,28), Vector2i(27,5), Vector2i(27,38), Vector2i(5,36)]
const KINDS: Array[int] = [3, 4, 5, 4, 5, 3]
const NAMES: Array[String] = ["中心街", "駅前", "物流地区", "新駅前", "産業地区", "郊外住宅地"]

static func region_at(p: Vector2i) -> int:
    var best: int = 0
    var distance: int = 100000
    for i: int in range(ANCHORS.size()):
        var delta: Vector2i = p - ANCHORS[i]
        var score: int = absi(delta.x) + absi(delta.y)
        if score < distance:
            best = i
            distance = score
    return best

static func analyze(grid: Array) -> Dictionary:
    var roads: Dictionary = {}
    for y: int in range(grid.size()):
        for x: int in range(grid[y].size()):
            if int(grid[y][x]) in [1, 2]:
                roads[Vector2i(x,y)] = true
    # Connectivity is rooted in the original settlement, not whichever isolated
    # fragment happens to be largest. Erasing the root can always be repaired.
    var connected: Dictionary = Graph.flood(roads, [HOME])
    var counts: Array[int] = [0,0,0,0,0,0]
    var candidates: Array = [[],[],[],[],[],[]]
    var buildings: Dictionary = {}
    var seen: Dictionary = {}
    for p: Vector2i in connected:
        for d: Vector2i in Graph.DIRS:
            var q: Vector2i = p + d
            if q.y < 0 or q.y >= grid.size() or q.x < 0 or q.x >= grid[q.y].size() or seen.has(q):
                continue
            seen[q] = true
            var kind: int = int(grid[q.y][q.x])
            var region: int = region_at(q)
            if kind == 0:
                candidates[region].append(q)
            elif kind in [3,4,5]:
                buildings[q] = kind
    # Count occupied parcels even when temporarily disconnected. This keeps
    # reconnecting districts from bypassing the bounded render/growth budget.
    for y: int in range(grid.size()):
        for x: int in range(grid[y].size()):
            if int(grid[y][x]) in [3,4,5]:
                counts[region_at(Vector2i(x,y))] += 1
    var reached: Array[bool] = []
    for anchor: Vector2i in ANCHORS:
        var near: bool = connected.has(anchor)
        for d: Vector2i in Graph.DIRS:
            near = near or connected.has(anchor + d)
        reached.append(near)
    return {"connected":connected, "counts":counts, "candidates":candidates,
        "buildings":buildings, "reached":reached}

static func growth_choice(state: Dictionary, preferred: int) -> Vector2i:
    var order: Array[int] = []
    if preferred >= 0 and preferred < ANCHORS.size():
        order.append(preferred)
    for i: int in range(ANCHORS.size()):
        if not order.has(i):
            order.append(i)
    for i: int in order:
        if int(state["counts"][i]) >= REGION_LIMIT:
            continue
        var best: Vector2i = Vector2i(-1,-1)
        var distance: int = 100000
        for p: Vector2i in state["candidates"][i]:
            var delta: Vector2i = p - ANCHORS[i]
            var score: int = absi(delta.x) + absi(delta.y)
            if score < distance:
                best = p
                distance = score
        if best.x >= 0:
            return best
    return Vector2i(-1,-1)

static func opened_region(before: Dictionary, after: Dictionary, fallback: int) -> int:
    # Compare newly reachable frontage, not gesture direction. Drawing the same
    # connection backwards must produce the same growth focus and explanation.
    var best: int = fallback
    var most: int = 0
    for i: int in range(ANCHORS.size()):
        var old: Array = before.get("candidates", [[],[],[],[],[],[]])[i]
        var gained: int = 0
        for p: Vector2i in after["candidates"][i]:
            if not old.has(p):
                gained += 1
        if gained > most:
            best = i
            most = gained
    return best
