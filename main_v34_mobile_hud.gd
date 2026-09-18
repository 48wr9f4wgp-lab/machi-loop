extends "res://main_v33_reset_control.gd"

# AXIVA v0.34 — iPhone-visible HUD / reset placement.
# Safari can expose a vertically clipped canvas while browser chrome is expanded.
# Critical gameplay HUD therefore lives inside board_rect as an overlay instead
# of relying on viewport y=0. The export shell also prevents document scrolling.

const V34_HUD_INSET: float = 10.0
const V34_HUD_H: float = 42.0
const V34_CONTEXT_GAP: float = 6.0
const V34_CONTEXT_H: float = 32.0

func _v34_hud_rect() -> Rect2:
    return Rect2(
        board_rect.position + Vector2(V34_HUD_INSET, V34_HUD_INSET),
        Vector2(maxf(1.0, board_rect.size.x - V34_HUD_INSET * 2.0), V34_HUD_H)
    )

func _v34_context_rect() -> Rect2:
    var hud: Rect2 = _v34_hud_rect()
    var pill_w: float = minf(board_rect.size.x - 28.0, 330.0)
    return Rect2(
        Vector2(board_rect.get_center().x - pill_w * 0.5, hud.end.y + V34_CONTEXT_GAP),
        Vector2(pill_w, V34_CONTEXT_H)
    )

func _v33_reset_rect() -> Rect2:
    var hud: Rect2 = _v34_hud_rect()
    return Rect2(
        hud.end.x - V33_RESET_W - 5.0,
        hud.position.y + (hud.size.y - V33_RESET_H) * 0.5,
        V33_RESET_W,
        V33_RESET_H
    )

func _v23_draw_city_first_shell() -> void:
    var size: Vector2 = get_viewport_rect().size
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font

    # Keep the reserved top strip as visual breathing room, but no critical
    # information depends on it being visible in mobile Safari.
    var top: Rect2 = Rect2(0.0, 0.0, size.x, V24_TOP_H)
    draw_rect(top, Color("#F3F0E6"))
    draw_line(Vector2(0.0, top.end.y), Vector2(size.x, top.end.y), Color("#CFD5CB"), 1.0)

    var hud: Rect2 = _v34_hud_rect()
    draw_rect(hud, Color(0.96, 0.95, 0.90, 0.94))
    draw_rect(hud, Color("#AAB7AE"), false, 1.0)

    draw_string(
        font,
        hud.position + Vector2(10.0, 18.0),
        "AXIVA",
        HORIZONTAL_ALIGNMENT_LEFT,
        92.0,
        15,
        Color("#173E30")
    )
    draw_string(
        font,
        hud.position + Vector2(10.0, 34.0),
        _v23_stage_name(),
        HORIZONTAL_ALIGNMENT_LEFT,
        150.0,
        8,
        Color("#667D70")
    )

    var reset_rect: Rect2 = _v33_reset_rect()
    var metric_right: float = reset_rect.position.x - 8.0
    var metric_left: float = hud.position.x + 162.0
    var metric_w: float = maxf(70.0, metric_right - metric_left)
    draw_string(
        font,
        Vector2(metric_left, hud.position.y + 18.0),
        "人口 %d" % population,
        HORIZONTAL_ALIGNMENT_RIGHT,
        metric_w,
        9,
        Color("#214638")
    )
    draw_string(
        font,
        Vector2(metric_left, hud.position.y + 34.0),
        "¥%d" % cash,
        HORIZONTAL_ALIGNMENT_RIGHT,
        metric_w,
        9,
        Color("#214638")
    )

    var message: String = _v23_context_message()
    if not message.is_empty():
        var pill: Rect2 = _v34_context_rect()
        draw_rect(pill, Color(0.055, 0.16, 0.115, 0.90))
        draw_string(
            font,
            pill.position + Vector2(10.0, 21.0),
            message,
            HORIZONTAL_ALIGNMENT_CENTER,
            pill.size.x - 20.0,
            9,
            Color("#F7FFF9")
        )

    var bottom: Rect2 = Rect2(0.0, size.y - V24_BOTTOM_H, size.x, V24_BOTTOM_H)
    draw_rect(bottom, Color("#F3F0E6"))
    draw_line(Vector2(0.0, bottom.position.y), Vector2(size.x, bottom.position.y), Color("#CFD5CB"), 1.0)
    _v23_draw_primary_tools(bottom, font)
