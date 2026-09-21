extends SceneTree
const Model = preload("res://domain/zero_c_network.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void:
    var grid: Array = empty_grid()
    # Three adjacent but disconnected fragments do not constitute a city.
    for p: Vector2i in Model.ANCHORS:
        grid[p.y][p.x] = 1
    require(int(Model.analyze(grid)["connected"]) == 1, "isolated destinations were counted together")
    grid = tree_grid()
    populate(grid)
    var tree: Dictionary = Model.analyze(grid)
    require(tree["buildings"].size() >= 40, "fixture has insufficient development")
    require(int(tree["connected"]) == 3, "tree failed actual connectivity")
    require(int(tree["centers"]) == 3, "functional districts not counted")
    require(float(tree["peak"]) > 1.0 and not bool(tree["ready"]), "mature single corridor did not congest")
    require(int(tree["redundant_pairs"]) == 0, "tree somehow has an alternate route")
    # Unrelated tiny loop at the end of a spur cannot satisfy redundancy.
    var ornament: Array = grid.duplicate(true)
    line(ornament, Vector2i(8, 12), Vector2i(11, 12))
    line(ornament, Vector2i(11, 12), Vector2i(12, 12))
    line(ornament, Vector2i(12, 12), Vector2i(12, 13))
    line(ornament, Vector2i(12, 13), Vector2i(11, 13))
    line(ornament, Vector2i(11, 13), Vector2i(11, 12))
    require(not bool(Model.analyze(ornament)["ready"]), "ornamental loop earned metropolis")
    # Two spatially different repairs: outer west/south loop, or north/east loop.
    for mode: int in [0, 1]:
        var repaired: Array = grid.duplicate(true)
        repair(repaired, mode)
        populate(repaired)
        var report: Dictionary = Model.analyze(repaired)
        print("ZERO_C_NETWORK repair=%d pairs=%d peak=%.2f centers=%d buildings=%d" % [mode, report["redundant_pairs"], report["peak"], report["centers"], report["buildings"].size()])
        require(bool(report["ready"]), "useful repair %d rejected" % mode)
        require(float(report["peak"]) < float(tree["peak"]), "repair did not redistribute trips")
        # Evaluate the same good network without any recorded failure history.
        require(bool(Model.analyze(repaired)["ready"]), "good planning requires failure history")
    var disconnected: Array = grid.duplicate(true)
    for y: int in range(10, 14):
        disconnected[y][8] = 0
    require(int(Model.analyze(disconnected)["connected"]) < 3, "deletion preserved a false connection")
    var empty_city: Array = tree_grid()
    repair(empty_city, 0)
    require(not bool(Model.analyze(empty_city)["ready"]), "bare roads counted as mature centers")
    require(Model.stage(999, false) == 4, "population alone bypassed metropolis gate")
    # Rapid blanket drawing leaves single-cell strips: more roads are not
    # equivalent to usable city blocks. Traffic can be good while land is poor.
    var dense: Array = empty_grid()
    for y: int in range(22):
        for x: int in range(16):
            if x % 2 == 0 or y % 2 == 0:
                dense[y][x] = 1
    populate(dense)
    var packed: Dictionary = Model.analyze(dense)
    require(int(packed["connected"]) == 3 and packed["buildings"].size() >= 40, "dense fixture lacks connected growth")
    require(int(packed["centers"]) == 0 and not bool(packed["ready"]), "road blanket bypassed land planning")
    require(not packed["cramped"].is_empty(), "fragmented city lacks map feedback")
    # Keep a useful network, remove excess roads, allow autonomous regrowth.
    var retained: Array = tree_grid()
    repair(retained, 0)
    for y: int in range(22):
        for x: int in range(16):
            if int(retained[y][x]) == 1:
                dense[y][x] = 1
            elif int(dense[y][x]) == 1:
                dense[y][x] = 0
    populate(dense)
    require(bool(Model.analyze(dense)["ready"]), "removing excess roads could not recover metropolis")
    var block: Array = [[1,1,1,1], [1,3,0,1], [1,0,4,1], [1,1,1,1]]
    var snapshot: Array = block.duplicate(true)
    require(Model.has_room(block, Vector2i(1,1)), "occupied shared block is not usable")
    require(Model.fragments_land(block, Vector2i(2,1)), "automatic feeder would destroy the last block")
    require(block == snapshot, "local-road room preview mutated the grid")
    print("AXIVA_ZERO_C_NETWORK_RESULT checks=%d failures=%d" % [checks, failures])
    if failures == 0:
        print("AXIVA_ZERO_C_NETWORK_OK")
    quit(0 if failures == 0 else 1)

static func empty_grid() -> Array:
    var grid: Array = []
    for y: int in range(22):
        var row: Array = []
        row.resize(16)
        row.fill(0)
        grid.append(row)
    return grid

static func line(grid: Array, a: Vector2i, b: Vector2i) -> void:
    var p: Vector2i = a
    grid[p.y][p.x] = 1
    while p != b:
        p += Vector2i(signi(b.x - p.x), signi(b.y - p.y))
        grid[p.y][p.x] = 1

static func tree_grid() -> Array:
    var grid: Array = empty_grid()
    line(grid, Vector2i(1, 5), Vector2i(8, 5))
    line(grid, Vector2i(8, 5), Vector2i(8, 20))
    line(grid, Vector2i(8, 8), Vector2i(14, 8))
    line(grid, Vector2i(8, 20), Vector2i(10, 20))
    return grid

static func repair(grid: Array, mode: int) -> void:
    if mode == 0:
        line(grid, Vector2i(1, 5), Vector2i(1, 20))
        line(grid, Vector2i(1, 20), Vector2i(14, 20))
        line(grid, Vector2i(14, 20), Vector2i(14, 8))
    else:
        line(grid, Vector2i(1, 5), Vector2i(1, 2))
        line(grid, Vector2i(1, 2), Vector2i(14, 2))
        line(grid, Vector2i(14, 2), Vector2i(14, 20))
        line(grid, Vector2i(14, 20), Vector2i(10, 20))

static func populate(grid: Array) -> void:
    for y: int in range(22):
        for x: int in range(16):
            if int(grid[y][x]) != 0:
                continue
            var p: Vector2i = Vector2i(x, y)
            var adjacent: bool = false
            for d: Vector2i in Model.DIRS:
                var q: Vector2i = p + d
                if q.x >= 0 and q.x < 16 and q.y >= 0 and q.y < 22 and int(grid[q.y][q.x]) == 1:
                    adjacent = true
            if not adjacent:
                continue
            var nearest: int = 0
            var distance: int = 1000
            for i: int in range(3):
                var a: Vector2i = Model.ANCHORS[i]
                var score: int = absi(p.x - a.x) + absi(p.y - a.y)
                if score < distance:
                    distance = score
                    nearest = i
            grid[y][x] = Model.KINDS[nearest]

func require(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("AXIVA_ZERO_C_FAILED: " + message)
