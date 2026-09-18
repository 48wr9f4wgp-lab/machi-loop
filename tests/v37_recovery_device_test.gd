extends SceneTree

const GameClass = preload("res://main_v37_recovery_device_test.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var game = GameClass.new()
    root.add_child(game)
    await process_frame
    await process_frame

    _expect(game._v37_query_requests_recovery("?recovery=1"), "recovery query not detected")
    _expect(game._v37_query_requests_recovery("?fresh=1&recovery=1"), "combined query not detected")
    _expect(not game._v37_query_requests_recovery("?fresh=1"), "fresh query incorrectly enables recovery mode")
    _expect(not game._v37_query_requests_recovery(""), "empty query incorrectly enables recovery mode")

    game.paused = true
    game.v37_recovery_session = true
    game._v37_seed_recovery_fixture()

    _expect(game.unlocked_cols == game.GRID_W, "fixture did not open full validation width")
    _expect(game.cash >= 1000, "fixture lacks bypass construction budget")
    _expect(game.population >= 90, "fixture population below recovery gate threshold")
    _expect(game._count_cells(game.Cell.ARTERIAL) >= 6, "fixture arterial count too low")
    _expect(game.v16_traffic_status == "severe", "fixture did not create severe congestion")
    _expect(game.v16_traffic_cause == "no_redundancy", "fixture cause is not missing redundancy")
    _expect(game.v29_recovery_stage == game.V29_STAGE_PROBLEM, "fixture did not enter problem beat")
    _expect(not game.v29_hotspot_cells.is_empty(), "fixture has no visible congestion hotspot")

    # Persistence safety is a hard lock for device-test URLs.
    var source: String = FileAccess.get_file_as_string("res://main_v37_recovery_device_test.gd")
    _expect(source.contains("if v37_recovery_session:\n        return\n    super._v07_save_city()"), "city-save guard removed")
    _expect(source.contains("func _v33_delete_persistent_city_state()"), "reset-delete guard missing")

    print("V37_RECOVERY_DEVICE_TEST_OK pop=%d congestion=%.1f roads=%d" % [
        game.population,
        game.congestion,
        game._count_cells(game.Cell.ARTERIAL)
    ])
    game.queue_free()
    quit(0)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V37_RECOVERY_DEVICE_TEST_FAILED: " + message)
    quit(1)
