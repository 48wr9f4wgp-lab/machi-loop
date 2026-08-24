extends "res://main_mobile.gd"

# MACHI LOOP v0.4 — visual/game-feel layer over the stable v0.3 simulation.

var v04_time: float = 0.0
var v04_cash_flash: float = 0.0
var v04_level_flash: float = 0.0
var v04_first_growth_seeded: bool = false
var v04_cell_fx: Array = []

func _process(delta: float) -> void:
    super._process(delta)
    v04_time += delta
    v04_cash_flash = maxf(0.0, v04_cash_flash - delta)
    v04_level_flash = maxf(0.0, v04_level_flash - delta)
    for i: int in range(v04_cell_fx.size() - 1, -1, -1):
        var fx: Dictionary = v04_cell_fx[i] as Dictionary
        var life: float = float(fx["life"]) - delta
        if life <= 0.0:
            v04_cell_fx.remove_at(i)
        else:
            fx["life"] = life
            v04_cell_fx[i] = fx
    queue_redraw()

func _draw() -> void:
    var size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#EDF3EA"))
    _draw_header(size)
    _draw_board()
    _draw_drag_preview()
    _draw_v04_effects()
    _draw_toolbar(size)
    if banner_timer > 0.0:
        _draw_banner(size)
    if v04_level_flash > 0.0:
        var alpha: float = clampf(v04_level_flash / 0.8, 0.0, 1.0) * 0.18
        draw_rect(board_rect.grow(7.0), Color(0.96, 0.76, 0.26, alpha), false, 5.0)

