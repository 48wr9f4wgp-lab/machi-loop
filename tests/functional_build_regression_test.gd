extends SceneTree

const SAVE_PATH: String = "user://machi_loop_save_v1.json"
const SAVE_TEMP: String = "user://machi_loop_save_v1.tmp"
const SAVE_BACKUP: String = "user://machi_loop_save_v1.backup.json"
const FTUE_PATH: String = "user://machi_loop_ftue_v1.json"
const FTUE_TEMP: String = "user://machi_loop_ftue_v1.tmp"

func _init() -> void:
    _cleanup()
    var game_script: Script = load("res://main.gd") as Script
    _require(game_script != null, "main.gd must load")

    var game: Node = game_script.new() as Node
    game._init_grid()
    game.rng.seed = 210021
    _require(int(game.cash) == 700 and int(game.city_level) == 1, "fresh city state invalid")
    _require(game._all_road_cells().is_empty(), "fresh city must have no roads")

    # Player verb: draw a meaningful arterial spine.
    game.drag_path = []
    for x: int in range(1, 7):
        game.drag_path.append(Vector2i(x, 10))
    game._commit_arterial()
    _require(int(game._count_cells(1)) >= 6, "main-road commit failed")
    _require(int(game.cash) < 700, "road construction did not charge cash")
    _require(int(game.v08_goal_stage) >= 1, "first road reward/goal did not trigger")

    # City must react and keep growing without manual local-road/building placement.
    for _i: int in range(18):
        game._simulation_tick()
    _require(int(game.population) > 0, "city did not auto-grow residents")
    _require(int(game.jobs) >= 0, "job state became invalid")
    _require(float(game.congestion) >= 0.0 and float(game.congestion) <= 100.0, "traffic escaped valid range")
    _require(int(game.v15_residential_demand) >= 0 and int(game.v15_residential_demand) <= 100, "residential demand invalid")
    _require(int(game.v15_commercial_demand) >= 0 and int(game.v15_commercial_demand) <= 100, "commercial demand invalid")
    _require(int(game.v15_industrial_demand) >= 0 and int(game.v15_industrial_demand) <= 100, "industrial demand invalid")
    _require(int(game.cash) >= 0, "economy persisted negative cash")

    # Road improvement and recovery tools must remain functional.
    var arterial: Vector2i = Vector2i(1, 10)
    game.cash = maxi(int(game.cash), 500)
    game._widen(arterial)
    _require(bool(game.widened.has(game._key(arterial))), "widening did not persist on road")
    var cash_before_remove: int = int(game.cash)
    game._bulldoze(arterial)
    _require(int(game.grid[arterial.y][arterial.x]) == 0, "road removal failed")
    _require(not game.widened.has(game._key(arterial)), "removed road retained widened state")
    _require(int(game.cash) >= cash_before_remove, "road salvage recovery did not refund cash")

    # First management decision and tier-gated service capacity.
    game.cash = maxi(int(game.cash), 1000)
    game._v09_select_policy(1)
    _require(int(game.v09_policy) == 1, "policy selection failed")
    game.city_level = 2
    game._v18_toggle_service(0)
    _require(bool(game.v18_mobility), "tier-2 first service failed")
    game._v18_toggle_service(1)
    _require(not bool(game.v18_safety), "tier-2 service-slot limit failed")
    game.city_level = 3
    game._v18_toggle_service(1)
    _require(bool(game.v18_safety), "tier-3 second service failed")

    # The planned maximum tier must be mechanically reachable.
    var max_city: Node = game_script.new() as Node
    max_city._init_grid()
    max_city.cash = 20000
    max_city.unlocked_cols = 16
    var homes_added: int = 0
    for y: int in range(22):
        for x: int in range(16):
            if homes_added < 78:
                max_city.grid[y][x] = 3
                homes_added += 1
    max_city._recalculate_city()
    max_city._check_unlocks()
    _require(int(max_city.population) >= 1000, "fixture failed to create metropolitan population")
    _require(int(max_city.city_level) == 6, "metropolitan tier is unreachable")
    _require(int(max_city.unlocked_cols) == 16, "maximum tier did not retain full land access")

    _cleanup()
    print("FUNCTIONAL_BUILD_REGRESSION_OK")
    quit(0)

func _cleanup() -> void:
    for path: String in [SAVE_PATH, SAVE_TEMP, SAVE_BACKUP, FTUE_PATH, FTUE_TEMP]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("FUNCTIONAL_BUILD_REGRESSION_FAILED: " + message)
    _cleanup()
    quit(1)
