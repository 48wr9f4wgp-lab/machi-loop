extends Node2D

# MACHI LOOP — portrait-first mobile vertical slice 0.3
# Core loop: draw arterial -> local roads/buildings auto-grow -> congestion -> widen roads -> expand.

enum Cell { EMPTY, ARTERIAL, LOCAL, RESIDENTIAL, COMMERCIAL, INDUSTRIAL }
enum Tool { ROAD, WIDEN, BULLDOZE }

const GRID_W: int = 16
const GRID_H: int = 22
const TOP_H: float = 126.0
const BOTTOM_H: float = 158.0
const MARGIN: float = 12.0
const START_UNLOCKED_COLS: int = 8
const ROAD_COST: int = 12
const WIDEN_COST: int = 90
const REMOVE_COST: int = 8

var grid: Array = []
var widened: Dictionary = {}
var current_tool: int = Tool.ROAD
var dragging: bool = false
var drag_path: Array = []
var paused: bool = false

var cash: int = 700
var population: int = 0
var jobs: int = 0
var tax_income: int = 0
var happiness: int = 100
var congestion: float = 0.0
var unlocked_cols: int = START_UNLOCKED_COLS
var city_level: int = 1
var tick_count: int = 0

var cell_size: float = 24.0
var board_origin: Vector2 = Vector2.ZERO
var board_rect: Rect2 = Rect2()
var tool_rects: Dictionary = {}
var banner: String = "DRAW A MAIN ROAD"
var banner_timer: float = 4.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 8242026
    _init_grid()
    _reflow()
    get_viewport().size_changed.connect(_reflow)

    var timer: Timer = Timer.new()
    timer.wait_time = 0.85
    timer.autostart = true
    timer.timeout.connect(_simulation_tick)
    add_child(timer)
    queue_redraw()

func _init_grid() -> void:
    grid.clear()
    for y: int in range(GRID_H):
        var row: Array = []
        for x: int in range(GRID_W):
            row.append(Cell.EMPTY)
        grid.append(row)

func _reflow() -> void:
    var size: Vector2 = get_viewport_rect().size
    var usable_w: float = maxf(220.0, size.x - MARGIN * 2.0)
    var usable_h: float = maxf(320.0, size.y - TOP_H - BOTTOM_H - MARGIN * 2.0)
    cell_size = floorf(minf(usable_w / float(GRID_W), usable_h / float(GRID_H)))
    cell_size = maxf(cell_size, 12.0)
    var board_size: Vector2 = Vector2(cell_size * GRID_W, cell_size * GRID_H)
    var board_space_top: float = TOP_H + MARGIN
    var board_space_h: float = size.y - TOP_H - BOTTOM_H - MARGIN * 2.0
    board_origin = Vector2((size.x - board_size.x) * 0.5, board_space_top + maxf(0.0, (board_space_h - board_size.y) * 0.5))
    board_rect = Rect2(board_origin, board_size)
    _layout_tools(size)
    queue_redraw()

func _layout_tools(size: Vector2) -> void:
    tool_rects.clear()
    var gap: float = 10.0
    var button_w: float = (size.x - MARGIN * 2.0 - gap) * 0.5
    var button_h: float = 56.0
    var x0: float = MARGIN
    var y0: float = size.y - BOTTOM_H + 14.0
    tool_rects[Tool.ROAD] = Rect2(x0, y0, button_w, button_h)
    tool_rects[Tool.WIDEN] = Rect2(x0 + button_w + gap, y0, button_w, button_h)
    tool_rects[Tool.BULLDOZE] = Rect2(x0, y0 + button_h + gap, button_w, button_h)
    tool_rects[99] = Rect2(x0 + button_w + gap, y0 + button_h + gap, button_w, button_h)

func _process(delta: float) -> void:
    if banner_timer > 0.0:
        banner_timer -= delta
        queue_redraw()

func _draw() -> void:
    var size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#EAF1E7"))
    _draw_header(size)
    _draw_board()
    _draw_drag_preview()
    _draw_toolbar(size)
    if banner_timer > 0.0:
        _draw_banner(size)

