extends "res://main_v07.gd"

# MACHI LOOP v0.8 — short/long city goals + hardened persistence.
# Keeps v0.3-v0.7 simulation/presentation, adds a visible next objective and reward loop.

const V08_GOAL_COUNT: int = 7
const V08_GOAL_REWARDS = [80, 100, 120, 160, 200, 280, 400]
const V08_SAVE_SCHEMA_VERSION: int = 2
const V08_SAVE_TEMP_PATH: String = "user://machi_loop_save_v1.tmp"
const V08_SAVE_BACKUP_PATH: String = "user://machi_loop_save_v1.backup.json"

var v08_goal_stage: int = 0
var v08_goal_flash: float = 0.0
var v08_goal_flash_reward: int = 0

func _process(delta: float) -> void:
    super._process(delta)
    if v08_goal_flash > 0.0:
        v08_goal_flash = maxf(0.0, v08_goal_flash - delta)
        queue_redraw()

func _draw() -> void:
    super._draw()
    if v08_goal_flash > 0.0:
        _v08_draw_goal_complete()
    elif not (_all_road_cells().is_empty() and v08_goal_stage == 0):
        _v08_draw_goal_card()

func _simulation_tick() -> void:
    super._simulation_tick()
    _v08_evaluate_goal()

func _commit_arterial() -> void:
    super._commit_arterial()
    _v08_evaluate_goal()

func _widen(p: Vector2i) -> void:
    super._widen(p)
    _v08_evaluate_goal()

func _bulldoze(p: Vector2i) -> void:
    super._bulldoze(p)
    _v08_evaluate_goal()

func _v08_evaluate_goal() -> void:
    if v08_goal_stage >= V08_GOAL_COUNT:
        return
    if not _v08_goal_complete(v08_goal_stage):
        return

    var reward: int = int(V08_GOAL_REWARDS[v08_goal_stage])
    cash += reward
    v08_goal_stage += 1
    v08_goal_flash = 1.25
    v08_goal_flash_reward = reward
    v04_cash_flash = 0.85
    _toast("CITY GOAL COMPLETE  +Y%d" % reward)
    _v07_save_city()
    queue_redraw()

func _v08_goal_complete(stage: int) -> bool:
    match stage:
        0:
            return _count_cells(Cell.ARTERIAL) >= 6
        1:
            return population >= 26
        2:
            return jobs >= 16
        3:
            return population >= 52 and congestion <= 55.0
        4:
            return city_level >= 2
        5:
            return city_level >= 3
        6:
            return city_level >= 4
        _:
            return false

func _v08_goal_title(stage: int) -> String:
    match stage:
        0:
            return "BUILD THE SPINE"
        1:
            return "WELCOME RESIDENTS"
        2:
            return "CREATE JOBS"
        3:
            return "KEEP THE CITY FLOWING"
        4:
            return "UNLOCK DISTRICT 2"
        5:
            return "UNLOCK DISTRICT 3"
        6:
            return "OPEN THE WHOLE CITY"
        _:
            return "CORE CITY COMPLETE"

func _v08_goal_progress(stage: int) -> float:
    match stage:
        0:
            return clampf(float(_count_cells(Cell.ARTERIAL)) / 6.0, 0.0, 1.0)
        1:
            return clampf(float(population) / 26.0, 0.0, 1.0)
        2:
            return clampf(float(jobs) / 16.0, 0.0, 1.0)
        3:
            if population < 52:
                return clampf(float(population) / 52.0, 0.0, 0.82)
            return clampf(0.82 + (1.0 - clampf(congestion / 100.0, 0.0, 1.0)) * 0.18, 0.82, 1.0)
        4:
            return clampf(float(population) / 90.0, 0.0, 1.0)
        5:
            return clampf(float(population) / 200.0, 0.0, 1.0)
        6:
            return clampf(float(population) / 360.0, 0.0, 1.0)
        _:
            return 1.0

func _v08_goal_progress_text(stage: int) -> String:
    match stage:
        0:
            return "%d / 6 ROAD CELLS" % _count_cells(Cell.ARTERIAL)
        1:
            return "%d / 26 POP" % population
        2:
            return "%d / 16 JOBS" % jobs
        3:
            if population < 52:
                return "%d / 52 POP" % population
            return "TRAFFIC %d%%  -  TARGET <=55%%" % int(congestion)
        4:
            return "%d / 90 POP" % population
        5:
            return "%d / 200 POP" % population
        6:
            return "%d / 360 POP" % population
        _:
            return "ALL CORE GOALS COMPLETE"