func _draw_header(size: Vector2) -> void:
    draw_rect(Rect2(0.0, 0.0, size.x, TOP_H), Color("#14271F"))
    draw_rect(Rect2(0.0, TOP_H - 3.0, size.x, 3.0), Color("#7CC6A1"))
    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(MARGIN + 4.0, 31.0), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 27, Color.WHITE)
    draw_string(font, Vector2(MARGIN + 4.0, 53.0), "BUILD THE FLOW. LET THE CITY GROW.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#9FC5B3"))

    var cash_color: Color = Color("#FFE18A") if v04_cash_flash > 0.0 else Color("#F6FBF8")
    var line1: String = "POP %d   CASH Y%d   LV %d" % [population, cash, city_level]
    var line2: String = "IN +Y%d   HAPPY %d%%   TRAFFIC %d%%" % [tax_income, happiness, int(congestion)]
    draw_string(font, Vector2(MARGIN + 4.0, 79.0), line1, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, cash_color)

    var state_color: Color = Color("#D7E8DE")
    if congestion >= 75.0:
        state_color = Color("#FFB08F")
    elif happiness >= 90:
        state_color = Color("#AEE6C7")
    draw_string(font, Vector2(MARGIN + 4.0, 101.0), line2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, state_color)

    var bar: Rect2 = Rect2(MARGIN + 4.0, 112.0, size.x - (MARGIN + 4.0) * 2.0, 8.0)
    draw_rect(bar, Color("#294238"))
    var progress: float = _v04_unlock_progress()
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color("#7CC6A1"))
    var label: String = "ALL DISTRICTS OPEN" if city_level >= 4 else "NEXT AREA AT %d POP" % _v04_next_unlock_target()
    draw_string(font, Vector2(MARGIN + 4.0, 134.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#A9C7B9"))

func _draw_cell_detail(p: Vector2i, rect: Rect2) -> void:
    var cell: int = int(grid[p.y][p.x])
    if cell == Cell.ARTERIAL or cell == Cell.LOCAL:
        _draw_v04_road(p, rect, cell)
        return
    if cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
        _draw_v04_building(p, rect, cell)
        return
    if (p.x * 11 + p.y * 7) % 9 == 0:
        draw_circle(rect.position + rect.size * Vector2(0.28, 0.35), maxf(1.0, cell_size * 0.045), Color(0.27, 0.49, 0.30, 0.22))

func _draw_v04_road(p: Vector2i, rect: Rect2, cell: int) -> void:
    var center: Vector2 = rect.get_center()
    var road_w: float = rect.size.x * (0.42 if cell == Cell.LOCAL else 0.64)
    var half: float = road_w * 0.5
    var surface: Color = Color("#68746F") if cell == Cell.LOCAL else Color("#343E3A")
    draw_rect(Rect2(center - Vector2(half, half), Vector2(road_w, road_w)), surface)

    if _v04_is_road(p + Vector2i(1, 0)):
        draw_rect(Rect2(center.x, center.y - half, rect.position.x + rect.size.x - center.x, road_w), surface)
    if _v04_is_road(p + Vector2i(-1, 0)):
        draw_rect(Rect2(rect.position.x, center.y - half, center.x - rect.position.x, road_w), surface)
    if _v04_is_road(p + Vector2i(0, 1)):
        draw_rect(Rect2(center.x - half, center.y, road_w, rect.position.y + rect.size.y - center.y), surface)
    if _v04_is_road(p + Vector2i(0, -1)):
        draw_rect(Rect2(center.x - half, rect.position.y, road_w, center.y - rect.position.y), surface)

    if cell == Cell.ARTERIAL:
        var horizontal: bool = _v04_is_road(p + Vector2i(1, 0)) or _v04_is_road(p + Vector2i(-1, 0))
        if horizontal:
            draw_line(Vector2(rect.position.x + 2.0, center.y), Vector2(rect.position.x + rect.size.x - 2.0, center.y), Color("#EBD274"), maxf(1.0, cell_size * 0.045))
        else:
            draw_line(Vector2(center.x, rect.position.y + 2.0), Vector2(center.x, rect.position.y + rect.size.y - 2.0), Color("#EBD274"), maxf(1.0, cell_size * 0.045))
        if widened.has(_key(p)):
            draw_rect(rect.grow(-cell_size * 0.08), Color("#86DDC2"), false, maxf(2.0, cell_size * 0.065))
        if (p.x * 3 + p.y * 5) % 4 == 0:
            var travel: float = fmod(v04_time * 0.55 + float((p.x + p.y) % 5) * 0.19, 1.0)
            var car: Vector2 = center
            if horizontal:
                car.x = rect.position.x + 3.0 + (rect.size.x - 6.0) * travel
                car.y += road_w * 0.20
            else:
                car.y = rect.position.y + 3.0 + (rect.size.y - 6.0) * travel
                car.x += road_w * 0.20
            draw_circle(car, maxf(1.3, cell_size * 0.065), Color("#EAF7F0"))

    var heat: float = clampf(_road_load(p) / _road_capacity(p), 0.0, 1.5)
    if heat > 0.92:
        draw_rect(rect.grow(-cell_size * 0.03), Color(0.95, 0.33, 0.20, minf(0.42, (heat - 0.80) * 0.32)), false, maxf(1.0, cell_size * 0.055))

func _draw_v04_building(p: Vector2i, rect: Rect2, cell: int) -> void:
    var scale: float = _v04_growth_scale(p)
    var size: Vector2 = rect.size * 0.74 * scale
    var center: Vector2 = rect.get_center()
    var base: Rect2 = Rect2(center - size * 0.5, size)
    draw_rect(Rect2(base.position + Vector2(cell_size * 0.07, cell_size * 0.09), base.size), Color(0.10, 0.16, 0.13, 0.18))

    var wall: Color = Color("#F2F1E8")
    var roof: Color = Color("#77AA72")
    if cell == Cell.COMMERCIAL:
        wall = Color("#EDF8FC")
        roof = Color("#4F9DBD")
    elif cell == Cell.INDUSTRIAL:
        wall = Color("#F0DFC0")
        roof = Color("#A98249")
    draw_rect(base, wall)
    draw_rect(base, Color(0.10, 0.17, 0.14, 0.28), false, 1.0)
    draw_rect(Rect2(base.position, Vector2(base.size.x, maxf(2.0, base.size.y * 0.22))), roof)

    if base.size.x >= 10.0 and scale > 0.78:
        var wc: Color = Color("#507265") if cell != Cell.COMMERCIAL else Color("#4F86A0")
        var ws: Vector2 = Vector2(maxf(1.5, base.size.x * 0.13), maxf(1.5, base.size.y * 0.17))
        draw_rect(Rect2(base.position + Vector2(base.size.x * 0.22, base.size.y * 0.53), ws), wc)
        draw_rect(Rect2(base.position + Vector2(base.size.x * 0.64, base.size.y * 0.53), ws), wc)

func _draw_drag_preview() -> void:
    if not dragging or current_tool != Tool.ROAD:
        return
    var new_count: int = 0
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if _in_bounds(p) and p.x < unlocked_cols:
            var rect: Rect2 = _cell_rect(p).grow(-cell_size * 0.06)
            var valid: bool = int(grid[p.y][p.x]) in [Cell.EMPTY, Cell.ARTERIAL]
            if int(grid[p.y][p.x]) == Cell.EMPTY:
                new_count += 1
            draw_rect(rect, Color(0.20, 0.82, 0.65, 0.52) if valid else Color(0.92, 0.28, 0.20, 0.45))
            draw_rect(rect, Color(0.89, 1.0, 0.93, 0.68) if valid else Color(1.0, 0.80, 0.76, 0.55), false, 2.0)
    if new_count > 0:
        var font: Font = ThemeDB.fallback_font
        var pill: Rect2 = Rect2(board_rect.get_center().x - 66.0, board_rect.position.y + board_rect.size.y - 38.0, 132.0, 30.0)
        draw_rect(pill, Color(0.07, 0.14, 0.11, 0.92))
        draw_string(font, pill.position + Vector2(0.0, 21.0), "%d CELLS  -Y%d" % [new_count, new_count * ROAD_COST], HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 12, Color.WHITE)

func _draw_toolbar(size: Vector2) -> void:
    draw_rect(Rect2(0.0, size.y - BOTTOM_H, size.x, BOTTOM_H), Color("#F5F8F3"))
    draw_line(Vector2(0.0, size.y - BOTTOM_H), Vector2(size.x, size.y - BOTTOM_H), Color("#BBCDC0"), 1.0)
    var font: Font = ThemeDB.fallback_font
    var labels: Dictionary = {Tool.ROAD: "MAIN ROAD", Tool.WIDEN: "WIDEN", Tool.BULLDOZE: "REMOVE", 99: "PAUSE" if not paused else "RESUME"}
    var subs: Dictionary = {Tool.ROAD: "Y12 / CELL", Tool.WIDEN: "Y90 / ROAD", Tool.BULLDOZE: "Y8 / CELL", 99: "CITY CLOCK"}
    for id: Variant in tool_rects.keys():
        var rect: Rect2 = tool_rects[id] as Rect2
        var active: bool = int(id) == current_tool and int(id) != 99
        var bg: Color = Color("#1E3B30") if active else Color.WHITE
        var fg: Color = Color.WHITE if active else Color("#20352D")
        var sub_fg: Color = Color("#BBD8C9") if active else Color("#6F8278")
        draw_rect(rect, bg)
        draw_rect(rect, Color("#20352D"), false, 2.0)
        if active:
            draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color("#7CC6A1"))
        draw_string(font, rect.position + Vector2(0.0, 27.0), str(labels[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, fg)
        draw_string(font, rect.position + Vector2(0.0, 47.0), str(subs[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 10, sub_fg)

func _draw_banner(size: Vector2) -> void:
    var font: Font = ThemeDB.fallback_font
    var w: float = minf(size.x - MARGIN * 2.0, 350.0)
    var rect: Rect2 = Rect2((size.x - w) * 0.5, board_origin.y + 10.0, w, 43.0)
    draw_rect(rect, Color(0.07, 0.14, 0.11, 0.92))
    draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), Color("#7CC6A1"))
    draw_string(font, rect.position + Vector2(0.0, 28.0), banner, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color.WHITE)

func _commit_arterial() -> void:
    var new_cells: Array = []
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if int(grid[p.y][p.x]) == Cell.EMPTY:
            new_cells.append(p)
    var cash_before: int = cash
    super._commit_arterial()
    if cash >= cash_before or new_cells.is_empty():
        return
    for item: Variant in new_cells:
        _v04_add_fx(item as Vector2i, "road", "")
    if not v04_first_growth_seeded and population == 0:
        _v04_seed_first_growth()

func _simulation_tick() -> void:
    var cash_before: int = cash
    var level_before: int = city_level
    super._simulation_tick()
    if cash > cash_before and tax_income > 0:
        v04_cash_flash = 0.42
    if city_level > level_before:
        v04_cash_flash = 0.60
        v04_level_flash = 0.80

func _auto_generate_local_roads() -> void:
    var before: Dictionary = {}
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) == Cell.LOCAL:
                before["%d:%d" % [x, y]] = true
    super._auto_generate_local_roads()
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) == Cell.LOCAL and not before.has("%d:%d" % [x, y]):
                _v04_add_fx(Vector2i(x, y), "local", "")
                return

func _auto_grow_buildings() -> void:
    var before_count: int = _count_cells(Cell.RESIDENTIAL) + _count_cells(Cell.COMMERCIAL) + _count_cells(Cell.INDUSTRIAL)
    super._auto_grow_buildings()
    var after_count: int = _count_cells(Cell.RESIDENTIAL) + _count_cells(Cell.COMMERCIAL) + _count_cells(Cell.INDUSTRIAL)
    if after_count <= before_count:
        return
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            var cell: int = int(grid[y][x])
            if cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL] and _v04_has_no_building_fx(p):
                var label: String = "+13 POP" if cell == Cell.RESIDENTIAL else "+JOBS"
                _v04_add_fx(p, "building", label)
                return

