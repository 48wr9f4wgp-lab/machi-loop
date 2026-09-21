extends SceneTree

const Probe = preload("res://tests/zero_b_probe.gd")
var failures: int = 0
var checks: int = 0

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(430, 932)
    var game: Node = Probe.new()
    root.add_child(game)
    await process_frame
    await process_frame
    game.set_process(false)
    for child: Node in game.get_children():
        if child is Timer:
            child.stop()
    game.rng.seed = 210021

    _require(game.zero_session, "ZERO base mode did not activate for B")
    _require(game.zero_b_session, "ZERO B did not activate")
    _require(game._zero_b_query_requests("?zero=b"), "ZERO B query parser rejected exact mode")
    _require(game._zero_b_query_requests("?fresh=1&zero=b"), "ZERO B query parser rejected mixed query")
    _require(not game._zero_b_query_requests("?zero=1"), "ZERO B parser swallowed the A mode")

    var village_wave: Array[int] = game._zero_b_wave("village", false)
    var station_wave: Array[int] = game._zero_b_wave("station", false)
    var interchange_wave: Array[int] = game._zero_b_wave("interchange", false)
    _require(village_wave.count(game.Cell.RESIDENTIAL) >= 6, "village wave is not residential-led")
    _require(station_wave.count(game.Cell.COMMERCIAL) >= 6, "station wave is not commercial-led")
    _require(interchange_wave.count(game.Cell.INDUSTRIAL) >= 6, "interchange wave is not industrial-led")
    _require(game._zero_b_wave("station", true).size() > station_wave.size(), "station connection has no spectacle bonus")
    _require(game._zero_b_wave("interchange", true).size() > interchange_wave.size(), "interchange connection has no spectacle bonus")

    var station_path: Array = game._v35_straight_path(Vector2i(8, 8), game.ZERO_STATION)
    var village_path: Array = game._v35_straight_path(Vector2i(1, 10), game.ZERO_VILLAGE)
    var interchange_path: Array = game._v35_straight_path(Vector2i(10, 10), game.ZERO_INTERCHANGE)
    _require(game._zero_b_signature_for_path(station_path) == "station", "station route signature is unreadable")
    _require(game._zero_b_signature_for_path(village_path) == "village", "village route signature is unreadable")
    _require(game._zero_b_signature_for_path(interchange_path) == "interchange", "interchange route signature is unreadable")

    _commit_line(game, Vector2i(8, 10), Vector2i(8, 8))
    _commit_line(game, Vector2i(8, 8), game.ZERO_STATION)
    _require(game._zero_landmark_connected(game.ZERO_STATION), "station connection was not recognized")
    _require(game.zero_b_last_signature == "station", "station connection did not own the response")
    _require(game.v42_arrivals.count(game.Cell.COMMERCIAL) >= 8, "station connection did not create a commercial burst")
    _require(game.zero_b_stage_piece_count >= 8, "station did not visibly transform after connection")

    for _i: int in range(8):
        game._simulation_tick()
        game._process(0.85)
    _require(game.v42_response_count >= 6, "ZERO B spectacle response was too slow")

    _commit_line(game, Vector2i(8, 8), Vector2i(1, 8))
    _commit_line(game, Vector2i(1, 8), game.ZERO_VILLAGE)
    _require(game._zero_landmark_connected(game.ZERO_VILLAGE), "village connection was not recognized")
    _require(game._zero_b_connected_count() >= 2, "two destination network stage was not reached")
    _require(game.zero_b_stage_piece_count >= 18, "two connections did not grow a visible city core")

    print("AXIVA_ZERO_B_RESULT checks=%d failures=%d pieces=%d responses=%d connected=%d" % [
        checks,
        failures,
        game.zero_b_stage_piece_count,
        game.v42_response_count,
        game._zero_b_connected_count()
    ])

    game.queue_free()
    await process_frame
    if failures == 0:
        print("AXIVA_ZERO_B_OK")
    quit(0 if failures == 0 else 1)

func _commit_line(game: Node, a: Vector2i, b: Vector2i) -> void:
    game.current_tool = game.Tool.ROAD
    game.drag_path = game._v35_straight_path(a, b)
    game.dragging = true
    game._commit_arterial()
    game.dragging = false
    game.drag_path.clear()

func _require(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("AXIVA_ZERO_B_FAILED: " + message)