func _v08_draw_goal_card() -> void:
    var font: Font = ThemeDB.fallback_font
    var w: float = minf(board_rect.size.x - 24.0, 330.0)
    var h: float = 58.0
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.end.y - h - 10.0, w, h)
    draw_rect(Rect2(rect.position + Vector2(0.0, 3.0), rect.size), Color(0.04, 0.09, 0.07, 0.15))
    draw_rect(rect, Color(0.055, 0.14, 0.105, 0.94))
    draw_rect(rect, Color("#42705B"), false, 1.0)

    if v08_goal_stage >= V08_GOAL_COUNT:
        draw_string(font, rect.position + Vector2(12.0, 24.0), "CITY GOALS", HORIZONTAL_ALIGNMENT_LEFT, 100.0, 9, Color("#86B89F"))
        draw_string(font, rect.position + Vector2(12.0, 44.0), "CORE CITY COMPLETE", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 14, Color("#E9FFF2"))
        return

    var reward: int = int(V08_GOAL_REWARDS[v08_goal_stage])
    draw_string(font, rect.position + Vector2(12.0, 15.0), "CITY GOAL %d/%d" % [v08_goal_stage + 1, V08_GOAL_COUNT], HORIZONTAL_ALIGNMENT_LEFT, 120.0, 8, Color("#86B89F"))
    draw_string(font, rect.position + Vector2(rect.size.x - 72.0, 15.0), "+Y%d" % reward, HORIZONTAL_ALIGNMENT_RIGHT, 60.0, 9, Color("#FFE28C"))
    draw_string(font, rect.position + Vector2(12.0, 34.0), _v08_goal_title(v08_goal_stage), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 13, Color("#F4FFF8"))
    draw_string(font, rect.position + Vector2(12.0, 50.0), _v08_goal_progress_text(v08_goal_stage), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 9, Color("#B9DDCB"))

    var bar: Rect2 = Rect2(rect.position.x + 12.0, rect.end.y - 5.0, rect.size.x - 24.0, 3.0)
    draw_rect(bar, Color("#28483A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * _v08_goal_progress(v08_goal_stage), bar.size.y)), Color("#71D0A2"))

func _v08_draw_goal_complete() -> void:
    var font: Font = ThemeDB.fallback_font
    var alpha: float = clampf(v08_goal_flash / 0.35, 0.0, 1.0)
    var w: float = minf(board_rect.size.x - 28.0, 320.0)
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.get_center().y - 39.0, w, 78.0)
    draw_rect(Rect2(rect.position + Vector2(0.0, 5.0), rect.size), Color(0.03, 0.08, 0.05, 0.22 * alpha))
    draw_rect(rect, Color(0.05, 0.16, 0.11, 0.96 * alpha))
    draw_rect(rect, Color(0.44, 0.89, 0.65, alpha), false, 3.0)
    draw_string(font, rect.position + Vector2(0.0, 31.0), "CITY GOAL COMPLETE", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, Color(0.96, 1.0, 0.97, alpha))
    draw_string(font, rect.position + Vector2(0.0, 57.0), "+Y%d  -  NEXT GOAL READY" % v08_goal_flash_reward, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, Color(1.0, 0.89, 0.55, alpha))

func _v08_infer_goal_stage_from_state() -> int:
    var inferred: int = 0
    while inferred < V08_GOAL_COUNT and _v08_goal_complete(inferred):
        inferred += 1
    return inferred

# v0.8 also upgrades the v0.7 save to the project Save Safety rule:
# schema_version, SHA-256 integrity, temp-file replacement, backup and legacy migration.
func _v07_save_city() -> void:
    if not _v07_has_meaningful_state() and not FileAccess.file_exists(SAVE_PATH):
        return

    var payload: Dictionary = {
        "grid": grid,
        "widened": widened.duplicate(true),
        "cash": cash,
        "unlocked_cols": unlocked_cols,
        "city_level": city_level,
        "tick_count": tick_count,
        "first_growth_seeded": v04_first_growth_seeded,
        "rng_state": str(rng.state),
        "goal_stage": v08_goal_stage
    }
    var payload_json: String = JSON.stringify(payload)
    var envelope: Dictionary = {
        "schema_version": V08_SAVE_SCHEMA_VERSION,
        "payload_json": payload_json,
        "checksum": payload_json.sha256_text()
    }

    var temp_file: FileAccess = FileAccess.open(V08_SAVE_TEMP_PATH, FileAccess.WRITE)
    if temp_file == null:
        return
    temp_file.store_string(JSON.stringify(envelope))
    temp_file.close()

    if FileAccess.file_exists(SAVE_PATH):
        if DirAccess.rename_absolute(SAVE_PATH, V08_SAVE_BACKUP_PATH) != OK:
            return

    if DirAccess.rename_absolute(V08_SAVE_TEMP_PATH, SAVE_PATH) != OK:
        if FileAccess.file_exists(V08_SAVE_BACKUP_PATH):
            DirAccess.rename_absolute(V08_SAVE_BACKUP_PATH, SAVE_PATH)
        return

    v07_last_saved_tick = tick_count

func _v07_load_city() -> bool:
    if _v08_load_from_path(SAVE_PATH):
        return true
    if _v08_load_from_path(V08_SAVE_BACKUP_PATH):
        _v07_save_city()
        return true
    return false

func _v08_load_from_path(path: String) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return false
    var raw: String = file.get_as_text()
    file.close()

    var parsed: Variant = JSON.parse_string(raw)
    if not parsed is Dictionary:
        return false
    var root: Dictionary = parsed as Dictionary

    if int(root.get("schema_version", 0)) == V08_SAVE_SCHEMA_VERSION:
        var payload_json: String = str(root.get("payload_json", ""))
        if payload_json.is_empty():
            return false
        if payload_json.sha256_text() != str(root.get("checksum", "")):
            return false
        var payload_variant: Variant = JSON.parse_string(payload_json)
        if not payload_variant is Dictionary:
            return false
        return _v08_apply_payload(payload_variant as Dictionary, false)

    if int(root.get("version", 0)) == 1:
        return _v08_apply_payload(root, true)
    return false

func _v08_apply_payload(data: Dictionary, legacy: bool) -> bool:
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
    v08_goal_stage = _v08_infer_goal_stage_from_state() if legacy else clampi(int(data.get("goal_stage", 0)), 0, V08_GOAL_COUNT)
    v07_last_saved_tick = tick_count
    return true
