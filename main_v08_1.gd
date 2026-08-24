extends "res://main_v08.gd"

# v0.8.1 — recovery guard: never overwrite the known-good backup with a corrupt main file.
func _v07_load_city() -> bool:
    if _v08_load_from_path(SAVE_PATH):
        return true
    if _v08_load_from_path(V08_SAVE_BACKUP_PATH):
        if FileAccess.file_exists(SAVE_PATH):
            if DirAccess.remove_absolute(SAVE_PATH) != OK:
                return true
        _v07_save_city()
        return true
    return false
