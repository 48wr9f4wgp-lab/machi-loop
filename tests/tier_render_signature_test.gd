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
    game.unlocked_cols = 16
    game.grid[4][4] = game.Cell.ARTERIAL
    game.grid[4][5] = game.Cell.RESIDENTIAL

    game.city_level = 4
    var tier4_hash: int = int(game._v10_scene_hash())
    game.city_level = 5
    var tier5_hash: int = int(game._v10_scene_hash())
    game.city_level = 6
    var tier6_hash: int = int(game._v10_scene_hash())

    if tier4_hash == tier5_hash or tier5_hash == tier6_hash or tier4_hash == tier6_hash:
        _fail("scene signature did not change across production asset tiers")
        return

    # Repeated reads at the same state must remain stable so the renderer does not
    # rebuild without a real state transition.
    var stable_hash: int = int(game._v10_scene_hash())
    if stable_hash != tier6_hash:
        _fail("scene signature is not deterministic at a stable tier")
        return

    print("TIER_RENDER_SIGNATURE_OK")
    quit(0)

func _fail(message: String) -> void:
    push_error("TIER_RENDER_SIGNATURE_FAILED: " + message)
    quit(1)