func _draw_header(size: Vector2) -> void:
    draw_rect(Rect2(0.0, 0.0, size.x, TOP_H), Color("#17251F"))
    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(MARGIN + 4.0, 34.0), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 27, Color.WHITE)
    draw_string(font, Vector2(MARGIN + 4.0, 60.0), "BUILD THE FLOW. LET THE CITY GROW.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#A9C7B9"))

    var line1: String = "POP %d   CASH Y%d   LV %d" % [population, cash, city_level]
    var line2: String = "IN +Y%d   HAPPY %d%%   TRAFFIC %d%%" % [tax_income, happiness, int(congestion)]
    draw_string(font, Vector2(MARGIN + 4.0, 88.0), line1, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#F5FBF7"))
    draw_string(font, Vector2(MARGIN + 4.0, 113.0), line2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#D7E8DE"))

func _draw_board() -> void:
    draw_rect(board_rect.grow(4.0), Color("#B7C8B2"), true)
    for y: int in range(GRID_H):
        for x: int in range(GRID_W):
            var p: Vector2i = Vector2i(x, y)
            var rect: Rect2 = _cell_rect(p)
            var locked: bool = x >= unlocked_cols
            if locked:
                draw_rect(rect, Color("#DDE2D9"))
            else:
                draw_rect(rect, _cell_color(p))
            draw_rect(rect, Color(0.12, 0.18, 0.14, 0.12), false, 1.0)

            if locked:
                if (x + y) % 2 == 0:
                    draw_line(rect.position + Vector2(3.0, rect.size.y - 3.0), rect.position + Vector2(rect.size.x - 3.0, 3.0), Color(0.3, 0.35, 0.31, 0.10), 1.0)
            else:
                _draw_cell_detail(p, rect)

    if unlocked_cols < GRID_W:
        var bx: float = board_origin.x + unlocked_cols * cell_size
        draw_line(Vector2(bx, board_origin.y), Vector2(bx, board_origin.y + GRID_H * cell_size), Color("#D39A41"), 3.0)

func _cell_color(p: Vector2i) -> Color:
    var cell: int = int(grid[p.y][p.x])
    match cell:
        Cell.ARTERIAL:
            return Color("#4C5654")
        Cell.LOCAL:
            return Color("#7F8985")
        Cell.RESIDENTIAL:
            return Color("#A8D7A5")
        Cell.COMMERCIAL:
            return Color("#84BDD6")
        Cell.INDUSTRIAL:
            return Color("#D5B477")
        _:
            return Color("#CFE1C6")

func _draw_cell_detail(p: Vector2i, rect: Rect2) -> void:
    var cell: int = int(grid[p.y][p.x])
    if cell == Cell.ARTERIAL or cell == Cell.LOCAL:
        var center: Vector2 = rect.get_center()
        var road_w: float = rect.size.x * (0.40 if cell == Cell.LOCAL else 0.62)
        var road_rect: Rect2 = Rect2(center - Vector2(road_w, road_w) * 0.5, Vector2(road_w, road_w))
        var load: float = _road_load(p)
        var heat: float = clampf(load / _road_capacity(p), 0.0, 1.5)
        if heat > 0.85:
            draw_circle(center, road_w * 0.54, Color(0.95, 0.36, 0.22, minf(0.62, heat * 0.42)))
        draw_rect(road_rect, Color("#303735" if cell == Cell.ARTERIAL else "#626B68"))
        if cell == Cell.ARTERIAL:
            draw_line(Vector2(center.x - road_w * 0.34, center.y), Vector2(center.x + road_w * 0.34, center.y), Color("#F1D078"), maxf(1.0, cell_size * 0.055))
        if widened.has(_key(p)):
            draw_rect(rect.grow(-cell_size * 0.10), Color("#8DE0CE"), false, maxf(2.0, cell_size * 0.07))
        return

    if cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
        var inset: Rect2 = rect.grow(-cell_size * 0.14)
        var building_color: Color = Color("#F3F1EA")
        if cell == Cell.COMMERCIAL:
            building_color = Color("#E7F5FB")
        elif cell == Cell.INDUSTRIAL:
            building_color = Color("#E8D5B4")
        draw_rect(inset, building_color)
        draw_rect(inset, Color(0.15, 0.20, 0.18, 0.24), false, 1.0)
        var roof_h: float = maxf(2.0, cell_size * 0.12)
        draw_rect(Rect2(inset.position, Vector2(inset.size.x, roof_h)), Color(0.2, 0.28, 0.24, 0.32))

func _draw_drag_preview() -> void:
    if not dragging or current_tool != Tool.ROAD:
        return
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if _in_bounds(p) and p.x < unlocked_cols:
            var rect: Rect2 = _cell_rect(p).grow(-cell_size * 0.08)
            var valid: bool = int(grid[p.y][p.x]) in [Cell.EMPTY, Cell.ARTERIAL]
            draw_rect(rect, Color(0.20, 0.78, 0.66, 0.52) if valid else Color(0.92, 0.28, 0.20, 0.45))

func _draw_toolbar(size: Vector2) -> void:
    draw_rect(Rect2(0.0, size.y - BOTTOM_H, size.x, BOTTOM_H), Color("#F4F7F2"))
    draw_line(Vector2(0.0, size.y - BOTTOM_H), Vector2(size.x, size.y - BOTTOM_H), Color("#C9D6CD"), 1.0)
    var font: Font = ThemeDB.fallback_font
    var labels: Dictionary = {
        Tool.ROAD: "MAIN ROAD",
        Tool.WIDEN: "WIDEN  Y90",
        Tool.BULLDOZE: "REMOVE",
        99: "PAUSE" if not paused else "RESUME"
    }
    for id: Variant in tool_rects.keys():
        var rect: Rect2 = tool_rects[id] as Rect2
        var active: bool = int(id) == current_tool and int(id) != 99
        var bg: Color = Color("#20352D") if active else Color.WHITE
        var fg: Color = Color.WHITE if active else Color("#20352D")
        draw_rect(rect, bg)
        draw_rect(rect, Color("#20352D"), false, 2.0)
        draw_string(font, rect.position + Vector2(0.0, 36.0), String(labels[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 17, fg)

func _draw_banner(size: Vector2) -> void:
    var font: Font = ThemeDB.fallback_font
    var w: float = minf(size.x - MARGIN * 2.0, 360.0)
    var rect: Rect2 = Rect2((size.x - w) * 0.5, board_origin.y + 10.0, w, 44.0)
    draw_rect(rect, Color(0.08, 0.13, 0.11, 0.90))
    draw_string(font, rect.position + Vector2(0.0, 29.0), banner, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15, Color.WHITE)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed:
            _pointer_down(touch.position)
        else:
            _pointer_up(touch.position)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        _pointer_move(drag.position)
    elif event is InputEventMouseButton:
        var mouse_button: InputEventMouseButton = event as InputEventMouseButton
        if mouse_button.button_index == MOUSE_BUTTON_LEFT:
            if mouse_button.pressed:
                _pointer_down(mouse_button.position)
            else:
                _pointer_up(mouse_button.position)
    elif event is InputEventMouseMotion and dragging:
        var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
        _pointer_move(mouse_motion.position)

func _pointer_down(pos: Vector2) -> void:
    for id: Variant in tool_rects.keys():
        var rect: Rect2 = tool_rects[id] as Rect2
        if rect.has_point(pos):
            if int(id) == 99:
                paused = not paused
                _toast("SIM PAUSED" if paused else "SIM RESUMED")
            else:
                current_tool = int(id)
            queue_redraw()
            return

    var cell: Vector2i = _screen_to_cell(pos)
    if not _in_bounds(cell) or cell.x >= unlocked_cols:
        return

    if current_tool == Tool.ROAD:
        dragging = true
        drag_path = [cell]
        queue_redraw()
    elif current_tool == Tool.WIDEN:
        _widen(cell)
    elif current_tool == Tool.BULLDOZE:
        _bulldoze(cell)

func _pointer_move(pos: Vector2) -> void:
    if not dragging or current_tool != Tool.ROAD:
        return
    var cell: Vector2i = _screen_to_cell(pos)
    if not _in_bounds(cell) or cell.x >= unlocked_cols:
        return
    var last: Vector2i = drag_path[-1] as Vector2i
    if cell == last:
        return
    var line: Array = _grid_line(last, cell)
    for item: Variant in line:
        var p: Vector2i = item as Vector2i
        if p != last and _in_bounds(p) and p.x < unlocked_cols and not drag_path.has(p):
            drag_path.append(p)
    queue_redraw()

func _pointer_up(_pos: Vector2) -> void:
    if dragging and current_tool == Tool.ROAD:
        _commit_arterial()
    dragging = false
    drag_path.clear()
    queue_redraw()

func _commit_arterial() -> void:
    var new_cells: Array = []
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if int(grid[p.y][p.x]) == Cell.EMPTY:
            new_cells.append(p)
    var cost: int = new_cells.size() * ROAD_COST
    if new_cells.is_empty():
        return
    if cash < cost:
        _toast("NOT ENOUGH CASH")
        return
    cash -= cost
    for item: Variant in new_cells:
        var p: Vector2i = item as Vector2i
        grid[p.y][p.x] = Cell.ARTERIAL
    _toast("MAIN ROAD  -Y%d" % cost)
    _recalculate_city()

func _widen(p: Vector2i) -> void:
    if int(grid[p.y][p.x]) != Cell.ARTERIAL:
        _toast("SELECT A MAIN ROAD")
        return
    var k: String = _key(p)
    if widened.has(k):
        _toast("ALREADY WIDENED")
        return
    if cash < WIDEN_COST:
        _toast("NEED Y90")
        return
    cash -= WIDEN_COST
    widened[k] = true
    _toast("ROAD CAPACITY UP")
    _recalculate_city()

func _bulldoze(p: Vector2i) -> void:
    var c: int = int(grid[p.y][p.x])
    if c == Cell.EMPTY:
        return
    if c == Cell.ARTERIAL:
        widened.erase(_key(p))
    grid[p.y][p.x] = Cell.EMPTY
    cash = maxi(0, cash - REMOVE_COST)
    _toast("REMOVED  -Y%d" % REMOVE_COST)
    _recalculate_city()

func _simulation_tick() -> void:
    if paused:
        return
    tick_count += 1
    _auto_generate_local_roads()
    _auto_grow_buildings()
    _recalculate_city()
    if tick_count % 5 == 0:
        cash += tax_income
    _check_unlocks()
    queue_redraw()

func _auto_generate_local_roads() -> void:
    var roads: Array = _all_road_cells()
    if roads.is_empty():
        return
    var candidates: Array = []
    for item: Variant in roads:
        var p: Vector2i = item as Vector2i
        for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var q: Vector2i = p + d
            if not _in_bounds(q) or q.x >= unlocked_cols:
                continue
            if int(grid[q.y][q.x]) != Cell.EMPTY:
                continue
            if _adjacent_road_count(q) >= 2:
                continue
            if _distance_to_arterial(q) > 3:
                continue
            if rng.randf() < 0.11:
                candidates.append(q)
    if not candidates.is_empty():
        var index: int = rng.randi_range(0, candidates.size() - 1)
        var q: Vector2i = candidates[index] as Vector2i
        grid[q.y][q.x] = Cell.LOCAL

func _auto_grow_buildings() -> void:
    if _all_road_cells().is_empty():
        return
    var growth_chance: float = 0.54 * clampf(1.20 - congestion / 120.0, 0.18, 1.0)
    if rng.randf() > growth_chance:
        return
    var candidates: Array = []
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            if int(grid[y][x]) == Cell.EMPTY and _adjacent_road_count(p) > 0:
                candidates.append(p)
    if candidates.is_empty():
        return
    var index: int = rng.randi_range(0, candidates.size() - 1)
    var p: Vector2i = candidates[index] as Vector2i
    grid[p.y][p.x] = _choose_building_type()

func _choose_building_type() -> int:
    var homes: int = _count_cells(Cell.RESIDENTIAL)
    var commerce: int = _count_cells(Cell.COMMERCIAL)
    var industry: int = _count_cells(Cell.INDUSTRIAL)
    if homes < 2:
        return Cell.RESIDENTIAL
    var estimated_jobs: int = commerce * 8 + industry * 11
    var estimated_pop: int = homes * 13
    if float(estimated_jobs) < float(estimated_pop) * 0.55:
        return Cell.COMMERCIAL if commerce <= industry else Cell.INDUSTRIAL
    var r: float = rng.randf()
    if r < 0.56:
        return Cell.RESIDENTIAL
    if r < 0.80:
        return Cell.COMMERCIAL
    return Cell.INDUSTRIAL

func _recalculate_city() -> void:
    var homes: int = _count_cells(Cell.RESIDENTIAL)
    var commerce: int = _count_cells(Cell.COMMERCIAL)
    var industry: int = _count_cells(Cell.INDUSTRIAL)
    population = homes * 13
    jobs = commerce * 8 + industry * 11

    var total_capacity: float = 0.0
    var roads: Array = _all_road_cells()
    for item: Variant in roads:
        total_capacity += _road_capacity(item as Vector2i)
    var trips: float = population * 0.72 + jobs * 0.32
    congestion = clampf((trips / maxf(1.0, total_capacity)) * 100.0, 0.0, 160.0)

    var job_ratio: float = minf(1.0, float(jobs + 10) / float(maxi(population, 1)))
    happiness = int(clampf(100.0 - maxf(0.0, congestion - 45.0) * 0.62 - absf(0.72 - job_ratio) * 22.0, 35.0, 100.0))
    tax_income = int(population * 0.08 + jobs * 0.05)

func _check_unlocks() -> void:
    var target_cols: int = START_UNLOCKED_COLS
    var target_level: int = 1
    if population >= 90:
        target_cols = 11
        target_level = 2
    if population >= 200:
        target_cols = 14
        target_level = 3
    if population >= 360:
        target_cols = GRID_W
        target_level = 4
    if target_cols > unlocked_cols:
        unlocked_cols = target_cols
        city_level = target_level
        var reward: int = 180 * target_level
        cash += reward
        _toast("CITY LV %d  +Y%d" % [city_level, reward])

func _road_load(p: Vector2i) -> float:
    var load: float = 0.0
    for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        var q: Vector2i = p + d
        if not _in_bounds(q):
            continue
        match int(grid[q.y][q.x]):
            Cell.RESIDENTIAL:
                load += 8.0
            Cell.COMMERCIAL:
                load += 6.0
            Cell.INDUSTRIAL:
                load += 9.0
    if int(grid[p.y][p.x]) == Cell.ARTERIAL:
        load += congestion * 0.08
    return load

func _road_capacity(p: Vector2i) -> float:
    if int(grid[p.y][p.x]) == Cell.ARTERIAL:
        return 30.0 if widened.has(_key(p)) else 18.0
    return 8.0

func _all_road_cells() -> Array:
    var result: Array = []
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) in [Cell.ARTERIAL, Cell.LOCAL]:
                result.append(Vector2i(x, y))
    return result

func _count_cells(kind: int) -> int:
    var n: int = 0
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) == kind:
                n += 1
    return n

func _adjacent_road_count(p: Vector2i) -> int:
    var n: int = 0
    for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        var q: Vector2i = p + d
        if _in_bounds(q) and int(grid[q.y][q.x]) in [Cell.ARTERIAL, Cell.LOCAL]:
            n += 1
    return n

func _distance_to_arterial(p: Vector2i) -> int:
    var best: int = 999
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            if int(grid[y][x]) == Cell.ARTERIAL:
                best = mini(best, absi(p.x - x) + absi(p.y - y))
    return best

func _screen_to_cell(pos: Vector2) -> Vector2i:
    if not board_rect.has_point(pos):
        return Vector2i(-1, -1)
    var local: Vector2 = pos - board_origin
    return Vector2i(int(local.x / cell_size), int(local.y / cell_size))

func _cell_rect(p: Vector2i) -> Rect2:
    return Rect2(board_origin + Vector2(p.x, p.y) * cell_size, Vector2(cell_size, cell_size))

func _in_bounds(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < GRID_W and p.y < GRID_H

func _key(p: Vector2i) -> String:
    return "%d:%d" % [p.x, p.y]

func _grid_line(a: Vector2i, b: Vector2i) -> Array:
    var points: Array = []
    var x0: int = a.x
    var y0: int = a.y
    var x1: int = b.x
    var y1: int = b.y
    var dx: int = absi(x1 - x0)
    var sx: int = 1 if x0 < x1 else -1
    var dy: int = -absi(y1 - y0)
    var sy: int = 1 if y0 < y1 else -1
    var err: int = dx + dy
    while true:
        points.append(Vector2i(x0, y0))
        if x0 == x1 and y0 == y1:
            break
        var e2: int = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy
    return points

func _toast(text: String) -> void:
    banner = text
    banner_timer = 2.4
    queue_redraw()
