extends "res://main_v22_road_guard.gd"

# MACHI LOOP v0.23 — Core Experience Rebuild / Vertical Slice v2.
# First production step after GDD v2.0 relock: city-as-UI presentation and
# first-road birth sequence. Existing simulation remains authoritative.

var v23_birth_started: bool = false
var v23_birth_announced: bool = false
var v23_birth_road_count: int = 0
var v23_birth_population: int = 0
var v23_alert_text: String = ""

func _ready() -> void:
    super._ready()
    v23_birth_road_count = _count_cells(Cell.ARTERIAL)
    v23_birth_population = population
    v23_birth_started = v23_birth_road_count > 0
    v23_birth_announced = population > 0
    queue_redraw()

func _commit_arterial() -> void:
    var before: int = _count_cells(Cell.ARTERIAL)
    super._commit_arterial()
    var after: int = _count_cells(Cell.ARTERIAL)
    if after > before and not v23_birth_started:
        v23_birth_started = true
        v23_birth_road_count = after
        v23_alert_text = "街が動きはじめました"
        queue_redraw()

func _simulation_tick() -> void:
    var before_population: int = population
    super._simulation_tick()
    if v23_birth_started and not v23_birth_announced and population > maxi(0, before_population):
        v23_birth_announced = true
        v23_birth_population = population
        v23_alert_text = "街が生まれました"
        if v22_feedback != null:
            v22_feedback.goal_complete()
    _v23_refresh_world_alert()
    queue_redraw()

func _draw() -> void:
    super._draw()
    _v23_draw_city_first_shell()

func _v22_draw_feedback_settings() -> void:
    # v2: SFX/haptics belong in settings, never persistent gameplay HUD.
    pass

func _v23_draw_city_first_shell() -> void:
    var size: Vector2 = get_viewport_rect().size
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var top: Rect2 = Rect2(0.0, 0.0, size.x, 112.0)
    draw_rect(top, Color("#F4F2E8"))
    draw_string(font, Vector2(18.0, 28.0), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, 170.0, 18, Color("#16352A"))
    draw_string(font, Vector2(18.0, 51.0), _v23_stage_name(), HORIZONTAL_ALIGNMENT_LEFT, 170.0, 10, Color("#668074"))
    draw_string(font, Vector2(size.x - 194.0, 31.0), "人口  %d" % population, HORIZONTAL_ALIGNMENT_RIGHT, 86.0, 11, Color("#244A3B"))
    draw_string(font, Vector2(size.x - 102.0, 31.0), "¥%d" % cash, HORIZONTAL_ALIGNMENT_RIGHT, 88.0, 11, Color("#244A3B"))

    var message: String = _v23_context_message()
    if not message.is_empty():
        var pill_w: float = minf(size.x - 32.0, 350.0)
        var pill: Rect2 = Rect2((size.x - pill_w) * 0.5, 64.0, pill_w, 34.0)
        draw_rect(pill, Color(0.07, 0.19, 0.14, 0.92))
        draw_string(font, pill.position + Vector2(12.0, 22.0), message, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 24.0, 10, Color("#F5FFF9"))

    var bottom_h: float = 108.0
    var bottom: Rect2 = Rect2(0.0, size.y - bottom_h, size.x, bottom_h)
    draw_rect(bottom, Color("#F4F2E8"))
    draw_line(Vector2(0.0, bottom.position.y), Vector2(size.x, bottom.position.y), Color("#D6DED8"), 1.0)
    _v23_draw_primary_tools(bottom, font)

func _v23_draw_primary_tools(bottom: Rect2, font: Font) -> void:
    var labels: Array[String] = ["幹線道路", "拡幅", "撤去"]
    var available: float = bottom.size.x - 32.0
    var gap: float = 8.0
    var w: float = (available - gap * 2.0) / 3.0
    var y: float = bottom.position.y + 18.0
    for i: int in range(3):
        var rect: Rect2 = Rect2(16.0 + float(i) * (w + gap), y, w, 54.0)
        var active: bool = mode == i
        draw_rect(rect, Color("#174B38") if active else Color("#E2E8E3"))
        draw_rect(rect, Color("#174B38"), false, 1.0)
        draw_string(font, rect.position + Vector2(6.0, 33.0), labels[i], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 11, Color("#FFFFFF") if active else Color("#244A3B"))

func _v23_context_message() -> String:
    if _count_cells(Cell.ARTERIAL) <= 0:
        return "最初の道を引こう"
    if not v23_birth_announced:
        return "道のそばに、街が生まれようとしています"
    if not v23_alert_text.is_empty():
        return v23_alert_text
    return "街を見て、次の一本を考えよう"

func _v23_stage_name() -> String:
    if population <= 0:
        return "まだ何もない土地"
    if population < 30:
        return "集落が生まれています"
    if population < 90:
        return "町が広がっています"
    return "都市が成長しています"

func _v23_refresh_world_alert() -> void:
    var worst_ratio: float = 0.0
    for y: int in range(GRID_H):
        for x: int in range(unlocked_cols):
            var p: Vector2i = Vector2i(x, y)
            if int(grid[y][x]) != Cell.ARTERIAL:
                continue
            worst_ratio = maxf(worst_ratio, _road_load(p) / maxf(0.1, _road_capacity(p)))
    if worst_ratio > 1.05:
        v23_alert_text = "この道に交通が集中しています"
    elif v23_birth_announced and population > v23_birth_population:
        v23_alert_text = "道に沿って街が広がっています"
