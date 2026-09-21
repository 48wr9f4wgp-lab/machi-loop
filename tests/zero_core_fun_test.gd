extends SceneTree

const Probe = preload("res://tests/zero_probe.gd")
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

    _require(game.zero_session, "ZERO mode did not activate")
    _require(game._zero_query_requests("?zero=1"), "zero query parser rejected exact mode")
    _require(game._zero_query_requests("?fresh=1&zero=1"), "zero query parser rejected mixed query")
    _require(not game._zero_query_requests("?zero=0"), "zero query parser accepted disabled mode")
    _require(game.unlocked_cols == game.GRID_W, "ZERO did not expose the full map")
    _require(game.tool_rects.size() == 2, "ZERO exposed extra permanent tools")
    _require(game.tool_rects.has(game.Tool.ROAD), "ZERO road tool missing")
    _require(game.tool_rects.has(game.Tool.BULLDOZE), "ZERO remove tool missing")
    _require(not game.tool_rects.has(game.Tool.WIDEN), "ZERO exposed WIDEN permanently")
    _require(not game._v44_should_offer_widen(), "ZERO exposed contextual WIDEN")
    _require(game.zero_landmark_count == 3, "ZERO world landmarks were not rendered")
    _require(game._v44_anchor(game.Cell.RESIDENTIAL) == game.ZERO_VILLAGE, "village pull not bound to residential growth")
    _require(game._v44_anchor(game.Cell.COMMERCIAL) == game.ZERO_STATION, "station pull not bound to commercial growth")
    _require(game._v44_anchor(game.Cell.INDUSTRIAL) == game.ZERO_INTERCHANGE, "interchange pull not bound to industrial growth")

    var cash_before: int = game.cash
    _commit_line(game, Vector2i(1, 10), Vector2i(8, 10))
    _require(game.zero_route_commits == 1, "first ZERO road did not commit")
    _require(game.cash == cash_before, "ZERO road exposed economy as a constraint")
    _require(game.v42_pending_path.is_empty(), "ZERO road opened acquisition management")
    _require(game.v42_arrivals.size() >= 10, "first ZERO road did not schedule the spectacle wave")

    for _i: int in range(10):
        game._simulation_tick()
        game._process(0.85)
    _require(game.v42_response_count >= 7, "ZERO first-road chain reaction was too weak")
    _require(game._v29_building_count() >= 6, "ZERO did not become a recognizable settlement quickly")
    _require(game.cash == game.ZERO_CASH, "ZERO economy leaked back into the experiment")

    _commit_line(game, Vector2i(8, 10), Vector2i(8, 8))
    _commit_line(game, Vector2i(8, 8), Vector2i(14, 8))
    _require(game.zero_route_commits == 3, "ZERO follow-up roads did not commit")
    _require(game._zero_landmark_connected(game.ZERO_STATION), "road reaching the station was not recognized")
    _require(game.zero_activated_until.has("station"), "station connection had no world payoff")
    _require(game.v42_arrivals.size() >= 9, "landmark connection did not amplify autonomous response")

    print("AXIVA_ZERO_RESULT checks=%d failures=%d buildings=%d responses=%d routes=%d" % [
        checks,
        failures,
        game._v29_building_count(),
        game.v42_response_count,
        game.zero_route_commits
    ])

    game.queue_free()
    await process_frame
    if failures == 0:
        print("AXIVA_ZERO_OK")
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
        push_error("AXIVA_ZERO_FAILED: " + message)
