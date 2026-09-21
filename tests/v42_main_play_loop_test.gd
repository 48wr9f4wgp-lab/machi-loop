extends SceneTree

var failures: int = 0
var checks: int = 0
const Probe = preload("res://tests/v42_main_probe.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(430, 932)
    var game: Node = await _new_game()
    _road(game, Vector2i(3, 10), Vector2i(8, 10))
    _require(game.v40_commit_count == 1, "first input did not commit once")
    _require(game.population >= 13 and game.v04_first_growth_seeded, "first road did not seed an immediate home")
    _require(game.v23_birth_started and game.v23_birth_announced, "city-birth flags were bypassed")
    _require(game.v28_sequence_active and game.v28_milestone_count == 1, "main input did not enter HOME choreography")
    _require(game.v08_goal_stage == 1 and game.cash == 708, "first reward/cost accounting or duplicate reward")
    for i: int in range(14):
        game._simulation_tick()
        game._process(0.85)
    _require(game.population >= 26, "recognizable settlement failed")
    _require(game.v28_reveal_count == 1, "arrival wave failed to reveal the city exactly once")
    _require(game._v23_context_message() != "道のそばに、街が生まれようとしています", "stale pre-birth context")
    _road(game, Vector2i(3, 10), Vector2i(8, 10))
    _require(game.v40_commit_count == 1 and game.v27_birth_pulse_count == 1, "existing road retriggered birth")
    game.queue_free()
    await process_frame

    game = await _new_game()
    _mixed_city(game)
    var saved_grid: String = JSON.stringify(game.grid)
    _road(game, Vector2i(3, 10), Vector2i(9, 10))
    _require(not game.v42_pending_path.is_empty(), "occupied route did not request confirmation")
    _require(JSON.stringify(game.grid) == saved_grid and game.cash == 1000, "preview changed city or money")
    _require(game.v42_pending_plan["total_cost"] == 140, "LOCAL upgrade / acquisition quote mismatch")
    var tick: int = game.tick_count
    game._simulation_tick()
    _require(game.tick_count == tick, "confirmation allowed the quote to become stale")
    _tap(game, game._v42_cancel_rect().get_center())
    _require(game.v42_pending_path.is_empty() and game.cash == 1000, "cancel altered city")
    _road(game, Vector2i(3, 10), Vector2i(9, 10))
    _tap(game, game._v42_confirm_rect().get_center())
    _require(game.v40_commit_count == 1 and game.cash == 860, "acquisition was not one atomic transaction")
    for x: int in range(3, 10):
        _require(int(game.grid[10][x]) == game.Cell.ARTERIAL, "route has a non-arterial hole")
    _require(game.widened.has("3:10"), "existing arterial lost its widening")
    for x: int in [4, 6, 7]:
        _require(not game.v10_building_nodes.has("%d:10" % x), "acquired building remains in renderer")
    _require(game.v32_full_sync_count > 0, "acquisition did not synchronize static city")
    # Failed quotes, locked land and duplicate cells are checked against the
    # same planner used by the input-driven transaction above.
    _mixed_city(game)
    game.cash = 139
    saved_grid = JSON.stringify(game.grid)
    _road(game, Vector2i(3, 10), Vector2i(9, 10))
    _require(game.cash == 139 and JSON.stringify(game.grid) == saved_grid, "insufficient funds partially applied")
    game.drag_path = [Vector2i(4, 10), Vector2i(4, 10)]
    _require(game._v40_preview_metrics()["total_cost"] == 32, "duplicate parcel was charged twice")
    game.drag_path = [Vector2i(4, 10), Vector2i(game.unlocked_cols, 10)]
    _require(not game._v40_preview_metrics()["valid"], "locked parcel was silently skipped")
    game.drag_path.clear()
    game.queue_free()
    await process_frame

    game = await _new_game()
    _mixed_city(game)
    var road_pos: Vector2 = game._v27_project_cell(Vector2i(3, 10), 0.0)
    var other_pos: Vector2 = road_pos + Vector2(60.0, 40.0)
    for tool: int in [game.Tool.ROAD, game.Tool.WIDEN, game.Tool.BULLDOZE]:
        game.current_tool = tool
        game.widened.clear()
        saved_grid = JSON.stringify(game.grid)
        var before_cash: int = game.cash
        _touch(game, 0, road_pos, true)
        _require(game.cash == before_cash and JSON.stringify(game.grid) == saved_grid, "first finger mutated before gesture arbitration")
        _touch(game, 1, other_pos, true)
        _drag(game, 1, other_pos + Vector2(20.0, 10.0))
        _touch(game, 1, other_pos, false)
        _drag(game, 0, road_pos + Vector2(20.0, 10.0))
        _touch(game, 0, road_pos, false)
        _require(game.cash == before_cash and JSON.stringify(game.grid) == saved_grid, "navigation edited city")
        _require(game.widened.is_empty(), "navigation widened a road")
        _require(not game.dragging and game.v41_touches.is_empty(), "gesture did not release ownership")
        game._v41_show_overview()
        road_pos = game._v27_project_cell(Vector2i(3, 10), 0.0)
        other_pos = road_pos + Vector2(60.0, 40.0)
    game.current_tool = game.Tool.WIDEN
    var before_cash: int = game.cash
    _tap(game, road_pos)
    _require(game.widened.has("3:10") and game.cash == before_cash - 90, "single-finger widen did not charge exactly once")
    game.current_tool = game.Tool.ROAD
    saved_grid = JSON.stringify(game.grid)
    var a: Vector2 = game._v27_project_cell(Vector2i(4, 14), 0.0)
    var b: Vector2 = game._v27_project_cell(Vector2i(8, 14), 0.0)
    _touch(game, 0, a, true)
    _drag(game, 0, b)
    _touch(game, 0, b, false, true)
    _require(JSON.stringify(game.grid) == saved_grid and not game.dragging, "canceled touch committed a road")
    _touch(game, 0, a, true)
    _drag(game, 0, b)
    game._notification(game.NOTIFICATION_APPLICATION_FOCUS_OUT)
    _touch(game, 0, b, false)
    _require(JSON.stringify(game.grid) == saved_grid and game.v41_touches.is_empty(), "focus-loss committed or latched input")
    _require(not bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch")), "touch mouse emulation is enabled")

    # Camera-space math must be independent of the SubViewport's resolution.
    for viewport_size: Vector2i in [Vector2i(480, 850), Vector2i(704, 1180)]:
        game.v10_viewport.size = viewport_size
        game._v41_show_overview()
        saved_grid = JSON.stringify(game.grid)
        before_cash = game.cash
        _tap(game, game._v41_overview_rect().get_center())
        _require(game.cash == before_cash and JSON.stringify(game.grid) == saved_grid, "overview reset the city")
        for corner: Vector2i in [Vector2i(0, 0), Vector2i(11, 0), Vector2i(0, 21), Vector2i(11, 21)]:
            var screen: Vector2 = game._v27_project_cell(corner, 0.0)
            _require(game._v41_world_area().has_point(screen), "overview excludes a playable corner")
            _require(game._screen_to_cell(screen) == corner, "corner picking failed")
        game.v41_camera_size = game._v28_base_camera_size()
        game._v41_apply_manual_camera()
        var center: Vector2 = game._v41_world_area().get_center()
        var shift: Vector2 = Vector2(20.0, 12.0)
        var anchor: Vector3 = game._v41_ground_at(center)
        _touch(game, 0, center - Vector2(40.0, 0.0), true)
        _touch(game, 1, center + Vector2(40.0, 0.0), true)
        _drag(game, 0, center - Vector2(40.0, 0.0) + shift)
        _drag(game, 1, center + Vector2(40.0, 0.0) + shift)
        _require(game._v41_ground_at(center + shift).distance_to(anchor) < 0.03, "pan slipped relative to fingers")
        _touch(game, 0, center, false)
        _touch(game, 1, center, false)
    game.queue_free()
    await process_frame

    # Integrated fresh-to-recovery model run. No direct seed/recovery calls,
    # no cash grants, and no prebuilt congestion fixture. This is still NOT a
    # physical-iPhone Vertical Slice exit proof.
    game = await _new_game()
    _road(game, Vector2i(3, 10), Vector2i(10, 10))
    var pressure_tick: int = -1
    for i: int in range(300):
        game._simulation_tick()
        game._process(0.85)
        if game.v29_recovery_stage == game.V29_STAGE_PROBLEM:
            pressure_tick = i
            break
    _require(pressure_tick >= 0, "natural structural pressure did not arise within five minutes")
    if pressure_tick >= 0:
        game._v41_show_overview()
        _road(game, Vector2i(3, 10), Vector2i(3, 7))
        _confirm_if_needed(game)
        _road(game, Vector2i(3, 7), Vector2i(10, 7))
        _confirm_if_needed(game)
        _road(game, Vector2i(10, 7), Vector2i(10, 10))
        _confirm_if_needed(game)
        _require(game.v29_recovery_count > 0, "player bypass did not cause measured recovery")
        for i: int in range(60):
            game._simulation_tick()
            game._process(0.85)
            if game.v29_completion_count > 0:
                break
        _require(game.v29_completion_count > 0, "city did not visibly resume growth after recovery")
    print("V42_MAIN_PLAY_LOOP_RESULT checks=%d failures=%d pressure_tick=%d cash=%d" % [checks, failures, pressure_tick, game.cash])
    game.queue_free()
    await process_frame
    if failures == 0:
        print("V42_MAIN_PLAY_LOOP_OK")
    quit(0 if failures == 0 else 1)

func _new_game() -> Node:
    var game: Node = Probe.new()
    root.add_child(game)
    await process_frame
    await process_frame
    game.set_process(false)
    for child: Node in game.get_children():
        if child is Timer:
            child.stop()
    game.rng.seed = 210021
    return game

func _mixed_city(game: Node) -> void:
    game._init_grid()
    game.cash = 1000
    game.unlocked_cols = 12
    game.v08_goal_stage = game.V08_GOAL_COUNT
    game.v04_first_growth_seeded = true
    game.v23_birth_started = true
    game.v23_birth_announced = true
    game.v28_sequence_active = false
    game.v42_arrivals.clear()
    game.widened.clear()
    var kinds: Array[int] = [1, 3, 2, 4, 5, 0, 1]
    for i: int in range(kinds.size()):
        game.grid[10][i + 3] = kinds[i]
    game.widened["3:10"] = true
    game._recalculate_city()
    game._v10_sync_scene()
    game._v41_show_overview()

func _road(game: Node, a: Vector2i, b: Vector2i) -> void:
    game.current_tool = game.Tool.ROAD
    var start: Vector2 = game._v27_project_cell(a, 0.0)
    var finish: Vector2 = game._v27_project_cell(b, 0.0)
    _touch(game, 0, start, true)
    _drag(game, 0, finish)
    _touch(game, 0, finish, false)

func _confirm_if_needed(game: Node) -> void:
    if not game.v42_pending_path.is_empty():
        _tap(game, game._v42_confirm_rect().get_center())

func _tap(game: Node, pos: Vector2) -> void:
    _touch(game, 0, pos, true)
    _touch(game, 0, pos, false)

func _touch(game: Node, index: int, pos: Vector2, pressed: bool, canceled: bool = false) -> void:
    var event: InputEventScreenTouch = InputEventScreenTouch.new()
    event.index = index
    event.position = pos
    event.pressed = pressed
    event.canceled = canceled
    game._unhandled_input(event)

func _drag(game: Node, index: int, pos: Vector2) -> void:
    var event: InputEventScreenDrag = InputEventScreenDrag.new()
    event.index = index
    event.position = pos
    game._unhandled_input(event)

func _require(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("V42_MAIN_PLAY_LOOP_FAILED: " + message)
