extends "res://main_v04.gd"

# MACHI LOOP v0.5 — first-session clarity + richer city presentation.
# Keeps v0.3 simulation and v0.4 feedback intact; this layer is presentation-only.

func _draw() -> void:
    super._draw()
    if _all_road_cells().is_empty():
        _draw_v05_first_action_coach()
    elif congestion >= 68.0 and not paused:
        _draw_v05_traffic_hint()

func _draw_header(size: Vector2) -> void:
    draw_rect(Rect2(0.0, 0.0, size.x, TOP_H), Color("#10261D"))
    draw_rect(Rect2(0.0, TOP_H - 3.0, size.x, 3.0), Color("#74D0A4"))
    var font: Font = ThemeDB.fallback_font

    draw_string(font, Vector2(MARGIN + 4.0, 30.0), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 25, Color("#F7FFF9"))
    draw_string(font, Vector2(MARGIN + 4.0, 50.0), "BUILD THE FLOW. LET THE CITY GROW.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#9BC9B4"))

    var cash_color: Color = Color("#FFE58C") if v04_cash_flash > 0.0 else Color("#F5FBF7")
    draw_string(font, Vector2(MARGIN + 4.0, 75.0), "POP %d" % population, HORIZONTAL_ALIGNMENT_LEFT, 92.0, 17, Color("#F5FBF7"))
    draw_string(font, Vector2(MARGIN + 105.0, 75.0), "CASH Y%d" % cash, HORIZONTAL_ALIGNMENT_LEFT, 150.0, 17, cash_color)
    draw_string(font, Vector2(size.x - 75.0, 75.0), "LV %d" % city_level, HORIZONTAL_ALIGNMENT_LEFT, 62.0, 17, Color("#F5FBF7"))

    var state_color: Color = Color("#BCEAD1")
    if congestion >= 75.0:
        state_color = Color("#FFB08F")
    elif happiness < 70:
        state_color = Color("#FFD58F")
    var state_text: String = "IN +Y%d    HAPPY %d%%    TRAFFIC %d%%" % [tax_income, happiness, int(congestion)]
    draw_string(font, Vector2(MARGIN + 4.0, 96.0), state_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 13, state_color)

    var bar: Rect2 = Rect2(MARGIN + 4.0, 104.0, size.x - (MARGIN + 4.0) * 2.0, 7.0)
    draw_rect(bar, Color("#29463A"))
    var progress: float = _v04_unlock_progress()
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color("#78D7AA"))
    var label: String = "ALL DISTRICTS OPEN" if city_level >= 4 else "NEXT AREA  %d / %d POP" % [population, _v04_next_unlock_target()]
    draw_string(font, Vector2(MARGIN + 4.0, 122.0), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 10, Color("#A6CCB9"))

func _draw_cell_detail(p: Vector2i, rect: Rect2) -> void:
    var cell: int = int(grid[p.y][p.x])
    if cell == Cell.EMPTY:
        _draw_v05_terrain_detail(p, rect)
        return
    super._draw_cell_detail(p, rect)

