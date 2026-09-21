extends SceneTree
const Probe = preload("res://tests/zero_c_probe.gd")
const Fixtures = preload("res://tests/zero_c_network_test.gd")
var checks: int = 0
var failures: int = 0
var normal_save_paths: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(430, 932)
    var game: Node = Probe.new()
    normal_save_paths.assign([game.SAVE_PATH, game.V08_SAVE_BACKUP_PATH, game.V20_FTUE_SAVE_PATH])
    for path: String in normal_save_paths:
        var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
        file.store_string("normal-save-sentinel:" + path)
        file.close()
    var save_before: String = _save_fingerprint()
    root.add_child(game)
    await process_frame
    await process_frame
    game.set_process(false)
    for child: Node in game.get_children():
        if child is Timer:
            child.stop()
    game.rng.seed = 210921
    require(game.zero_session and game.zero_b_session and game.zero_c_session, "C mode routing failed")
    require(game._zero_c_query_requests("?fresh=1&zero=c"), "C query not recognized")
    require(not game._zero_c_query_requests("?zero=cat"), "partial query activated C")
    require(not game._zero_c_query_requests("?zero=b"), "B query activated C")
    require(not game._v07_load_city(), "C loaded the normal save")
    require(_save_fingerprint() == save_before, "C startup modified normal persistence")
    game._v07_save_city()
    require(_save_fingerprint() == save_before, "C wrote a normal save")
    game._v33_delete_persistent_city_state()
    require(_save_fingerprint() == save_before, "C reset would delete normal persistence")
    # Player transaction path: no direct state injection for the growth sequence.
    commit_line(game, Vector2i(1, 5), Vector2i(8, 5))
    commit_line(game, Vector2i(8, 5), Vector2i(8, 20))
    commit_line(game, Vector2i(8, 8), Vector2i(14, 8))
    require(game.zero_c_effect.contains("駅につながった"), "station connection was not explained")
    require(not game.zero_c_road_marks.is_empty(), "new connection has no map marks")
    var feedback: String = game.zero_c_effect
    var feedback_until: float = game.zero_c_effect_until
    commit_line(game, Vector2i(8, 8), Vector2i(14, 8))
    require(game.zero_c_effect == feedback and game.zero_c_effect_until == feedback_until, "no-op drawing invented a new effect")
    commit_line(game, Vector2i(8, 20), Vector2i(10, 20))
    for i: int in range(150):
        game._simulation_tick()
        game._process(0.85)
        if i % 10 == 0:
            await process_frame
    var before: int = game.zero_c_state["buildings"].size()
    print("ZERO_C_GROWTH buildings=%d stage=%d centers=%d peak=%.2f" % [before, game.zero_c_stage, game.zero_c_state["centers"], game.zero_c_state["peak"]])
    require(before >= 40 and game.zero_c_stage == 4, "tree did not reach large city")
    require(game._zero_c_stalled() and not game.zero_c_metropolis, "tree did not stall")
    for i: int in range(20):
        game._simulation_tick()
    require(game.zero_c_state["buildings"].size() == before, "stalled city kept growing")
    require(not game._zero_c_hint().is_empty(), "stalled city has no contextual explanation")
    require(not game.zero_c_stage_notice.is_empty(), "growth stages have no transition feedback")
    # The repair is also performed through actual main road transactions.
    commit_line(game, Vector2i(1, 5), Vector2i(1, 20))
    commit_line(game, Vector2i(1, 20), Vector2i(14, 20))
    commit_line(game, Vector2i(14, 20), Vector2i(14, 8))
    require(game.zero_c_effect.contains("流れが分かれた"), "alternate route was not explained")
    for i: int in range(120):
        game._simulation_tick()
        game._process(0.85)
        if i % 10 == 0:
            await process_frame
    print("ZERO_C_REPAIR buildings=%d pairs=%d centers=%d peak=%.2f stable=%d" % [game.zero_c_state["buildings"].size(), game.zero_c_state["redundant_pairs"], game.zero_c_state["centers"], game.zero_c_state["peak"], game.zero_c_stable_ticks])
    require(game.zero_c_metropolis and game.zero_c_stage == 5, "repair failed metropolitan breakthrough")
    require(game.zero_c_state["buildings"].size() > before, "repair did not restart growth")
    require(game.zero_b_stage_piece_count == 0, "decorative B center leaked into C")
    require(game.cash == game.ZERO_CASH, "repair can hit a cash dead end")
    require(_save_fingerprint() == save_before, "play session modified normal persistence")
    # Stable-flow time is simulation time, not frames or paused time.
    game.zero_c_metropolis = false
    game.zero_c_stable_ticks = 0
    game.paused = true
    for i: int in range(15):
        game._simulation_tick()
    require(game.zero_c_stable_ticks == 0, "paused session earned stability")
    game.paused = false
    game.dragging = true
    for i: int in range(15):
        game._simulation_tick()
    require(game.zero_c_stable_ticks == 0, "active road gesture earned stability")
    game.dragging = false
    # A valid city from the start needs no failure/recovery marker.
    game.grid = Fixtures.tree_grid()
    Fixtures.repair(game.grid, 1)
    Fixtures.populate(game.grid)
    game.zero_c_earned_once = false
    game.v29_recovery_stage = 0
    game._recalculate_city()
    for i: int in range(13):
        game._simulation_tick()
    require(game.zero_c_metropolis, "preventive planning did not qualify")
    # Cut both approaches to station, then restore them via player transactions.
    game._bulldoze(Vector2i(13, 8))
    game._bulldoze(Vector2i(14, 7))
    game._bulldoze(Vector2i(14, 9))
    require(not game.zero_c_metropolis and game.zero_c_stable_ticks == 0, "route deletion retained qualification")
    commit_line(game, Vector2i(13, 8), Vector2i(14, 8))
    commit_line(game, Vector2i(14, 6), Vector2i(14, 10))
    for i: int in range(15):
        game._simulation_tick()
    require(game.zero_c_metropolis, "repaired deletion did not recover")
    # The existing road-only eraser still rejects buildings, without claiming
    # an improvement for a rejected action.
    var before_removal: Dictionary = game.zero_c_state.duplicate(true)
    var parcel: Vector2i = game.zero_c_state["buildings"].keys()[0]
    game.zero_c_effect = ""
    game._bulldoze(parcel)
    require(not game.zero_c_effect.contains("土地がまとまり"), "building deletion falsely claimed a block recovery")
    require(game.zero_c_state["buildings"].size() == before_removal["buildings"].size(), "road-only eraser removed a building")
    # Reproduce a densely pre-drawn city, then recover through real erase inputs.
    game.grid = Fixtures.empty_grid()
    for y: int in range(22):
        for x: int in range(16):
            if x % 2 == 0 or y % 2 == 0:
                game.grid[y][x] = game.Cell.ARTERIAL
    Fixtures.populate(game.grid)
    game._recalculate_city()
    for i: int in range(15):
        game._simulation_tick()
    require(not game.zero_c_metropolis and game.zero_c_state["centers"] == 0, "rapid road blanket qualified")
    require(game._zero_c_hint().contains("土地を広く"), "fragmentation lacks actionable hint")
    for origin: Vector2i in [Vector2i(1,5), Vector2i(11,7)]:
        for offset: Vector2i in [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2)]:
            game._bulldoze(origin + offset)
    require(game._zero_c_spacious_total(game.zero_c_state) >= 8, "erasing roads did not restore usable parcels")
    require(game.zero_c_effect.contains("土地がまとまり"), "land recovery was not explained")
    for i: int in range(15):
        game._simulation_tick()
    require(game.zero_c_metropolis, "dense city could not recover through road removal")
    game.queue_free()
    await process_frame
    require(_save_fingerprint() == save_before, "C exit modified normal persistence")
    print("AXIVA_ZERO_C_RESULT checks=%d failures=%d" % [checks, failures])
    if failures == 0:
        print("AXIVA_ZERO_C_OK")
    quit(0 if failures == 0 else 1)

func commit_line(game: Node, a: Vector2i, b: Vector2i) -> void:
    game.current_tool = game.Tool.ROAD
    game.drag_path = game._v35_straight_path(a, b)
    game.dragging = true
    game._commit_arterial()
    game.dragging = false
    game.drag_path.clear()

func _save_fingerprint() -> String:
    var result: String = ""
    for path: String in normal_save_paths:
        result += path + FileAccess.get_file_as_string(path)
    return result

func require(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("AXIVA_ZERO_C_FAILED: " + message)
