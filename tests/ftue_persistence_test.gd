extends SceneTree

const FTUE_PATH: String = "user://machi_loop_ftue_v1.json"
const FTUE_TEMP: String = "user://machi_loop_ftue_v1.tmp"

func _init() -> void:
    _cleanup()
    var game_script: Script = load("res://main.gd") as Script
    if game_script == null:
        _fail("main.gd did not load")
        return

    var first: Node = game_script.new() as Node
    first._init_grid()
    first.v20_ftue_stage = 3
    first._v20_save_ftue()
    if not FileAccess.file_exists(FTUE_PATH):
        _fail("FTUE sidecar was not created")
        return

    var second: Node = game_script.new() as Node
    second._init_grid()
    if int(second._v20_load_ftue_stage()) != 3:
        _fail("FTUE stage did not resume")
        return

    var corrupt: FileAccess = FileAccess.open(FTUE_PATH, FileAccess.WRITE)
    if corrupt == null:
        _fail("could not corrupt FTUE sidecar")
        return
    corrupt.store_string("{corrupt")
    corrupt.close()

    var recovered: Node = game_script.new() as Node
    recovered._init_grid()
    for x: int in range(6):
        recovered.grid[0][x] = 1
    if int(recovered._v20_load_ftue_stage()) != 1:
        _fail("corrupt FTUE sidecar did not recover from city state")
        return

    _cleanup()
    print("FTUE persistence fixture passed")
    quit(0)

func _cleanup() -> void:
    for path: String in [FTUE_PATH, FTUE_TEMP]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)

func _fail(message: String) -> void:
    push_error(message)
    _cleanup()
    quit(1)
