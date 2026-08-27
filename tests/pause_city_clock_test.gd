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
    game.v04_time = 5.0
    game.paused = true
    game._process(0.5)
    if absf(float(game.v04_time) - 5.0) > 0.0001:
        _fail("city animation clock advanced while paused: %f" % float(game.v04_time))
        return

    game.paused = false
    game._process(0.5)
    if float(game.v04_time) <= 5.0:
        _fail("city animation clock did not resume")
        return

    print("PAUSE_CITY_CLOCK_OK")
    quit(0)

func _fail(message: String) -> void:
    push_error("PAUSE_CITY_CLOCK_FAILED: " + message)
    quit(1)
