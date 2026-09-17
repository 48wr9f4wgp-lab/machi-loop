extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var script: Script = load("res://main_v28_city_birth_sequence.gd") as Script
    if script == null:
        _fail("v0.28 script did not load")
        return

    var game: Node = script.new() as Node
    root.add_child(game)
    await process_frame
    await process_frame

    if not is_instance_valid(game.v10_camera):
        _fail("3D camera did not initialize")
        return

    game._init_grid()
    game.unlocked_cols = game.GRID_W
    game.city_level = 1
    game.population = 0

    for x: int in range(5, 11):
        game.grid[10][x] = game.Cell.ARTERIAL
    game._recalculate_city()

    game._v04_seed_first_growth()
    if not game.v28_sequence_active:
        _fail("first residential seed did not start the birth sequence")
        return
    if game.v28_sequence_stage != game.V28_STAGE_HOME:
        _fail("birth sequence did not enter HOME stage")
        return
    if game.v28_home_anchor.x < 0:
        _fail("first home anchor was not captured")
        return

    var local_p: Vector2i = _find_empty(game, Vector2i(7, 11))
    if local_p.x < 0:
        _fail("could not find local-road fixture cell")
        return
    game.grid[local_p.y][local_p.x] = game.Cell.LOCAL
    game._v28_note_local_road(local_p)
    if game.v28_local_anchor != local_p:
        _fail("local-road milestone anchor was not captured")
        return

    var commercial_p: Vector2i = _find_empty(game, Vector2i(8, 9))
    if commercial_p.x < 0:
        _fail("could not find commercial fixture cell")
        return
    game.grid[commercial_p.y][commercial_p.x] = game.Cell.COMMERCIAL
    game._v28_note_commercial(commercial_p)
    if game.v28_commercial_anchor != commercial_p:
        _fail("commercial milestone anchor was not captured")
        return

    while game._count_cells(game.Cell.RESIDENTIAL) < 2:
        var extra_home: Vector2i = _find_empty(game, Vector2i(6, 9))
        if extra_home.x < 0:
            _fail("could not create second residential fixture")
            return
        game.grid[extra_home.y][extra_home.x] = game.Cell.RESIDENTIAL
    game._recalculate_city()

    if game.population < 26:
        _fail("fixture did not reach recognizable settlement population")
        return

    game._v28_maybe_reveal()
    if game.v28_sequence_stage != game.V28_STAGE_REVEAL:
        _fail("home + local road + commercial + population did not trigger reveal")
        return
    if game.v28_reveal_count != 1:
        _fail("city reveal count was not exactly one")
        return
    if game._v23_context_message() != "街が生まれました":
        _fail("final sequence copy does not match the city-birth reveal")
        return

    var base_size: float = game._v28_base_camera_size()
    game._v28_update_camera(0.25)
    if game.v10_camera.size >= base_size:
        _fail("reveal choreography did not begin from a closer city framing")
        return

    game._v28_maybe_reveal()
    if game.v28_reveal_count != 1:
        _fail("city reveal retriggered")
        return

    print("V28_CITY_BIRTH_SEQUENCE_OK milestones=%d reveal=%d pop=%d camera=%.2f/%.2f" % [
        game.v28_milestone_count,
        game.v28_reveal_count,
        game.population,
        game.v10_camera.size,
        base_size
    ])
    game.queue_free()
    quit(0)

func _find_empty(game: Node, preferred: Vector2i) -> Vector2i:
    if game._in_bounds(preferred) and preferred.x < game.unlocked_cols and int(game.grid[preferred.y][preferred.x]) == game.Cell.EMPTY:
        return preferred
    for y: int in range(game.GRID_H):
        for x: int in range(game.unlocked_cols):
            if int(game.grid[y][x]) == game.Cell.EMPTY:
                return Vector2i(x, y)
    return Vector2i(-1, -1)

func _fail(message: String) -> void:
    push_error("V28_CITY_BIRTH_SEQUENCE_FAILED: " + message)
    quit(1)
