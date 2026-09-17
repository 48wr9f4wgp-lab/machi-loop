extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var script: Script = load("res://main_v27_growth_delight.gd") as Script
    if script == null:
        _fail("v0.27 script did not load")
        return

    var game: Node = script.new() as Node
    root.add_child(game)
    await process_frame
    await process_frame

    if not is_instance_valid(game.v10_viewport) or not is_instance_valid(game.v10_static_root):
        _fail("3D renderer did not initialize")
        return

    game._init_grid()
    game.unlocked_cols = game.GRID_W
    game.city_level = 1
    game.v04_time = 10.0
    game.grid[10][7] = game.Cell.ARTERIAL
    game._recalculate_city()

    game._v04_seed_first_growth()
    if not game.v04_first_growth_seeded:
        _fail("first road response did not seed initial growth")
        return
    if game.population <= 0:
        _fail("first growth did not create visible population")
        return
    if game.v27_growth_schedule.size() != 1:
        _fail("first settlement did not receive exactly one growth schedule")
        return
    if game.v27_birth_anchor.x < 0 or game.v27_birth_pulse_count != 1:
        _fail("first settlement birth pulse was not armed")
        return
    if not game.v23_birth_announced or game.v23_alert_text != "街が生まれました":
        _fail("first settlement did not immediately announce city birth")
        return

    var key: String = game._key(game.v27_birth_anchor)
    if not game.v27_growth_schedule.has(key):
        _fail("birth anchor is missing its growth schedule")
        return
    var state: Dictionary = game.v27_growth_schedule[key] as Dictionary
    var start: float = float(state["start"])
    var duration: float = float(state["duration"])

    game.v04_time = start
    var start_scale: float = game._v04_growth_scale(game.v27_birth_anchor)
    if start_scale > 0.12:
        _fail("new building did not begin close to ground level")
        return

    game.v04_time = start + duration * 0.64
    var mid_scale: float = game._v04_growth_scale(game.v27_birth_anchor)
    if mid_scale < 0.80:
        _fail("growth animation did not rise quickly enough")
        return

    game.v04_time = start + duration
    var end_scale: float = game._v04_growth_scale(game.v27_birth_anchor)
    if absf(end_scale - 1.0) > 0.01:
        _fail("growth animation did not settle at full scale")
        return

    var second: Vector2i = game.v27_birth_anchor + Vector2i(1, 0)
    if not game._in_bounds(second):
        second = game.v27_birth_anchor + Vector2i(-1, 0)
    game._v27_schedule_growth(second, false)
    var second_state: Dictionary = game.v27_growth_schedule[game._key(second)] as Dictionary
    if float(second_state["start"]) < game.v04_time:
        _fail("autonomous growth wave scheduled in the past")
        return

    game.v04_time = maxf(
        float(state["start"]) + float(state["duration"]),
        float(second_state["start"]) + float(second_state["duration"])
    ) + 0.40
    game._v27_cleanup_growth_schedule()
    if not game.v27_growth_schedule.is_empty():
        _fail("completed growth schedules were not cleaned up")
        return

    print("V27_GROWTH_DELIGHT_OK population=%d sequences=%d pulse=%d" % [
        game.population,
        game.v27_growth_sequence_count,
        game.v27_birth_pulse_count
    ])
    game.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("V27_GROWTH_DELIGHT_FAILED: " + message)
    quit(1)