func _v04_seed_first_growth() -> void:
    var candidates: Array = []
    for item: Variant in _all_road_cells():
        var p: Vector2i = item as Vector2i
        for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var q: Vector2i = p + d
            if _in_bounds(q) and q.x < unlocked_cols and int(grid[q.y][q.x]) == Cell.EMPTY and not candidates.has(q):
                candidates.append(q)
    if candidates.is_empty():
        return
    var q: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)] as Vector2i
    grid[q.y][q.x] = Cell.RESIDENTIAL
    v04_first_growth_seeded = true
    _v04_add_fx(q, "building", "+13 POP")
    _recalculate_city()
    _toast("ROAD SET - HOMES MOVING IN")

func _draw_v04_effects() -> void:
    var font: Font = ThemeDB.fallback_font
    for item: Variant in v04_cell_fx:
        var fx: Dictionary = item as Dictionary
        var p: Vector2i = fx["p"] as Vector2i
        var life: float = float(fx["life"])
        var max_life: float = float(fx["max_life"])
        var ratio: float = clampf(life / maxf(max_life, 0.001), 0.0, 1.0)
        var rect: Rect2 = _cell_rect(p)
        var kind: String = str(fx["kind"])
        var color: Color = Color(0.42, 0.95, 0.67, ratio * 0.72)
        if kind == "road":
            color = Color(0.40, 0.89, 0.82, ratio * 0.70)
        elif kind == "local":
            color = Color(0.65, 0.86, 0.78, ratio * 0.54)
        draw_rect(rect.grow(-cell_size * (0.02 + (1.0 - ratio) * 0.16)), color, false, maxf(1.5, cell_size * 0.065))
        var label: String = str(fx["label"])
        if not label.is_empty():
            var rise: float = (1.0 - ratio) * 16.0
            draw_string(font, rect.position + Vector2(-cell_size * 0.55, -5.0 - rise), label, HORIZONTAL_ALIGNMENT_CENTER, cell_size * 2.1, 10, Color(0.10, 0.24, 0.17, minf(1.0, ratio * 1.8)))

