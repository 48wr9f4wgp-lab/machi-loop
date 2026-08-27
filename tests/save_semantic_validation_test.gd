extends SceneTree

const SAVE_PATH: String = "user://machi_loop_save_v1.json"
const SAVE_TEMP: String = "user://machi_loop_save_v1.tmp"
const SAVE_BACKUP: String = "user://machi_loop_save_v1.backup.json"
const FTUE_PATH: String = "user://machi_loop_ftue_v1.json"
const FTUE_TEMP: String = "user://machi_loop_ftue_v1.tmp"

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _cleanup()
    var game_script: Script = load("res://main.gd") as Script
    if game_script == null:
        _fail("main.gd failed to load")
        return

    # Create two valid generations so the first one becomes the recovery backup.
    var source: Node = game_script.new() as Node
    source._init_grid()
    source.grid[0][0] = source.Cell.ARTERIAL
    source.cash = 321
    source._v07_save_city()
    if not FileAccess.file_exists(SAVE_PATH):
        _fail("first save missing")
        return
    source.cash = 654
    source._v07_save_city()
    if not FileAccess.file_exists(SAVE_BACKUP):
        _fail("backup generation missing")
        return

    # Keep the envelope/checksum structurally valid while injecting an impossible
    # cell enum. The current save must be rejected and backup recovery must win.
    var root: Dictionary = _read_envelope(SAVE_PATH)
    if root.is_empty():
        _fail("could not parse current envelope")
        return
    var payload: Dictionary = _read_payload(root)
    if payload.is_empty():
        _fail("could not parse current payload")
        return
    var bad_grid: Array = (payload.get("grid", []) as Array).duplicate(true)
    bad_grid[0][0] = 999
    payload["grid"] = bad_grid
    _write_payload_envelope(SAVE_PATH, root, payload)

    var recovered: Node = game_script.new() as Node
    recovered._init_grid()
    if not recovered._v07_load_city():
        _fail("semantic corruption did not recover from backup")
        return
    if int(recovered.cash) != 321:
        _fail("semantic corruption recovered wrong generation: %d" % int(recovered.cash))
        return
    if int(recovered.grid[0][0]) != recovered.Cell.ARTERIAL:
        _fail("backup road state was not restored")
        return

    # A stale widened key is not fatal. It should be sanitized if it points to an
    # ordinary building instead of an arterial road.
    recovered.grid[1][1] = recovered.Cell.RESIDENTIAL
    recovered.widened["1:1"] = true
    recovered._v07_save_city()

    var normalized: Node = game_script.new() as Node
    normalized._init_grid()
    if not normalized._v07_load_city():
        _fail("save containing stale widened reference was rejected")
        return
    if normalized.widened.has("1:1"):
        _fail("stale widened reference survived normalization")
        return
    if int(normalized.grid[1][1]) != normalized.Cell.RESIDENTIAL:
        _fail("widened normalization damaged ordinary development")
        return

    _cleanup()
    print("SAVE_SEMANTIC_VALIDATION_OK")
    quit(0)

func _read_envelope(path: String) -> Dictionary:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed as Dictionary if parsed is Dictionary else {}

func _read_payload(root: Dictionary) -> Dictionary:
    var payload_json: String = str(root.get("payload_json", ""))
    var parsed: Variant = JSON.parse_string(payload_json)
    return parsed as Dictionary if parsed is Dictionary else {}

func _write_payload_envelope(path: String, root: Dictionary, payload: Dictionary) -> void:
    var payload_json: String = JSON.stringify(payload)
    root["payload_json"] = payload_json
    root["checksum"] = payload_json.sha256_text()
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(root))
        file.close()

func _cleanup() -> void:
    for path: String in [SAVE_PATH, SAVE_TEMP, SAVE_BACKUP, FTUE_PATH, FTUE_TEMP]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)

func _fail(message: String) -> void:
    push_error("SAVE_SEMANTIC_VALIDATION_FAILED: " + message)
    _cleanup()
    quit(1)
