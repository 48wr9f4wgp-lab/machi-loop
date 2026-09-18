extends SceneTree

const GameClass = preload("res://main_v30_fresh_test_mode.gd")

func _init() -> void:
    var game = GameClass.new()

    _expect(game._v30_query_requests_fresh("?fresh=1"), "fresh=1 must enable fresh mode")
    _expect(game._v30_query_requests_fresh("?v=30&fresh=1&utm_source=device"), "fresh=1 must survive other query params")
    _expect(not game._v30_query_requests_fresh("?fresh=0"), "fresh=0 must not enable fresh mode")
    _expect(not game._v30_query_requests_fresh("?refresh=1"), "refresh=1 must not false-positive")
    _expect(not game._v30_query_requests_fresh(""), "empty query must not enable fresh mode")

    # Verify fresh mode is non-destructive to the normal city save path.
    var sentinel: String = "{\"fresh_guard\":true}"
    var file: FileAccess = FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
    _expect(file != null, "fixture could not create sentinel save")
    if file != null:
        file.store_string(sentinel)
        file.close()

    game.v30_fresh_session = true
    _expect(not game._v07_load_city(), "fresh mode must bypass normal city restore")
    game._v07_save_city()

    var readback: FileAccess = FileAccess.open(game.SAVE_PATH, FileAccess.READ)
    _expect(readback != null, "fresh mode unexpectedly removed normal save")
    if readback != null:
        _expect(readback.get_as_text() == sentinel, "fresh mode modified normal save")
        readback.close()

    if FileAccess.file_exists(game.SAVE_PATH):
        DirAccess.remove_absolute(game.SAVE_PATH)

    print("V30_FRESH_TEST_MODE_OK")
    game.free()
    quit(0)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V30_FRESH_TEST_MODE_FAILED: " + message)
    quit(1)
