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
    game.unlocked_cols = game.GRID_W
    game.cash = 1000

    for x: int in range(3, 9):
        game.grid[10][x] = game.Cell.ARTERIAL
    game.grid[9][5] = game.Cell.RESIDENTIAL
    game.grid[11][5] = game.Cell.LOCAL
    game.widened[game._key(Vector2i(4, 10))] = true

    game.v40_remove_path = [
        Vector2i(3, 10), Vector2i(4, 10), Vector2i(5, 10),
        Vector2i(5, 9), Vector2i(5, 11)
    ]
    var before_cash: int = game.cash
    game._v40_commit_remove_path()

    for x: int in range(3, 6):
        if int(game.grid[10][x]) != game.Cell.EMPTY:
            _fail("player-authored arterial segment was not removed")
            return
    if game.widened.has(game._key(Vector2i(4, 10))):
        _fail("removed widened arterial retained widened state")
        return
    if int(game.grid[9][5]) != game.Cell.RESIDENTIAL:
        _fail("simulation-owned building was removed")
        return
    if int(game.grid[11][5]) != game.Cell.EMPTY:
        _fail("local road in remove path was not removed")
        return
    if game.cash != before_cash - 4 * game.REMOVE_COST:
        _fail("removal cost was not charged once per removed road cell")
        return

    print("V40_RECOVERABLE_ROADS_OK")
    game.free()
    quit(0)

func _fail(message: String) -> void:
    push_error("V40_RECOVERABLE_ROADS_FAILED: " + message)
    quit(1)