func _draw_v04_building(p: Vector2i, rect: Rect2, cell: int) -> void:
    var scale: float = _v04_growth_scale(p)
    var seed: int = (p.x * 17 + p.y * 31) % 7
    var center: Vector2 = rect.get_center()
    var footprint: Vector2 = rect.size * (0.62 + float(seed % 3) * 0.035) * scale
    var rise: float = cell_size * (0.10 + float(seed % 2) * 0.025) * scale
    var roof_center: Vector2 = center + Vector2(-rise * 0.28, -rise * 0.55)
    var roof_rect: Rect2 = Rect2(roof_center - footprint * 0.5, footprint)

    draw_rect(Rect2(center - footprint * 0.5 + Vector2(cell_size * 0.09, cell_size * 0.12), footprint), Color(0.07, 0.13, 0.10, 0.20))

    var wall: Color = Color("#EDEBD9")
    var roof: Color = Color("#77A96F")
    var side: Color = Color("#C7C7B4")
    if cell == Cell.COMMERCIAL:
        wall = Color("#E5F4F6")
        roof = Color("#4E9DBB")
        side = Color("#B9D7DA")
    elif cell == Cell.INDUSTRIAL:
        wall = Color("#EAD5AF")
        roof = Color("#A37B45")
        side = Color("#C4A477")

    var top_right: Vector2 = roof_rect.position + Vector2(roof_rect.size.x, 0.0)
    var bottom_right: Vector2 = roof_rect.position + roof_rect.size
    var bottom_left: Vector2 = roof_rect.position + Vector2(0.0, roof_rect.size.y)
    var drop: Vector2 = Vector2(rise * 0.34, rise)
    draw_colored_polygon(PackedVector2Array([top_right, bottom_right, bottom_right + drop, top_right + drop]), side.darkened(0.08))
    draw_colored_polygon(PackedVector2Array([bottom_left, bottom_right, bottom_right + drop, bottom_left + drop]), side)
    draw_rect(roof_rect, roof)
    draw_rect(roof_rect, Color(0.07, 0.14, 0.11, 0.24), false, 1.0)

    if cell == Cell.RESIDENTIAL:
        var porch: Rect2 = Rect2(roof_rect.position + Vector2(roof_rect.size.x * 0.34, roof_rect.size.y * 0.70), Vector2(roof_rect.size.x * 0.32, maxf(2.0, roof_rect.size.y * 0.18)))
        draw_rect(porch, wall)
        if seed % 2 == 0:
            draw_circle(roof_rect.position + Vector2(roof_rect.size.x * 0.18, roof_rect.size.y * 0.24), maxf(1.1, cell_size * 0.045), Color("#D9EFE1"))
    elif cell == Cell.COMMERCIAL:
        var glass: Rect2 = roof_rect.grow(-maxf(2.0, cell_size * 0.16))
        draw_rect(glass, Color("#BCE3EC"))
        draw_line(Vector2(glass.position.x, glass.get_center().y), Vector2(glass.end.x, glass.get_center().y), Color("#6FA9B7"), 1.0)
    else:
        var vent: Vector2 = roof_rect.position + Vector2(roof_rect.size.x * 0.72, roof_rect.size.y * 0.28)
        draw_rect(Rect2(vent, Vector2(maxf(2.0, cell_size * 0.09), maxf(3.0, cell_size * 0.18))), Color("#6F6B5D"))

