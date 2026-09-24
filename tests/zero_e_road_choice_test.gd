extends SceneTree

const Probe = preload("res://tests/zero_e_probe.gd")
const Model = preload("res://domain/zero_e_road_choice.gd")
var checks: int = 0
var failures: int = 0
var paths: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(430, 932)
    var game: Node = Probe.new()
    paths.assign([game.SAVE_PATH, game.V08_SAVE_BACKUP_PATH, game.V20_FTUE_SAVE_PATH])
    for path: String in paths:
        var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
        file.store_string("normal-save-sentinel:" + path)
        file.close()
    var before_save: String = fingerprint()
    root.add_child(game)
    await process_frame
    await process_frame
    game.set_process(false)
    for child: Node in game.get_children():
        if child is Timer:
            child.stop()
    require(game.zero_e_session and game.v37_recovery_session and not game.zero_d_session and not game.zero_c_session, "E isolation")
    require(game._zero_e_query_requests("?build=x&zero=e") and not game._zero_e_query_requests("?zero=else"), "E activation query")
    require(game.GRID_W == 16 and game.GRID_H == 22, "E must remain compact")
    require(game.zero_e_state["routes"].size() == 1 and float(game.zero_e_state["peak"]) > 1.0, "seed lacks actual bottleneck")
    require(not game.zero_e_state["hotspots"].is_empty(), "seed lacks spatial hotspot")
    require(fingerprint() == before_save and not game._v07_load_city(), "E read normal save")
    var before: float = float(game.zero_e_state["peak"])
    # An isolated or cosmetic spur cannot relieve a real route bottleneck.
    road(game, Vector2i(2, 3), Vector2i(5, 3))
    require(game.zero_e_state["routes"].size() == 1 and is_equal_approx(float(game.zero_e_state["peak"]), before), "unrelated spur relieved traffic")
    game._v37_seed_recovery_fixture()
    road(game, Vector2i(6, 10), Vector2i(6, 9))
    road(game, Vector2i(6, 9), Vector2i(8, 9))
    road(game, Vector2i(8, 9), Vector2i(8, 10))
    require(game.zero_e_state["routes"].size() == 1 and float(game.zero_e_state["peak"]) > 1.0, "tiny ornamental loop relieved through traffic")
    game._v37_seed_recovery_fixture()
    for mode: int in [0, 1]:
        if mode == 1:
            game._v37_seed_recovery_fixture()
        var row: int = 7 if mode == 0 else 13
        road(game, Vector2i(3, 10), Vector2i(3, row))
        road(game, Vector2i(3, row), Vector2i(12, row))
        require(game.zero_e_state["routes"].size() == 1, "one-ended route already solved traffic")
        road(game, Vector2i(12, row), Vector2i(12, 10))
        print("ZERO_E_ROUTE mode=%d peak=%.2f" % [mode, game.zero_e_state["peak"]])
        require(game.zero_e_state["routes"].size() == 2, "player-created bypass did not become a route")
        require(float(game.zero_e_state["peak"]) < before - 0.4 and game.zero_e_state["hotspots"].is_empty(), "bypass did not actually distribute load")
        var initial: int = game._v29_building_count()
        for i: int in range(4):
            game._simulation_tick()
        require(game._v29_building_count() > initial, "recovered access did not grow")
        var appeared: bool = false
        for y: int in range(game.GRID_H):
            for x: int in range(game.GRID_W):
                if y < 10 and mode == 0 and int(game.grid[y][x]) == game.Cell.COMMERCIAL and y != 6:
                    appeared = true
                if y > 10 and mode == 1 and int(game.grid[y][x]) == game.Cell.RESIDENTIAL and y != 12:
                    appeared = true
        require(appeared, "route-side growth failed for option %d" % mode)
        game.current_tool = game.Tool.BULLDOZE
        tap(game, game._v27_project_cell(Vector2i(8, row), 0))
        require(game.zero_e_state["routes"].size() == 1 and float(game.zero_e_state["peak"]) > 1.0, "cutting bypass did not restore traffic pressure")
    game._v07_save_city()
    game._v20_save_ftue()
    game._v33_delete_persistent_city_state()
    require(fingerprint() == before_save, "E mutated normal save or reset")
    game.queue_free()
    await process_frame
    require(fingerprint() == before_save, "E exit mutated save")
    print("AXIVA_ZERO_E_RESULT checks=%d failures=%d" % [checks, failures])
    if failures == 0:
        print("AXIVA_ZERO_E_OK")
    quit(0 if failures == 0 else 1)

func road(game: Node, a: Vector2i, b: Vector2i) -> void:
    game.current_tool = game.Tool.ROAD
    var start: Vector2 = game._v27_project_cell(a, 0)
    var finish: Vector2 = game._v27_project_cell(b, 0)
    require(game._v41_world_area().has_point(start) and game._v41_world_area().has_point(finish), "road endpoints outside viewport")
    touch(game, start, true)
    var drag: InputEventScreenDrag = InputEventScreenDrag.new()
    drag.index = 0
    drag.position = finish
    game._unhandled_input(drag)
    touch(game, finish, false)
    require(int(game.grid[b.y][b.x]) == game.Cell.ARTERIAL, "real touch could not draw road at %s" % b)

func touch(game: Node, pos: Vector2, pressed: bool) -> void:
    var event: InputEventScreenTouch = InputEventScreenTouch.new()
    event.index = 0
    event.position = pos
    event.pressed = pressed
    game._unhandled_input(event)

func tap(game: Node, pos: Vector2) -> void:
    touch(game, pos, true)
    touch(game, pos, false)

func fingerprint() -> String:
    var result: String = ""
    for path: String in paths:
        result += FileAccess.get_file_as_string(path)
    return result

func require(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("AXIVA_ZERO_E_FAILED: " + message)
