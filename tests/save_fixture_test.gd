extends SceneTree

const SAVE_PATH: String = "user://machi_loop_save_v1.json"
const SAVE_TEMP_PATH: String = "user://machi_loop_save_v1.tmp"
const SAVE_BACKUP_PATH: String = "user://machi_loop_save_v1.backup.json"

func _init() -> void:
    _cleanup()
    var game_script: Script = load("res://main.gd") as Script
    if game_script == null:
        _fail("main.gd did not load")
        return

    var first: Node = game_script.new() as Node
    first._init_grid()
    first.grid[0][0] = 1
    first.cash = 555
    first.v08_goal_stage = 2
    first.v09_policy = 1
    first.city_level = 5
    first.unlocked_cols = 16
    first.v18_mobility = true
    first.v18_green = true
    first._v07_save_city()
    if not FileAccess.file_exists(SAVE_PATH):
        _fail("first save was not created")
        return

    first.cash = 556
    first.v09_policy = 3
    first.city_level = 6
    first.unlocked_cols = 16
    first.v18_mobility = false
    first.v18_green = false
    first.v18_education = true
    first.v18_safety = true
    first._v07_save_city()
    if not FileAccess.file_exists(SAVE_BACKUP_PATH):
        _fail("backup save was not created")
        return

    var second: Node = game_script.new() as Node
    second._init_grid()
    if not second._v07_load_city():
        _fail("current save did not reload")
        return
    if int(second.cash) != 556 or int(second.v08_goal_stage) != 2 or int(second.v09_policy) != 3:
        _fail("current save restored wrong base state")
        return
    if int(second.city_level) != 6 or int(second.unlocked_cols) != 16:
        _fail("current save restored wrong progression state")
        return
    if bool(second.v18_mobility) or bool(second.v18_green) or not bool(second.v18_education) or not bool(second.v18_safety):
        _fail("current save restored wrong service state")
        return

    var corrupt: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if corrupt == null:
        _fail("could not open save for corruption fixture")
        return
    corrupt.store_string("{corrupt")
    corrupt.close()

    var recovered: Node = game_script.new() as Node
    recovered._init_grid()
    if not recovered._v07_load_city():
        _fail("backup recovery failed")
        return
    if int(recovered.cash) != 555 or int(recovered.v08_goal_stage) != 2 or int(recovered.v09_policy) != 1:
        _fail("backup recovery restored wrong base state")
        return
    if int(recovered.city_level) != 5 or int(recovered.unlocked_cols) != 16:
        _fail("backup recovery restored wrong progression state")
        return
    if not bool(recovered.v18_mobility) or not bool(recovered.v18_green) or bool(recovered.v18_education) or bool(recovered.v18_safety):
        _fail("backup recovery restored wrong service state")
        return

    var repaired: Node = game_script.new() as Node
    repaired._init_grid()
    if not repaired._v07_load_city():
        _fail("repaired main save did not reload")
        return
    if int(repaired.cash) != 555 or int(repaired.v09_policy) != 1:
        _fail("repaired main save has wrong state")
        return
    if int(repaired.city_level) != 5 or int(repaired.unlocked_cols) != 16:
        _fail("repaired main save lost progression state")
        return
    if not bool(repaired.v18_mobility) or not bool(repaired.v18_green):
        _fail("repaired main save lost service state")
        return

    _cleanup()
    print("SAVE_FIXTURE_OK")
    quit(0)

func _cleanup() -> void:
    for path: String in [SAVE_PATH, SAVE_TEMP_PATH, SAVE_BACKUP_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)

func _fail(message: String) -> void:
    push_error("SAVE_FIXTURE_FAILED: " + message)
    _cleanup()
    quit(1)