func _draw_toolbar(size: Vector2) -> void:
    draw_rect(Rect2(0.0, size.y - BOTTOM_H, size.x, BOTTOM_H), Color("#F5F8F3"))
    draw_line(Vector2(0.0, size.y - BOTTOM_H), Vector2(size.x, size.y - BOTTOM_H), Color("#BBCDC0"), 1.0)
    var font: Font = ThemeDB.fallback_font
    var labels: Dictionary = {Tool.ROAD: "MAIN ROAD", Tool.WIDEN: "WIDEN", Tool.BULLDOZE: "REMOVE", 99: "PAUSE" if not paused else "RESUME"}
    var subs: Dictionary = {Tool.ROAD: "Y12 / CELL", Tool.WIDEN: "Y90 / ROAD", Tool.BULLDOZE: "Y8 / CELL", 99: "CITY CLOCK"}
    for id: Variant in tool_rects.keys():
        var rect: Rect2 = tool_rects[id] as Rect2
        var active: bool = int(id) == current_tool and int(id) != 99
        var bg: Color = Color("#173D2F") if active else Color("#FFFFFF")
        var fg: Color = Color.WHITE if active else Color("#1A3329")
        var sub_fg: Color = Color("#BDE4D1") if active else Color("#73847B")
        draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.08, 0.16, 0.12, 0.12))
        draw_rect(rect, bg)
        draw_rect(rect, Color("#1A3329"), false, 2.0)
        if active:
            draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color("#78D7AA"))
        _draw_v05_tool_icon(int(id), rect, fg)
        draw_string(font, rect.position + Vector2(30.0, 27.0), str(labels[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 38.0, 14, fg)
        draw_string(font, rect.position + Vector2(30.0, 46.0), str(subs[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 38.0, 9, sub_fg)

func _draw_v05_tool_icon(id: int, rect: Rect2, color: Color) -> void:
    var c: Vector2 = rect.position + Vector2(25.0, rect.size.y * 0.50)
    if id == Tool.ROAD:
        draw_line(c + Vector2(-8.0, 5.0), c + Vector2(8.0, -5.0), color, 4.0)
        draw_line(c + Vector2(-5.0, 6.0), c + Vector2(11.0, -4.0), Color(1.0, 0.86, 0.42, color.a), 1.0)
    elif id == Tool.WIDEN:
        draw_line(c + Vector2(-8.0, -4.0), c + Vector2(8.0, -4.0), color, 3.0)
        draw_line(c + Vector2(-8.0, 4.0), c + Vector2(8.0, 4.0), color, 3.0)
    elif id == Tool.BULLDOZE:
        draw_line(c + Vector2(-7.0, -7.0), c + Vector2(7.0, 7.0), color, 3.0)
        draw_line(c + Vector2(7.0, -7.0), c + Vector2(-7.0, 7.0), color, 3.0)
    else:
        draw_rect(Rect2(c + Vector2(-6.0, -8.0), Vector2(4.0, 16.0)), color)
        draw_rect(Rect2(c + Vector2(2.0, -8.0), Vector2(4.0, 16.0)), color)

func _draw_v05_terrain_detail(p: Vector2i, rect: Rect2) -> void:
    var seed: int = abs((p.x * 92821 + p.y * 68917) % 97)
    if seed % 13 == 0:
        var c: Vector2 = rect.position + rect.size * Vector2(0.34, 0.42)
        var r: float = maxf(1.4, cell_size * 0.075)
        draw_circle(c + Vector2(-r * 0.7, 0.0), r, Color(0.27, 0.50, 0.31, 0.28))
        draw_circle(c + Vector2(r * 0.6, r * 0.1), r * 0.85, Color(0.22, 0.44, 0.27, 0.26))
        draw_rect(Rect2(c + Vector2(-0.7, r * 0.5), Vector2(1.4, r * 1.7)), Color(0.33, 0.29, 0.20, 0.22))
    elif seed % 17 == 0:
        var a: Vector2 = rect.position + rect.size * Vector2(0.24, 0.68)
        draw_line(a, a + Vector2(cell_size * 0.10, -cell_size * 0.12), Color(0.25, 0.46, 0.28, 0.24), 1.0)
        draw_line(a + Vector2(cell_size * 0.08, 0.0), a + Vector2(cell_size * 0.16, -cell_size * 0.10), Color(0.25, 0.46, 0.28, 0.20), 1.0)

func _draw_v05_first_action_coach() -> void:
    var font: Font = ThemeDB.fallback_font
    var pulse: float = 0.5 + 0.5 * sin(v04_time * 3.0)
    var w: float = minf(board_rect.size.x - 28.0, 320.0)
    var card: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + board_rect.size.y * 0.34, w, 82.0)
    draw_rect(Rect2(card.position + Vector2(0.0, 4.0), card.size), Color(0.05, 0.11, 0.08, 0.18))
    draw_rect(card, Color(0.06, 0.15, 0.11, 0.94))
    draw_rect(card, Color(0.46, 0.86, 0.67, 0.55 + pulse * 0.35), false, 2.0)
    draw_string(font, card.position + Vector2(0.0, 29.0), "START YOUR CITY", HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 16, Color("#F5FFF8"))
    draw_string(font, card.position + Vector2(0.0, 53.0), "DRAG ON THE MAP TO DRAW A MAIN ROAD", HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 11, Color("#BDE4D1"))
    var y: float = card.position.y + 67.0
    var x1: float = card.get_center().x - 44.0
    var x2: float = card.get_center().x + 44.0
    draw_line(Vector2(x1, y), Vector2(x2, y), Color("#78D7AA"), 3.0)
    draw_line(Vector2(x2, y), Vector2(x2 - 8.0, y - 5.0), Color("#78D7AA"), 3.0)
    draw_line(Vector2(x2, y), Vector2(x2 - 8.0, y + 5.0), Color("#78D7AA"), 3.0)

func _draw_v05_traffic_hint() -> void:
    var font: Font = ThemeDB.fallback_font
    var w: float = minf(board_rect.size.x - 24.0, 300.0)
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + 10.0, w, 39.0)
    draw_rect(rect, Color(0.34, 0.12, 0.07, 0.92))
    draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), Color("#FF916F"))
    draw_string(font, rect.position + Vector2(0.0, 26.0), "TRAFFIC RISING  -  WIDEN A MAIN ROAD", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Color("#FFF4EF"))
