extends "res://main_v32_incremental_renderer.gd"

# AXIVA v0.33 — explicit city reset control.
# A compact two-tap RESET control is available inside the city viewport.
# Normal sessions delete city/FTUE persistence only after the second tap.
# ?fresh=1 sessions restart the ephemeral test scene without touching the
# player's normal save. Feedback settings are intentionally preserved.

const V33_RESET_ARM_SECONDS: float = 2.5
const V33_RESET_W: float = 72.0
const V33_RESET_H: float = 28.0

var v33_reset_armed_for: float = 0.0
var v33_reset_in_progress: bool = false
var v33_reset_request_count: int = 0
var v33_reset_execute_count: int = 0

func _process(delta: float) -> void:
    super._process(delta)
    if v33_reset_armed_for <= 0.0:
        return
    v33_reset_armed_for = maxf(0.0, v33_reset_armed_for - delta)
    queue_redraw()

func _draw() -> void:
    super._draw()
    _v33_draw_reset_control()

func _pointer_down(pos: Vector2) -> void:
    if _v33_reset_rect().has_point(pos):
        _v33_request_reset()
        return
    super._pointer_down(pos)

func _v33_reset_rect() -> Rect2:
    var x: float = board_rect.end.x - V33_RESET_W - 10.0
    var y: float = board_rect.position.y + 10.0
    return Rect2(x, y, V33_RESET_W, V33_RESET_H)

func _v33_draw_reset_control() -> void:
    if board_rect.size.x <= 1.0 or board_rect.size.y <= 1.0:
        return
    var rect: Rect2 = _v33_reset_rect()
    var armed: bool = v33_reset_armed_for > 0.0
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var bg: Color = Color(0.28, 0.10, 0.08, 0.92) if armed else Color(0.055, 0.13, 0.095, 0.82)
    var border: Color = Color(0.96, 0.45, 0.36, 0.95) if armed else Color(0.52, 0.66, 0.58, 0.80)
    draw_rect(rect, bg)
    draw_rect(rect, border, false, 1.0)
    draw_string(
        font,
        rect.position + Vector2(4.0, 19.0),
        "RESET?" if armed else "RESET",
        HORIZONTAL_ALIGNMENT_CENTER,
        rect.size.x - 8.0,
        9,
        Color("#F7FFF9")
    )

func _v33_request_reset() -> void:
    if v33_reset_in_progress:
        return
    v33_reset_request_count += 1
    if v33_reset_armed_for <= 0.0:
        v33_reset_armed_for = V33_RESET_ARM_SECONDS
        queue_redraw()
        return
    _v33_execute_reset()

func _v33_execute_reset() -> void:
    if v33_reset_in_progress:
        return
    v33_reset_in_progress = true
    v33_reset_armed_for = 0.0
    v33_reset_execute_count += 1

    # In fresh device-test mode the normal save is deliberately untouchable.
    # A reset only reloads a fresh ephemeral scene.
    if not v30_fresh_session:
        _v33_delete_persistent_city_state()

    var err: Error = get_tree().reload_current_scene()
    if err != OK:
        # Do not remain permanently save-suppressed if a host cannot reload.
        v33_reset_in_progress = false
        queue_redraw()

func _v33_delete_persistent_city_state() -> void:
    if v30_fresh_session:
        return
    for path: String in [
        SAVE_PATH,
        V08_SAVE_TEMP_PATH,
        V08_SAVE_BACKUP_PATH,
        V20_FTUE_SAVE_PATH,
        V20_FTUE_TEMP_PATH
    ]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)

# Scene reload invokes inherited exit hooks. Suppress city/FTUE writes while the
# destructive reset is in progress, otherwise those hooks would recreate the
# files that were just deleted.
func _v07_save_city() -> void:
    if v33_reset_in_progress:
        return
    super._v07_save_city()

func _v20_save_ftue() -> void:
    if v33_reset_in_progress:
        return
    super._v20_save_ftue()
