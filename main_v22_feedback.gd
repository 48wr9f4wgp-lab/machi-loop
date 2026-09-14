extends "res://main_v21_assets.gd"

# MACHI LOOP v0.22A — feedback pass rebuilt from the GitHub baseline.
# Event-specific SFX, native-safe haptics and persisted player toggles.

const FeedbackControllerClass = preload("res://feedback/feedback_controller.gd")
const V22_SETTINGS_PATH: String = "user://machi_loop_feedback_v1.json"
const V22_SETTINGS_TEMP_PATH: String = "user://machi_loop_feedback_v1.tmp"
const V22_SETTINGS_SCHEMA: int = 1

var v22_feedback: FeedbackController

func _ready() -> void:
    super._ready()
    v22_feedback = FeedbackControllerClass.new()
    add_child(v22_feedback)
    _v22_load_settings()
    queue_redraw()

func _exit_tree() -> void:
    _v22_save_settings()
    super._exit_tree()

func _draw() -> void:
    super._draw()
    _v22_draw_feedback_settings()

func _pointer_down(pos: Vector2) -> void:
    var sfx_rect: Rect2 = _v22_sfx_rect()
    var haptic_rect: Rect2 = _v22_haptic_rect()
    if sfx_rect.has_point(pos):
        v22_feedback.settings.sfx_enabled = not v22_feedback.settings.sfx_enabled
        _v22_save_settings()
        queue_redraw()
        return
    if haptic_rect.has_point(pos):
        v22_feedback.settings.haptics_enabled = not v22_feedback.settings.haptics_enabled
        _v22_save_settings()
        queue_redraw()
        return
    super._pointer_down(pos)

func _commit_arterial() -> void:
    var new_count: int = 0
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if _in_bounds(p) and int(grid[p.y][p.x]) == Cell.EMPTY:
            new_count += 1
    var cash_before: int = cash
    super._commit_arterial()
    if new_count <= 0:
        return
    if cash < cash_before:
        v22_feedback.arterial_confirm()
    elif cash_before < new_count * ROAD_COST:
        v22_feedback.insufficient_funds()

func _widen(p: Vector2i) -> void:
    var valid_arterial: bool = _in_bounds(p) and int(grid[p.y][p.x]) == Cell.ARTERIAL
    var key: String = _key(p) if _in_bounds(p) else ""
    var was_widened: bool = not key.is_empty() and widened.has(key)
    var cash_before: int = cash
    super._widen(p)
    if valid_arterial and not was_widened and widened.has(key):
        v22_feedback.widened()
    elif valid_arterial and not was_widened and cash_before < WIDEN_COST:
        v22_feedback.insufficient_funds()

func _bulldoze(p: Vector2i) -> void:
    var before: int = int(grid[p.y][p.x]) if _in_bounds(p) else Cell.EMPTY
    super._bulldoze(p)
    if before != Cell.EMPTY and _in_bounds(p) and int(grid[p.y][p.x]) == Cell.EMPTY:
        v22_feedback.demolished()

func _v08_evaluate_goal() -> void:
    var before: int = v08_goal_stage
    super._v08_evaluate_goal()
    if v08_goal_stage > before:
        v22_feedback.goal_complete()

func _check_unlocks() -> void:
    var before: int = city_level
    super._check_unlocks()
    if city_level > before:
        v22_feedback.tier_up()

func _v22_draw_feedback_settings() -> void:
    if v22_feedback == null:
        return
    var font: Font = ThemeDB.fallback_font
    for item: Dictionary in [
        {"rect": _v22_sfx_rect(), "label": "SFX", "on": v22_feedback.settings.sfx_enabled},
        {"rect": _v22_haptic_rect(), "label": "HAPTIC", "on": v22_feedback.settings.haptics_enabled}
    ]:
        var rect: Rect2 = item["rect"] as Rect2
        var enabled: bool = bool(item["on"])
        draw_rect(rect, Color("#183A2D") if enabled else Color("#48534E"))
        draw_rect(rect, Color("#71D0A2") if enabled else Color("#7F8B85"), false, 1.0)
        draw_string(font, rect.position + Vector2(0.0, 14.0), "%s %s" % [str(item["label"]), "ON" if enabled else "OFF"], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 8, Color("#F4FFF8"))

func _v22_sfx_rect() -> Rect2:
    var size: Vector2 = get_viewport_rect().size
    return Rect2(size.x - 142.0, 126.0, 62.0, 20.0)

func _v22_haptic_rect() -> Rect2:
    var size: Vector2 = get_viewport_rect().size
    return Rect2(size.x - 74.0, 126.0, 62.0, 20.0)

func _v22_load_settings() -> void:
    if not FileAccess.file_exists(V22_SETTINGS_PATH):
        return
    var file: FileAccess = FileAccess.open(V22_SETTINGS_PATH, FileAccess.READ)
    if file == null:
        return
    var raw: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(raw)
    if not parsed is Dictionary:
        return
    var root: Dictionary = parsed as Dictionary
    if int(root.get("schema_version", 0)) != V22_SETTINGS_SCHEMA:
        return
    var payload_json: String = str(root.get("payload_json", ""))
    if payload_json.is_empty() or payload_json.sha256_text() != str(root.get("checksum", "")):
        return
    var payload_variant: Variant = JSON.parse_string(payload_json)
    if payload_variant is Dictionary:
        v22_feedback.apply_payload(payload_variant as Dictionary)

func _v22_save_settings() -> void:
    if v22_feedback == null:
        return
    var payload_json: String = JSON.stringify(v22_feedback.to_payload())
    var envelope: Dictionary = {
        "schema_version": V22_SETTINGS_SCHEMA,
        "payload_json": payload_json,
        "checksum": payload_json.sha256_text()
    }
    var file: FileAccess = FileAccess.open(V22_SETTINGS_TEMP_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(envelope))
    file.close()
    if FileAccess.file_exists(V22_SETTINGS_PATH):
        DirAccess.remove_absolute(V22_SETTINGS_PATH)
    DirAccess.rename_absolute(V22_SETTINGS_TEMP_PATH, V22_SETTINGS_PATH)
