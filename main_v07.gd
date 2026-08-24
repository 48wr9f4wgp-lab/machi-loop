extends "res://main_v06.gd"

# MACHI LOOP v0.7 — persistent city save/resume layer.
# Keeps v0.3-v0.6 simulation and presentation intact.

const SAVE_PATH: String = "user://machi_loop_save_v1.json"
const SAVE_VERSION: int = 1
const AUTOSAVE_TICKS: int = 5

var v07_last_saved_tick: int = -AUTOSAVE_TICKS

func _ready() -> void:
    super._ready()
    if _v07_load_city():
        _toast("CITY RESTORED")
        queue_redraw()

func _simulation_tick() -> void:
    super._simulation_tick()
    if tick_count - v07_last_saved_tick >= AUTOSAVE_TICKS:
        _v07_save_city()

func _commit_arterial() -> void:
    super._commit_arterial()
    _v07_save_city()

func _widen(p: Vector2i) -> void:
    super._widen(p)
    _v07_save_city()

func _bulldoze(p: Vector2i) -> void:
    super._bulldoze(p)
    _v07_save_city()

func _exit_tree() -> void:
    _v07_save_city()

func _v07_has_meaningful_state() -> bool:
    return cash != 700 or population > 0 or city_level > 1 or not _all_road_cells().is_empty()

func _v07_save_city() -> void:
    if not _v07_has_meaningful_state() and not FileAccess.file_exists(SAVE_PATH):
        return

    var data: Dictionary = {
        "version": SAVE_VERSION,
        "grid": grid,
        "widened": widened.duplicate(true),
        "cash": cash,
        "unlocked_cols": unlocked_cols,
        "city_level": city_level,
        "tick_count": tick_count,
        "first_growth_seeded": v04_first_growth_seeded,
        "rng_state": str(rng.state)
    }

    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(data))
    file.close()
    v07_last_saved_tick = tick_count

func _v07_load_city() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false

    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var raw: String = file.get_as_text()
    file.close()

    var parsed: Variant = JSON.parse_string(raw)
    if not parsed is Dictionary:
        return false
    var data: Dictionary = parsed as Dictionary
    if int(data.get("version", 0)) != SAVE_VERSION:
        return false

    var saved_grid_variant: Variant = data.get("grid", [])
    if not saved_grid_variant is Array:
        return false
    var saved_grid: Array = saved_grid_variant as Array
    if saved_grid.size() != GRID_H:
        return false

    var restored_grid: Array = []
    for y: int in range(GRID_H):
        var row_variant: Variant = saved_grid[y]
        if not row_variant is Array:
            return false
        var source_row: Array = row_variant as Array
        if source_row.size() != GRID_W:
            return false
        var row: Array = []
        for x: int in range(GRID_W):
            row.append(int(source_row[x]))
        restored_grid.append(row)
    grid = restored_grid

    var saved_widened_variant: Variant = data.get("widened", {})
    if saved_widened_variant is Dictionary:
        widened = (saved_widened_variant as Dictionary).duplicate(true)
    else:
        widened.clear()

    cash = maxi(0, int(data.get("cash", 700)))
    unlocked_cols = clampi(int(data.get("unlocked_cols", START_UNLOCKED_COLS)), START_UNLOCKED_COLS, GRID_W)
    city_level = clampi(int(data.get("city_level", 1)), 1, 4)
    tick_count = maxi(0, int(data.get("tick_count", 0)))
    rng.state = int(str(data.get("rng_state", str(rng.state))))

    _recalculate_city()
    v04_first_growth_seeded = bool(data.get("first_growth_seeded", population > 0))
    v07_last_saved_tick = tick_count
    return true
