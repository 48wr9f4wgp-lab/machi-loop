extends SceneTree

const GameClass = preload("res://main_v33_reset_control.gd")

func _init() -> void:
    var game = GameClass.new()
    game._init_grid()

    _cleanup_city_files()

    # First tap only arms the destructive action.
    game._v33_request_reset()
    _expect(game.v33_reset_armed_for > 0.0, "first reset tap did not arm confirmation")
    _expect(game.v33_reset_execute_count == 0, "first reset tap executed destructive reset")

    # Fresh test mode must never delete a player's normal persisted city.
    _write_text(game.SAVE_PATH, "NORMAL_SAVE_SENTINEL")
    _write_text(game.V20_FTUE_SAVE_PATH, "FTUE_SENTINEL")
    game.v30_fresh_session = true
    game._v33_delete_persistent_city_state()
    _expect(_read_text(game.SAVE_PATH) == "NORMAL_SAVE_SENTINEL", "fresh reset deleted normal city save")
    _expect(_read_text(game.V20_FTUE_SAVE_PATH) == "FTUE_SENTINEL", "fresh reset deleted FTUE persistence")

    # Normal reset removes city/FTUE state and backup/temp files.
    game.v30_fresh_session = false
    _write_text(game.V08_SAVE_TEMP_PATH, "TEMP")
    _write_text(game.V08_SAVE_BACKUP_PATH, "BACKUP")
    _write_text(game.V20_FTUE_TEMP_PATH, "FTUE_TEMP")
    game._v33_delete_persistent_city_state()
    for path: String in [
        game.SAVE_PATH,
        game.V08_SAVE_TEMP_PATH,
        game.V08_SAVE_BACKUP_PATH,
        game.V20_FTUE_SAVE_PATH,
        game.V20_FTUE_TEMP_PATH
    ]:
        _expect(not FileAccess.file_exists(path), "reset left city persistence behind: " + path)

    # Feedback preferences are intentionally outside the reset scope.
    _write_text(game.V22_SETTINGS_PATH, "SETTINGS_SENTINEL")
    game._v33_delete_persistent_city_state()
    _expect(_read_text(game.V22_SETTINGS_PATH) == "SETTINGS_SENTINEL", "reset deleted feedback settings")

    # Exit-time persistence must be suppressed while reset is active.
    _write_text(game.SAVE_PATH, "SAVE_GUARD")
    _write_text(game.V20_FTUE_SAVE_PATH, "FTUE_GUARD")
    game.v33_reset_in_progress = true
    game._v07_save_city()
    game._v20_save_ftue()
    _expect(_read_text(game.SAVE_PATH) == "SAVE_GUARD", "reset exit hook rewrote city save")
    _expect(_read_text(game.V20_FTUE_SAVE_PATH) == "FTUE_GUARD", "reset exit hook rewrote FTUE save")

    _cleanup_city_files()
    if FileAccess.file_exists(game.V22_SETTINGS_PATH):
        DirAccess.remove_absolute(game.V22_SETTINGS_PATH)
    game.free()
    print("V33_RESET_CONTROL_OK")
    quit(0)

func _write_text(path: String, value: String) -> void:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    _expect(file != null, "could not create fixture file: " + path)
    if file == null:
        return
    file.store_string(value)
    file.close()

func _read_text(path: String) -> String:
    if not FileAccess.file_exists(path):
        return ""
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return ""
    var value: String = file.get_as_text()
    file.close()
    return value

func _cleanup_city_files() -> void:
    for path: String in [
        GameClass.SAVE_PATH,
        GameClass.V08_SAVE_TEMP_PATH,
        GameClass.V08_SAVE_BACKUP_PATH,
        GameClass.V20_FTUE_SAVE_PATH,
        GameClass.V20_FTUE_TEMP_PATH
    ]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V33_RESET_CONTROL_FAILED: " + message)
    quit(1)
