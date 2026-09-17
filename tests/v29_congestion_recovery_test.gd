extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var script: Script = load("res://main_v29_congestion_recovery.gd") as Script
    if script == null:
        _fail("v0.29 script did not load")
        return

    var game: Node = script.new() as Node
    root.add_child(game)
    await process_frame
    await process_frame

    game.paused = true
    game._init_grid()
    game.unlocked_cols = game.GRID_W
    game.city_level = 4
    game.v28_sequence_active = false
    game.v29_recovery_stage = game.V29_STAGE_NONE

    # One overloaded east-west arterial with no redundant route.
    for x: int in range(3, 13):
        game.grid[10][x] = game.Cell.ARTERIAL

    for x: int in range(4, 12):
        game.grid[8][x] = game.Cell.RESIDENTIAL
        game.grid[12][x] = game.Cell.RESIDENTIAL
    for x: int in range(4, 8):
        game.grid[7][x] = game.Cell.RESIDENTIAL
        game.grid[6][x] = game.Cell.COMMERCIAL
        game.grid[14][x] = game.Cell.INDUSTRIAL

    game._recalculate_city()

    if game.v16_traffic_status != "severe":
        _fail("fixture did not create severe congestion")
        return
    if game.v16_traffic_cause != "no_redundancy":
        _fail("fixture did not identify missing redundancy")
        return
    if game.v29_recovery_stage != game.V29_STAGE_PROBLEM:
        _fail("severe structural congestion did not begin the problem beat")
        return
    if game.v29_problem_anchor.x < 0 or game.v29_hotspot_cells.is_empty():
        _fail("congestion problem did not capture a visible hotspot")
        return

    var baseline_congestion: float = game.congestion
    var baseline_cycles: int = game.v16_cycles

    # Add a parallel bypass and connect both ends, creating a real network cycle.
    var bypass: Array[Vector2i] = []
    for x: int in range(3, 13):
        var p: Vector2i = Vector2i(x, 16)
        game.grid[p.y][p.x] = game.Cell.ARTERIAL
        bypass.append(p)
    for y: int in range(11, 16):
        var left: Vector2i = Vector2i(3, y)
        var right: Vector2i = Vector2i(12, y)
        game.grid[left.y][left.x] = game.Cell.ARTERIAL
        game.grid[right.y][right.x] = game.Cell.ARTERIAL
        bypass.append(left)
        bypass.append(right)

    game._v29_register_intervention(bypass)
    if game.v29_recovery_stage != game.V29_STAGE_INTERVENTION:
        _fail("bypass intervention was not registered")
        return

    game._recalculate_city()

    if game.v16_cycles <= baseline_cycles:
        _fail("bypass did not add network redundancy")
        return
    if game.congestion >= baseline_congestion - 12.0:
        _fail("bypass did not materially reduce congestion")
        return
    if game.v29_recovery_stage != game.V29_STAGE_RECOVERY:
        _fail("traffic improvement did not enter recovery beat")
        return
    if game.v29_recovery_count != 1:
        _fail("recovery beat count is incorrect")
        return
    if game.v29_bypass_cells.size() != bypass.size():
        _fail("player-authored bypass cells were not preserved")
        return

    # First new parcel after recovery proves that autonomous growth resumed.
    var before_buildings: int = game._v29_building_count()
    game.grid[5][5] = game.Cell.RESIDENTIAL
    game._recalculate_city()
    game._v29_note_growth_resume(before_buildings)

    if game.v29_recovery_stage != game.V29_STAGE_RESUMED:
        _fail("new growth after recovery did not complete the sequence")
        return
    if game.v29_growth_resume_count != 1 or game.v29_completion_count != 1:
        _fail("recovery completion counters are incorrect")
        return
    if game._v23_context_message() != "道一本で街の流れが変わった":
        _fail("final causal message is not exposed through city-as-UI")
        return

    print("V29_CONGESTION_RECOVERY_OK baseline=%.1f recovered=%.1f cycles=%d bypass=%d" % [
        baseline_congestion,
        game.v29_recovery_congestion,
        game.v16_cycles,
        game.v29_bypass_cells.size()
    ])
    game.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("V29_CONGESTION_RECOVERY_FAILED: " + message)
    quit(1)
