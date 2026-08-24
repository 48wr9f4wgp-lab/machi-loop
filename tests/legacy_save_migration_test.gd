extends SceneTree

const ProgressionModel = preload("res://domain/progression_model.gd")
const SAVE_PATH: String = "user://machi_loop_save_v1.json"
const SAVE_TEMP: String = "user://machi_loop_save_v1.tmp"
const SAVE_BACKUP: String = "user://machi_loop_save_v1.backup.json"

func _init() -> void:
    _cleanup()
    var legacy_script: Script = load("res://main_v18_services.gd") as Script
    var current_script: Script = load("res://main.gd") as Script
    _require(legacy_script != null and current_script != null, "migration scripts did not load")

    var legacy: Node = legacy_script.new() as Node
    legacy._init_grid()
    legacy.grid[0][0] = 1
    legacy.cash = 777
    legacy.city_level = 4
    legacy.unlocked_cols = 16
    legacy.v08_goal_stage = 7
    legacy.v09_policy = 2
    legacy.v18_mobility = true
    legacy.v18_safety = true
    legacy.v18_education = true
    legacy.v18_green = true
    legacy._v07_save_city()
    _require(FileAccess.file_exists(SAVE_PATH), "legacy schema save was not created")

    var current: Node = current_script.new() as Node
    current._init_grid()
    _require(bool(current._v07_load_city()), "current build could not load schema-v4 save")
    _require(int(current.cash) == 777, "cash changed during migration")
    _require(int(current.city_level) >= 4, "city tier regressed during migration")
    _require(int(current.unlocked_cols) == 16, "land unlock regressed during migration")
    _require(int(current.v09_policy) == 2, "policy changed during migration")
    _require(int(current._v19_active_service_count()) <= ProgressionModel.service_slots(int(current.city_level)), "legacy services violate new slot cap")
    _require(int(current._v20_load_ftue_stage()) == 4, "progressed legacy city should infer FTUE complete")

    current._v07_save_city()
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    _require(file != null, "migrated save could not be reopened")
    var raw: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(raw)
    _require(parsed is Dictionary, "migrated save is not valid JSON")
    _require(int((parsed as Dictionary).get("schema_version", 0)) == 5, "legacy save was not rewritten to schema v5")

    _cleanup()
    print("LEGACY_SAVE_MIGRATION_OK")
    quit(0)

func _cleanup() -> void:
    for path: String in [SAVE_PATH, SAVE_TEMP, SAVE_BACKUP]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("LEGACY_SAVE_MIGRATION_FAILED: " + message)
    _cleanup()
    quit(1)
