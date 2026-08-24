extends "res://main_v05.gd"

# MACHI LOOP v0.6 — hierarchy cleanup + less spreadsheet-like land presentation.
# Keeps simulation/game-feel from v0.3-v0.5 and changes presentation only.

func _draw() -> void:
    var size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#ECF2E9"))
    _draw_header(size)
    _draw_board()
    _draw_drag_preview()
    _draw_v04_effects()
    _draw_toolbar(size)

    var has_roads: bool = not _all_road_cells().is_empty()
    if not has_roads:
        _draw_v06_first_action_coach()
    elif banner_timer > 0.0:
        _draw_banner(size)

    if has_roads and congestion >= 68.0 and not paused:
        _draw_v05_traffic_hint()

    if v04_level_flash > 0.0:
        var alpha: float = clampf(v04_level_flash / 0.8, 0.0, 1.0) * 0.18
        draw_rect(board_rect.grow(7.0), Color(0.96, 0.76, 0.26, alpha), false, 5.0)

func _draw_header(size: Vector2) -> void:
    draw_rect(Rect2(0.0, 0.0, size.x, TOP_H), Color("#10261D"))
    draw_rect(Rect2(0.0, TOP_H - 3.0, size.x, 3.0), Color("#71D0A2"))
    var font: Font = ThemeDB.fallback_font

    draw_string(font, Vector2(MARGIN + 4.0, 28.0), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color("#F7FFF9"))
    draw_string(font, Vector2(MARGIN + 4.0, 47.0), "BUILD THE FLOW. LET THE CITY GROW.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("#9BC9B4"))

    var level_rect: Rect2 = Rect2(size.x - 68.0, 12.0, 54.0, 25.0)
    draw_rect(level_rect, Color("#1A3A2E"))
    draw_rect(level_rect, Color("#4D7865"), false, 1.0)
    draw_string(font, level_rect.position + Vector2(0.0, 18.0), "LV %d" % city_level, HORIZONTAL_ALIGNMENT_CENTER, level_rect.size.x, 11, Color("#DDF4E7"))

    var gap: float = 6.0
    var cards_x: float = MARGIN + 4.0
    var cards_w: float = size.x - (MARGIN + 4.0) * 2.0
    var card_w: float = (cards_w - gap * 2.0) / 3.0
    var card_h: float = 35.0
    var card_y: float = 56.0

    _draw_v06_stat_card(Rect2(cards_x, card_y, card_w, card_h), "POP", str(population), Color("#DDF4E7"))
    var cash_color: Color = Color("#FFE58C") if v04_cash_flash > 0.0 else Color("#F7FFF9")
    _draw_v06_stat_card(Rect2(cards_x + card_w + gap, card_y, card_w, card_h), "CASH", "Y%d" % cash, cash_color)
    var traffic_color: Color = Color("#AEE7C9")
    if congestion >= 75.0:
        traffic_color = Color("#FFAF8C")
    elif congestion >= 50.0:
        traffic_color = Color("#FFD28C")
    _draw_v06_stat_card(Rect2(cards_x + (card_w + gap) * 2.0, card_y, card_w, card_h), "TRAFFIC", "%d%%" % int(congestion), traffic_color)

    draw_string(font, Vector2(cards_x, 108.0), "IN +Y%d   HAPPY %d%%" % [tax_income, happiness], HORIZONTAL_ALIGNMENT_LEFT, 190.0, 11, Color("#BCE0CD"))
    var next_text: String = "MAX CITY" if city_level >= 4 else "NEXT %d/%d" % [population, _v04_next_unlock_target()]
    draw_string(font, Vector2(size.x - 132.0, 108.0), next_text, HORIZONTAL_ALIGNMENT_RIGHT, 116.0, 10, Color("#A6CCB9"))

    var bar: Rect2 = Rect2(cards_x, 115.0, cards_w, 6.0)
    draw_rect(bar, Color("#29463A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * _v04_unlock_progress(), bar.size.y)), Color("#71D0A2"))

func _draw_v06_stat_card(rect: Rect2, label: String, value: String, value_color: Color) -> void:
    var font: Font = ThemeDB.fallback_font
    draw_rect(rect, Color("#173329"))
    draw_rect(rect, Color("#315646"), false, 1.0)
    draw_string(font, rect.position + Vector2(8.0, 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 8, Color("#84B49E"))
    draw_string(font, rect.position + Vector2(8.0, 29.0), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 14, value_color)

func _draw_board() -> void:
    draw_rect(board_rect.grow(5.0), Color("#AFC0AB"), true)
    draw_rect(board_rect.grow(2.0), Color("#DCE7D8"), true)

    for y: int in range(GRID_H):
        for x: int in range(GRID_W):
            var p: Vector2i = Vector2i(x, y)
            var rect: Rect2 = _cell_rect(p)
            var locked: bool = x >= unlocked_cols
            if locked:
                draw_rect(rect, _v06_locked_land_color(p))
            else:
                var cell: int = int(grid[y][x])
                if cell == Cell.EMPTY:
                    draw_rect(rect, _v06_open_land_color(p))
                else:
                    draw_rect(rect, _cell_color(p))

            var minor_alpha: float = 0.055 if not locked else 0.035
            draw_rect(rect, Color(0.08, 0.14, 0.10, minor_alpha), false, 1.0)

            if not locked:
                _draw_cell_detail(p, rect)
            elif (x + y) % 5 == 0:
                draw_line(rect.position + Vector2(5.0, rect.size.y - 5.0), rect.position + Vector2(rect.size.x - 5.0, 5.0), Color(0.24, 0.30, 0.26, 0.07), 1.0)

    for bx: int in range(4, GRID_W, 4):
        var gx: float = board_origin.x + float(bx) * cell_size
        draw_line(Vector2(gx, board_origin.y), Vector2(gx, board_origin.y + board_rect.size.y), Color(0.08, 0.14, 0.10, 0.075), 1.0)
    for by: int in range(4, GRID_H, 4):
        var gy: float = board_origin.y + float(by) * cell_size
        draw_line(Vector2(board_origin.x, gy), Vector2(board_origin.x + board_rect.size.x, gy), Color(0.08, 0.14, 0.10, 0.075), 1.0)

    if unlocked_cols < GRID_W:
        var bx_line: float = board_origin.x + float(unlocked_cols) * cell_size
        draw_rect(Rect2(bx_line - 2.0, board_origin.y, 4.0, board_rect.size.y), Color("#D8A34C"))
        var locked_width: float = float(GRID_W - unlocked_cols) * cell_size
        if locked_width > 90.0:
            var badge: Rect2 = Rect2(bx_line + 10.0, board_origin.y + 14.0, minf(locked_width - 20.0, 120.0), 30.0)
            draw_rect(badge, Color(0.84, 0.64, 0.30, 0.16))
            draw_rect(badge, Color(0.64, 0.48, 0.22, 0.24), false, 1.0)
            var font: Font = ThemeDB.fallback_font
            draw_string(font, badge.position + Vector2(0.0, 20.0), "NEXT DISTRICT", HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 9, Color(0.36, 0.33, 0.24, 0.72))

func _v06_open_land_color(p: Vector2i) -> Color:
    var seed: int = abs((p.x * 41 + p.y * 73 + p.x * p.y * 5) % 11)
    if seed < 3:
        return Color("#D4E6CC")
    if seed < 7:
        return Color("#CFE2C7")
    return Color("#C9DEC2")

func _v06_locked_land_color(p: Vector2i) -> Color:
    var seed: int = abs((p.x * 19 + p.y * 47) % 7)
    if seed < 3:
        return Color("#DEE4DC")
    return Color("#E4E8E1")

func _draw_v06_first_action_coach() -> void:
    var font: Font = ThemeDB.fallback_font
    var pulse: float = 0.5 + 0.5 * sin(v04_time * 3.0)
    var w: float = minf(board_rect.size.x - 30.0, 326.0)
    var card: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + 18.0, w, 68.0)
    draw_rect(Rect2(card.position + Vector2(0.0, 4.0), card.size), Color(0.05, 0.11, 0.08, 0.16))
    draw_rect(card, Color(0.055, 0.14, 0.105, 0.95))
    draw_rect(card, Color(0.44, 0.84, 0.64, 0.55 + pulse * 0.30), false, 2.0)
    draw_rect(Rect2(card.position, Vector2(5.0, card.size.y)), Color("#71D0A2"))
    draw_string(font, card.position + Vector2(14.0, 27.0), "DRAW YOUR FIRST MAIN ROAD", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 28.0, 14, Color("#F4FFF8"))
    draw_string(font, card.position + Vector2(14.0, 48.0), "DRAG ACROSS THE GREEN LAND", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 90.0, 10, Color("#BDE4D1"))
    var y: float = card.position.y + 48.0
    var x2: float = card.end.x - 17.0
    draw_line(Vector2(x2 - 42.0, y), Vector2(x2, y), Color("#71D0A2"), 3.0)
    draw_line(Vector2(x2, y), Vector2(x2 - 8.0, y - 5.0), Color("#71D0A2"), 3.0)
    draw_line(Vector2(x2, y), Vector2(x2 - 8.0, y + 5.0), Color("#71D0A2"), 3.0)
