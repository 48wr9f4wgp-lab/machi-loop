extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var game_script: Script = load("res://main.gd") as Script
    if game_script == null:
        _fail("main.gd failed to load")
        return
    var game: Node = game_script.new() as Node
    game._init_grid()
    game.cash = 1000

    var building: Vector2i = Vector2i(2, 2)
    game.grid[building.y][building.x] = game.Cell.RESIDENTIAL
    var cash_before_building: int = int(game.cash)
    game._bulldoze(building)
    if int(game.grid[building.y][building.x]) != game.Cell.RESIDENTIAL:
        _fail("ordinary residential development was manually demolished")
        return
    if int(game.cash) != cash_before_building:
        _fail("blocked building demolition changed cash")
        return

    var local_road: Vector2i = Vector2i(3, 2)
    game.grid[local_road.y][local_road.x] = game.Cell.LOCAL
    var cash_before_local: int = int(game.cash)
    game._bulldoze(local_road)
    if int(game.grid[local_road.y][local_road.x]) != game.Cell.EMPTY:
        _fail("local road removal stopped working")
        return
    if int(game.cash) < cash_before_local:
        _fail("local road salvage recovery regressed")
        return

    var arterial: Vector2i = Vector2i(4, 2)
    game.grid[arterial.y][arterial.x] = game.Cell.ARTERIAL
    game.widened[game._key(arterial)] = true
    var cash_before_arterial: int = int(game.cash)
    game._bulldoze(arterial)
    if int(game.grid[arterial.y][arterial.x]) != game.Cell.EMPTY:
        _fail("arterial removal stopped working")
        return
    if game.widened.has(game._key(arterial)):
        _fail("removed arterial retained widened state")
        return
    if int(game.cash) < cash_before_arterial:
        _fail("arterial salvage recovery regressed")
        return

    print("ROAD_ONLY_BULLDOZE_OK")
    quit(0)

func _fail(message: String) -> void:
    push_error("ROAD_ONLY_BULLDOZE_FAILED: " + message)
    quit(1)
