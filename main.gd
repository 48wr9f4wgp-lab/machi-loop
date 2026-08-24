extends Node2D

# MACHI LOOP — Vertical Slice 0.2
# Core loop: draw arterial -> local roads/buildings auto-grow -> congestion -> widen roads -> expand.

enum Cell { EMPTY, ARTERIAL, LOCAL, RESIDENTIAL, COMMERCIAL, INDUSTRIAL }
enum Tool { ROAD, WIDEN, BULLDOZE }

const GRID_W := 24
const GRID_H := 14
const TOP_H := 76.0
const BOTTOM_H := 92.0
const MARGIN := 22.0
const START_UNLOCKED_COLS := 9

var grid: Array = []
var widened := {}
var current_tool := Tool.ROAD
var dragging := false
var drag_path: Array = []
var paused := false

var cash := 700
var population := 0
var jobs := 0
var tax_income := 0
var happiness := 100
var congestion := 0.0
var unlocked_cols := START_UNLOCKED_COLS
var city_level := 1
var tick_count := 0

var cell_size := 42.0
var board_origin := Vector2.ZERO
var board_rect := Rect2()
var tool_rects := {}
var banner := "幹線道路を引いて、街を育てよう"
var banner_timer := 4.0

var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 8242026
    _init_grid()
    _reflow()
    get_viewport().size_changed.connect(_reflow)

    var timer := Timer.new()
    timer.wait_time = 0.85
    timer.autostart = true
    timer.timeout.connect(_simulation_tick)
    add_child(timer)

    queue_redraw()

func _init_grid() -> void:
    grid.clear()
    for y in GRID_H:
        var row := []
        for x in GRID_W:
            row.append(Cell.EMPTY)
        grid.append(row)

func _reflow() -> void:
    var size := get_viewport_rect().size
    var usable_w: float = maxf(320.0, size.x - MARGIN * 2.0)
    var usable_h: float = maxf(220.0, size.y - TOP_H - BOTTOM_H - MARGIN)
    cell_size = floorf(minf(usable_w / GRID_W, usable_h / GRID_H))
    cell_size = maxf(cell_size, 20.0)
    var board_size := Vector2(cell_size * GRID_W, cell_size * GRID_H)
    board_origin = Vector2((size.x - board_size.x) * 0.5, TOP_H + 8.0)
    board_rect = Rect2(board_origin, board_size)
    _layout_tools(size)
    queue_redraw()

func _layout_tools(size: Vector2) -> void:
    tool_rects.clear()
    var gap := 10.0
    var button_w: float = minf(190.0, (size.x - MARGIN * 2.0 - gap * 3.0) / 4.0)
    var button_h := 54.0
    var total_w: float = button_w * 4.0 + gap * 3.0
    var x0: float = (size.x - total_w) * 0.5
    var y := size.y - BOTTOM_H + 18.0
    tool_rects[Tool.ROAD] = Rect2(x0, y, button_w, button_h)
    tool_rects[Tool.WIDEN] = Rect2(x0 + (button_w + gap), y, button_w, button_h)
    tool_rects[Tool.BULLDOZE] = Rect2(x0 + (button_w + gap) * 2.0, y, button_w, button_h)
    tool_rects[99] = Rect2(x0 + (button_w + gap) * 3.0, y, button_w, button_h)

func _process(delta: float) -> void:
    if banner_timer > 0.0:
        banner_timer -= delta
        queue_redraw()

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#EAF1E7"))
    _draw_header(size)
    _draw_board()
    _draw_drag_preview()
    _draw_toolbar()
    if banner_timer > 0.0:
        _draw_banner(size)

