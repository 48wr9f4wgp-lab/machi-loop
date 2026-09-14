extends SceneTree

const SAVE_PATH: String = "user://machi_loop_save_v1.json"
const SAVE_TEMP_PATH: String = "user://machi_loop_save_v1.tmp"
const SAVE_BACKUP_PATH: String = "user://machi_loop_save_v1.backup.json"

func _init() -> void:
    _cleanup()
    var game_script: Script = load("res://main.gd") as Script
    var controller_script: Script = load("res://feedback/feedback_controller.gd") as Script
    if game_script == null or controller_script == null:
        _fail("scripts did not load")
        return

    var first: Node = game_script.new() as Node
    first.v22_feedback = controller_script.new()
    first._init_grid()
    first.grid[0][0] = 1
    first.cash = 612
    first.v22_feedback.settings.sfx_enabled = false
    first.v22_feedback.settings.sfx_volume = 0.35
    first.v22_feedback.settings.haptics_enabled = false
    first._v07_save_city()

    var saved: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if saved == null:
        _fail("schema 6 save missing")
        return
    var root_variant: Variant = JSON.parse_string(saved.get_as_text())
    saved.close()
    if not root_variant is Dictionary or int((root_variant as Dictionary).get("schema_version", 0)) != 6:
        _fail("city save did not migrate to schema 6")
        return

    var second: Node = game_script.new() as Node
    second.v22_feedback = controller_script.new()
    second._init_grid()
    if not second._v07_load_city():
        _fail("schema 6 save did not reload")
        return
    if int(second.cash) != 612:
        _fail("base state lost")
        return
    if bool(second.v22_feedback.settings.sfx_enabled):
        _fail("sfx toggle lost")
        return
    if not is_equal_approx(float(second.v22_feedback.settings.sfx_volume), 0.35):
        _fail("sfx volume lost")
        return
    if bool(second.v22_feedback.settings.haptics_enabled):
        _fail("haptics toggle lost")
        return

    _cleanup()
    print("FEEDBACK_SAVE_MIGRATION_OK")
    quit(0)

func _cleanup() -> void:
    for path: String in [SAVE_PATH, SAVE_TEMP_PATH, SAVE_BACKUP_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)

func _fail(message: String) -> void:
    push_error("FEEDBACK_SAVE_MIGRATION_FAILED: " + message)
    _cleanup()
    quit(1)