func _v04_add_fx(p: Vector2i, kind: String, label: String) -> void:
    var duration: float = 0.95 if kind == "building" else 0.72
    v04_cell_fx.append({"p": p, "kind": kind, "label": label, "life": duration, "max_life": duration})

func _v04_has_no_building_fx(p: Vector2i) -> bool:
    for item: Variant in v04_cell_fx:
        var fx: Dictionary = item as Dictionary
        if str(fx["kind"]) == "building" and (fx["p"] as Vector2i) == p:
            return false
    return true

func _v04_growth_scale(p: Vector2i) -> float:
    for item: Variant in v04_cell_fx:
        var fx: Dictionary = item as Dictionary
        if str(fx["kind"]) != "building" or (fx["p"] as Vector2i) != p:
            continue
        var progress: float = 1.0 - clampf(float(fx["life"]) / maxf(float(fx["max_life"]), 0.001), 0.0, 1.0)
        return 0.55 + 0.45 * (1.0 - pow(1.0 - progress, 3.0))
    return 1.0

func _v04_is_road(p: Vector2i) -> bool:
    return _in_bounds(p) and p.x < unlocked_cols and int(grid[p.y][p.x]) in [Cell.ARTERIAL, Cell.LOCAL]

func _v04_unlock_progress() -> float:
    if city_level >= 4:
        return 1.0
    var base: int = 0
    var target: int = 90
    if population >= 90:
        base = 90
        target = 200
    if population >= 200:
        base = 200
        target = 360
    return clampf(float(population - base) / float(maxi(1, target - base)), 0.0, 1.0)

func _v04_next_unlock_target() -> int:
    if population < 90:
        return 90
    if population < 200:
        return 200
    return 360