func _draw_header(size: Vector2) -> void:
    draw_rect(Rect2(0, 0, size.x, TOP_H), Color("#17251F"))
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(22, 31), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
    var stats := "人口 %d   資金 ¥%d   税収 +¥%d   幸福 %d%%   渋滞 %d%%   Lv.%d" % [population, cash, tax_income, happiness, int(congestion), city_level]
    draw_string(font, Vector2(22, 59), stats, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#D7E8DE"))

func _draw_board() -> void:
    draw_rect(board_rect.grow(4.0), Color("#C8D6C4"), true)
    for y in GRID_H:
        for x in GRID_W:
            var rect := _cell_rect(Vector2i(x, y))
            var locked := x >= unlocked_cols
            if locked:
                draw_rect(rect, Color("#DCE1D8"))
            else:
                draw_rect(rect, _cell_color(Vector2i(x, y)))
            draw_rect(rect, Color(0.12, 0.18, 0.14, 0.10), false, 1.0)

            if locked:
                if (x + y) % 2 == 0:
                    draw_line(rect.position + Vector2(4, rect.size.y - 4), rect.position + Vector2(rect.size.x - 4, 4), Color(0.3,0.35,0.31,0.10), 1.0)
            else:
                _draw_cell_detail(Vector2i(x, y), rect)

    if unlocked_cols < GRID_W:
        var bx := board_origin.x + unlocked_cols * cell_size
        draw_line(Vector2(bx, board_origin.y), Vector2(bx, board_origin.y + GRID_H * cell_size), Color("#D39A41"), 3.0)

func _cell_color(p: Vector2i) -> Color:
    match grid[p.y][p.x]:
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
    var cell: int = grid[p.y][p.x]
    if cell == Cell.ARTERIAL or cell == Cell.LOCAL:
        var center := rect.get_center()
        var road_w := rect.size.x * (0.34 if cell == Cell.LOCAL else 0.52)
        var road_rect := Rect2(center - Vector2(road_w, road_w) * 0.5, Vector2(road_w, road_w))
        var load := _road_load(p)
        var heat: float = clampf(load / _road_capacity(p), 0.0, 1.5)
        if heat > 0.85:
            draw_circle(center, road_w * 0.48, Color(0.95, 0.36, 0.22, minf(0.65, heat * 0.45)))
        draw_rect(road_rect, Color("#333A38" if cell == Cell.ARTERIAL else "#626B68"))
        if cell == Cell.ARTERIAL:
            draw_line(Vector2(center.x - road_w * 0.36, center.y), Vector2(center.x + road_w * 0.36, center.y), Color("#F1D078"), maxf(1.0, cell_size * 0.045))
        if widened.has(_key(p)):
            draw_rect(rect.grow(-cell_size * 0.12), Color("#8DE0CE"), false, maxf(2.0, cell_size * 0.06))
        return

    if cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
        var inset := rect.grow(-cell_size * 0.18)
        var building_color := Color("#F2F0E9")
        if cell == Cell.COMMERCIAL:
            building_color = Color("#E7F5FB")
        elif cell == Cell.INDUSTRIAL:
            building_color = Color("#E7D5B7")
        draw_rect(inset, building_color)
        draw_rect(inset, Color(0.15,0.20,0.18,0.22), false, 1.0)
        var roof_h: float = maxf(2.0, cell_size * 0.10)
        draw_rect(Rect2(inset.position, Vector2(inset.size.x, roof_h)), Color(0.2,0.28,0.24,0.30))

func _draw_drag_preview() -> void:
    if not dragging or current_tool != Tool.ROAD:
        return
    for p in drag_path:
        if _in_bounds(p) and p.x < unlocked_cols:
            var rect := _cell_rect(p).grow(-cell_size * 0.10)
            var valid: bool = grid[p.y][p.x] in [Cell.EMPTY, Cell.ARTERIAL]
            draw_rect(rect, Color(0.20, 0.78, 0.66, 0.48) if valid else Color(0.92, 0.28, 0.20, 0.45))

func _draw_toolbar() -> void:
    var font := ThemeDB.fallback_font
    var labels := {
        Tool.ROAD: "幹線",
        Tool.WIDEN: "拡幅 ¥90",
        Tool.BULLDOZE: "撤去",
        99: "停止" if not paused else "再開"
    }
    for id in tool_rects.keys():
        var rect: Rect2 = tool_rects[id]
        var active: bool = id == current_tool and id != 99
        var bg := Color("#20352D") if active else Color("#F8FAF5")
        var fg := Color.WHITE if active else Color("#20352D")
        draw_rect(rect, bg)
        draw_rect(rect, Color("#20352D"), false, 2.0)
        draw_string(font, rect.position + Vector2(0, 35), labels[id], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, fg)

func _draw_banner(size: Vector2) -> void:
    var font := ThemeDB.fallback_font
    var w: float = minf(size.x - 40.0, 560.0)
    var rect := Rect2((size.x - w) * 0.5, TOP_H + 16.0, w, 46.0)
    draw_rect(rect, Color(0.08, 0.13, 0.11, 0.88))
    draw_string(font, rect.position + Vector2(0, 30), banner, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 17, Color.WHITE)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _pointer_down(event.position)
        else:
            _pointer_up(event.position)
    elif event is InputEventScreenDrag:
        _pointer_move(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _pointer_down(event.position)
        else:
            _pointer_up(event.position)
    elif event is InputEventMouseMotion and dragging:
        _pointer_move(event.position)

func _pointer_down(pos: Vector2) -> void:
    for id in tool_rects.keys():
        if tool_rects[id].has_point(pos):
            if id == 99:
                paused = not paused
                _toast("シミュレーション停止" if paused else "シミュレーション再開")
            else:
                current_tool = id
            queue_redraw()
            return

    var cell := _screen_to_cell(pos)
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
    var cell := _screen_to_cell(pos)
    if not _in_bounds(cell) or cell.x >= unlocked_cols:
        return
    var last: Vector2i = drag_path[-1]
    if cell == last:
        return
    for p in _grid_line(last, cell):
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
    var new_cells := []
    for p in drag_path:
        if grid[p.y][p.x] == Cell.EMPTY:
            new_cells.append(p)
    var cost := new_cells.size() * 12
    if new_cells.is_empty():
        return
    if cash < cost:
        _toast("資金不足：幹線道路は1マス ¥12")
        return
    cash -= cost
    for p in new_cells:
        grid[p.y][p.x] = Cell.ARTERIAL
    _toast("幹線道路を整備  -¥%d" % cost)
    _recalculate_city()

func _widen(p: Vector2i) -> void:
    if grid[p.y][p.x] != Cell.ARTERIAL:
        _toast("拡幅できるのは幹線道路だけ")
        return
    var k := _key(p)
    if widened.has(k):
        _toast("ここはすでに拡幅済み")
        return
    if cash < 90:
        _toast("拡幅には ¥90 必要")
        return
    cash -= 90
    widened[k] = true
    _toast("道路容量アップ")
    _recalculate_city()

func _bulldoze(p: Vector2i) -> void:
    var c: int = grid[p.y][p.x]
    if c == Cell.EMPTY:
        return
    if c == Cell.ARTERIAL:
        widened.erase(_key(p))
    grid[p.y][p.x] = Cell.EMPTY
    cash = maxi(0, cash - 8)
    _toast("撤去 -¥8")
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
    var roads := _all_road_cells()
    if roads.is_empty():
        return

    var candidates := []
    for p in roads:
        for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
            var q: Vector2i = p + d
            if not _in_bounds(q) or q.x >= unlocked_cols:
                continue
            if grid[q.y][q.x] != Cell.EMPTY:
                continue
            if _adjacent_road_count(q) >= 2:
                continue
            if _distance_to_arterial(q) > 3:
                continue
            if rng.randf() < 0.11:
                candidates.append(q)

    if not candidates.is_empty():
        var q: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
        grid[q.y][q.x] = Cell.LOCAL

func _auto_grow_buildings() -> void:
    if _all_road_cells().is_empty():
        return
    var growth_chance: float = 0.54 * clampf(1.20 - congestion / 120.0, 0.18, 1.0)
    if rng.randf() > growth_chance:
        return

    var candidates := []
    for y in GRID_H:
        for x in unlocked_cols:
            var p := Vector2i(x, y)
            if grid[y][x] == Cell.EMPTY and _adjacent_road_count(p) > 0:
                candidates.append(p)
    if candidates.is_empty():
        return

    var p: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
    grid[p.y][p.x] = _choose_building_type()

func _choose_building_type() -> int:
    var homes := _count_cells(Cell.RESIDENTIAL)
    var commerce := _count_cells(Cell.COMMERCIAL)
    var industry := _count_cells(Cell.INDUSTRIAL)
    if homes < 2:
        return Cell.RESIDENTIAL
    var estimated_jobs := commerce * 8 + industry * 11
    var estimated_pop := homes * 13
    if estimated_jobs < estimated_pop * 0.55:
        return Cell.COMMERCIAL if commerce <= industry else Cell.INDUSTRIAL
    var r := rng.randf()
    if r < 0.56:
        return Cell.RESIDENTIAL
    if r < 0.80:
        return Cell.COMMERCIAL
    return Cell.INDUSTRIAL

func _recalculate_city() -> void:
    var homes := _count_cells(Cell.RESIDENTIAL)
    var commerce := _count_cells(Cell.COMMERCIAL)
    var industry := _count_cells(Cell.INDUSTRIAL)
    population = homes * 13
    jobs = commerce * 8 + industry * 11

    var total_capacity := 0.0
    for p in _all_road_cells():
        total_capacity += _road_capacity(p)
    var trips := population * 0.72 + jobs * 0.32
    congestion = clampf((trips / maxf(1.0, total_capacity)) * 100.0, 0.0, 160.0)

    var job_ratio: float = minf(1.0, float(jobs + 10) / float(maxi(population, 1)))
    happiness = int(clampf(100.0 - maxf(0.0, congestion - 45.0) * 0.62 - absf(0.72 - job_ratio) * 22.0, 35.0, 100.0))
    tax_income = int(population * 0.08 + jobs * 0.05)

func _check_unlocks() -> void:
    var target_cols := START_UNLOCKED_COLS
    var target_level := 1
    if population >= 90:
        target_cols = 13
        target_level = 2
    if population >= 200:
        target_cols = 18
        target_level = 3
    if population >= 360:
        target_cols = GRID_W
        target_level = 4
    if target_cols > unlocked_cols:
        unlocked_cols = target_cols
        city_level = target_level
        cash += 180 * target_level
        _toast("都市Lv.%d！ 新エリア解放 +¥%d" % [city_level, 180 * target_level])

func _road_load(p: Vector2i) -> float:
    var load := 0.0
    for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
        var q: Vector2i = p + d
        if not _in_bounds(q):
            continue
        match grid[q.y][q.x]:
            Cell.RESIDENTIAL:
                load += 8.0
            Cell.COMMERCIAL:
                load += 6.0
            Cell.INDUSTRIAL:
                load += 9.0
    if grid[p.y][p.x] == Cell.ARTERIAL:
        load += congestion * 0.08
    return load

func _road_capacity(p: Vector2i) -> float:
    if grid[p.y][p.x] == Cell.ARTERIAL:
        return 30.0 if widened.has(_key(p)) else 18.0
    return 8.0

func _all_road_cells() -> Array:
    var result := []
    for y in GRID_H:
        for x in unlocked_cols:
            if grid[y][x] in [Cell.ARTERIAL, Cell.LOCAL]:
                result.append(Vector2i(x, y))
    return result

func _count_cells(kind: int) -> int:
    var n := 0
    for y in GRID_H:
        for x in unlocked_cols:
            if grid[y][x] == kind:
                n += 1
    return n

func _adjacent_road_count(p: Vector2i) -> int:
    var n := 0
    for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
        var q: Vector2i = p + d
        if _in_bounds(q) and grid[q.y][q.x] in [Cell.ARTERIAL, Cell.LOCAL]:
            n += 1
    return n

func _distance_to_arterial(p: Vector2i) -> int:
    var best := 999
    for y in GRID_H:
        for x in unlocked_cols:
            if grid[y][x] == Cell.ARTERIAL:
                best = mini(best, absi(p.x - x) + absi(p.y - y))
    return best

func _screen_to_cell(pos: Vector2) -> Vector2i:
    if not board_rect.has_point(pos):
        return Vector2i(-1, -1)
    var local := pos - board_origin
    return Vector2i(int(local.x / cell_size), int(local.y / cell_size))

func _cell_rect(p: Vector2i) -> Rect2:
    return Rect2(board_origin + Vector2(p.x, p.y) * cell_size, Vector2(cell_size, cell_size))

func _in_bounds(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < GRID_W and p.y < GRID_H

func _key(p: Vector2i) -> String:
    return "%d:%d" % [p.x, p.y]

func _grid_line(a: Vector2i, b: Vector2i) -> Array:
    var points := []
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
