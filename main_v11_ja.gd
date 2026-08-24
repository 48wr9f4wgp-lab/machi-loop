extends "res://main_v10.gd"

# MACHI LOOP v0.11 — Japanese-first UI layer.
# Web builds generate a small Noto Sans CJK JP subset in CI so Japanese never depends on browser/system fallback.

var v11_font: Font

func _ready() -> void:
    _v11_init_font()
    super._ready()

func _v11_init_font() -> void:
    var font_path: String = "res://generated/MachiLoopJP.otf"
    if ResourceLoader.exists(font_path):
        v11_font = load(font_path) as Font
    if v11_font == null:
        var system_font: SystemFont = SystemFont.new()
        system_font.font_names = PackedStringArray(["Noto Sans CJK JP", "Hiragino Sans", "Yu Gothic", "sans-serif"])
        system_font.allow_system_fallback = true
        v11_font = system_font

func _draw_header(size: Vector2) -> void:
    draw_rect(Rect2(0.0, 0.0, size.x, TOP_H), Color("#10261D"))
    draw_rect(Rect2(0.0, TOP_H - 3.0, size.x, 3.0), Color("#71D0A2"))
    var latin: Font = ThemeDB.fallback_font

    draw_string(latin, Vector2(MARGIN + 4.0, 28.0), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color("#F7FFF9"))
    draw_string(v11_font, Vector2(MARGIN + 4.0, 47.0), "街の流れをつくり、都市を育てる。", HORIZONTAL_ALIGNMENT_LEFT, size.x - 110.0, 10, Color("#9BC9B4"))

    var level_rect: Rect2 = Rect2(size.x - 68.0, 12.0, 54.0, 25.0)
    draw_rect(level_rect, Color("#1A3A2E"))
    draw_rect(level_rect, Color("#4D7865"), false, 1.0)
    draw_string(v11_font, level_rect.position + Vector2(0.0, 18.0), "都市LV %d" % city_level, HORIZONTAL_ALIGNMENT_CENTER, level_rect.size.x, 9, Color("#DDF4E7"))

    var gap: float = 6.0
    var cards_x: float = MARGIN + 4.0
    var cards_w: float = size.x - (MARGIN + 4.0) * 2.0
    var card_w: float = (cards_w - gap * 2.0) / 3.0
    var card_h: float = 35.0
    var card_y: float = 56.0

    _v11_stat_card(Rect2(cards_x, card_y, card_w, card_h), "人口", str(population), Color("#DDF4E7"))
    var cash_color: Color = Color("#FFE58C") if v04_cash_flash > 0.0 else Color("#F7FFF9")
    _v11_stat_card(Rect2(cards_x + card_w + gap, card_y, card_w, card_h), "資金", "¥%d" % cash, cash_color)
    var traffic_color: Color = Color("#AEE7C9")
    if congestion >= 75.0:
        traffic_color = Color("#FFAF8C")
    elif congestion >= 50.0:
        traffic_color = Color("#FFD28C")
    _v11_stat_card(Rect2(cards_x + (card_w + gap) * 2.0, card_y, card_w, card_h), "渋滞", "%d%%" % int(congestion), traffic_color)

    draw_string(v11_font, Vector2(cards_x, 108.0), "収入 +¥%d   幸福 %d%%" % [tax_income, happiness], HORIZONTAL_ALIGNMENT_LEFT, 210.0, 10, Color("#BCE0CD"))
    var next_text: String = "最大都市" if city_level >= 4 else "次の地区 %d/%d" % [population, _v04_next_unlock_target()]
    draw_string(v11_font, Vector2(size.x - 142.0, 108.0), next_text, HORIZONTAL_ALIGNMENT_RIGHT, 126.0, 8, Color("#A6CCB9"))

    var bar: Rect2 = Rect2(cards_x, 115.0, cards_w, 6.0)
    draw_rect(bar, Color("#29463A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * _v04_unlock_progress(), bar.size.y)), Color("#71D0A2"))

func _v11_stat_card(rect: Rect2, label: String, value: String, value_color: Color) -> void:
    draw_rect(rect, Color("#173329"))
    draw_rect(rect, Color("#315646"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(8.0, 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 8, Color("#84B49E"))
    draw_string(v11_font, rect.position + Vector2(8.0, 29.0), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 14, value_color)

func _draw_toolbar(size: Vector2) -> void:
    draw_rect(Rect2(0.0, size.y - BOTTOM_H, size.x, BOTTOM_H), Color("#F5F8F3"))
    draw_line(Vector2(0.0, size.y - BOTTOM_H), Vector2(size.x, size.y - BOTTOM_H), Color("#BBCDC0"), 1.0)
    var labels: Dictionary = {
        Tool.ROAD: "幹線道路",
        Tool.WIDEN: "拡幅",
        Tool.BULLDOZE: "撤去",
        99: "一時停止" if not paused else "再開"
    }
    var subs: Dictionary = {
        Tool.ROAD: "1マス ¥12",
        Tool.WIDEN: "1道路 ¥90",
        Tool.BULLDOZE: "1マス ¥8",
        99: "街の時間"
    }
    for id: Variant in tool_rects.keys():
        var rect: Rect2 = tool_rects[id] as Rect2
        var active: bool = int(id) == current_tool and int(id) != 99
        var bg: Color = Color("#173D2F") if active else Color.WHITE
        var fg: Color = Color.WHITE if active else Color("#1A3329")
        var sub_fg: Color = Color("#BDE4D1") if active else Color("#73847B")
        draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.08, 0.16, 0.12, 0.12))
        draw_rect(rect, bg)
        draw_rect(rect, Color("#1A3329"), false, 2.0)
        if active:
            draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color("#78D7AA"))
        _draw_v05_tool_icon(int(id), rect, fg)
        draw_string(v11_font, rect.position + Vector2(30.0, 27.0), str(labels[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 38.0, 14, fg)
        draw_string(v11_font, rect.position + Vector2(30.0, 46.0), str(subs[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 38.0, 9, sub_fg)

func _draw_v06_first_action_coach() -> void:
    var pulse: float = 0.5 + 0.5 * sin(v04_time * 3.0)
    var w: float = minf(board_rect.size.x - 30.0, 326.0)
    var card: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + 18.0, w, 68.0)
    draw_rect(Rect2(card.position + Vector2(0.0, 4.0), card.size), Color(0.05, 0.11, 0.08, 0.16))
    draw_rect(card, Color(0.055, 0.14, 0.105, 0.95))
    draw_rect(card, Color(0.44, 0.84, 0.64, 0.55 + pulse * 0.30), false, 2.0)
    draw_rect(Rect2(card.position, Vector2(5.0, card.size.y)), Color("#71D0A2"))
    draw_string(v11_font, card.position + Vector2(14.0, 27.0), "最初の幹線道路を引こう", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 28.0, 13, Color("#F4FFF8"))
    draw_string(v11_font, card.position + Vector2(14.0, 48.0), "緑の土地をドラッグ", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 90.0, 10, Color("#BDE4D1"))
    var y: float = card.position.y + 48.0
    var x2: float = card.end.x - 17.0
    draw_line(Vector2(x2 - 42.0, y), Vector2(x2, y), Color("#71D0A2"), 3.0)
    draw_line(Vector2(x2, y), Vector2(x2 - 8.0, y - 5.0), Color("#71D0A2"), 3.0)
    draw_line(Vector2(x2, y), Vector2(x2 - 8.0, y + 5.0), Color("#71D0A2"), 3.0)

func _draw_v05_traffic_hint() -> void:
    var w: float = minf(board_rect.size.x - 24.0, 310.0)
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + 10.0, w, 46.0)
    draw_rect(rect, Color(0.34, 0.12, 0.07, 0.92))
    draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), Color("#FF916F"))
    draw_string(v11_font, rect.position + Vector2(10.0, 20.0), "渋滞が増えています", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 11, Color("#FFF4EF"))
    draw_string(v11_font, rect.position + Vector2(10.0, 37.0), "幹線道路を拡幅して流れを改善", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 9, Color("#FFD8CA"))

func _draw_banner(size: Vector2) -> void:
    var w: float = minf(size.x - MARGIN * 2.0, 360.0)
    var rect: Rect2 = Rect2((size.x - w) * 0.5, board_origin.y + 10.0, w, 44.0)
    draw_rect(rect, Color(0.08, 0.13, 0.11, 0.92))
    draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), Color("#71D0A2"))
    draw_string(v11_font, rect.position + Vector2(8.0, 29.0), _v11_banner_text(banner), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 13, Color.WHITE)

func _v11_banner_text(source: String) -> String:
    if source == "DRAW A MAIN ROAD":
        return "幹線道路を引こう"
    if source == "ROAD SET - HOMES MOVING IN":
        return "道路完成・住民が引っ越してきた"
    if source == "NOT ENOUGH CASH":
        return "資金不足"
    if source == "SIM PAUSED":
        return "シミュレーション一時停止"
    if source == "SIM RESUMED":
        return "シミュレーション再開"
    if source.begins_with("CITY GOAL COMPLETE"):
        return "目標を達成しました"
    if source.begins_with("NEED Y"):
        return "変更には資金が必要"
    if source.begins_with("POLICY:"):
        return "都市方針  " + _v09_policy_name(v09_policy)
    if source.contains("UNLOCK"):
        return "地区解放"
    return "街が更新されました"

func _v08_goal_title(stage: int) -> String:
    match stage:
        0:
            return "道路網をつくる"
        1:
            return "住民を増やす"
        2:
            return "雇用を増やす"
        3:
            return "交通を保つ"
        4:
            return "第2地区を解放"
        5:
            return "第3地区を解放"
        6:
            return "全地区を解放"
        _:
            return "都市の基礎完成"

func _v08_goal_progress_text(stage: int) -> String:
    match stage:
        0:
            return "%d / 6 道路マス" % _count_cells(Cell.ARTERIAL)
        1:
            return "人口 %d / 26" % population
        2:
            return "雇用 %d / 16" % jobs
        3:
            if population < 52:
                return "人口 %d / 52" % population
            return "渋滞 %d%%  目標55%%以下" % int(congestion)
        4:
            return "人口 %d / 90" % population
        5:
            return "人口 %d / 200" % population
        6:
            return "人口 %d / 360" % population
        _:
            return "都市の基礎完成"

func _v08_draw_goal_card() -> void:
    var w: float = minf(board_rect.size.x - 24.0, 330.0)
    var h: float = 58.0
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.end.y - h - 10.0, w, h)
    draw_rect(Rect2(rect.position + Vector2(0.0, 3.0), rect.size), Color(0.04, 0.09, 0.07, 0.15))
    draw_rect(rect, Color(0.055, 0.14, 0.105, 0.94))
    draw_rect(rect, Color("#42705B"), false, 1.0)

    if v08_goal_stage >= V08_GOAL_COUNT:
        draw_string(v11_font, rect.position + Vector2(12.0, 23.0), "街づくり目標", HORIZONTAL_ALIGNMENT_LEFT, 120.0, 9, Color("#86B89F"))
        draw_string(v11_font, rect.position + Vector2(12.0, 44.0), "都市の基礎完成", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 13, Color("#E9FFF2"))
        return

    var reward: int = int(V08_GOAL_REWARDS[v08_goal_stage])
    draw_string(v11_font, rect.position + Vector2(12.0, 15.0), "街づくり目標 %d/%d" % [v08_goal_stage + 1, V08_GOAL_COUNT], HORIZONTAL_ALIGNMENT_LEFT, 170.0, 8, Color("#86B89F"))
    draw_string(v11_font, rect.position + Vector2(rect.size.x - 82.0, 15.0), "+¥%d" % reward, HORIZONTAL_ALIGNMENT_RIGHT, 70.0, 9, Color("#FFE28C"))
    draw_string(v11_font, rect.position + Vector2(12.0, 34.0), _v08_goal_title(v08_goal_stage), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 13, Color("#F4FFF8"))
    draw_string(v11_font, rect.position + Vector2(12.0, 50.0), _v08_goal_progress_text(v08_goal_stage), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 9, Color("#B9DDCB"))

    var bar: Rect2 = Rect2(rect.position.x + 12.0, rect.end.y - 5.0, rect.size.x - 24.0, 3.0)
    draw_rect(bar, Color("#28483A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * _v08_goal_progress(v08_goal_stage), bar.size.y)), Color("#71D0A2"))

func _v08_draw_goal_complete() -> void:
    var alpha: float = clampf(v08_goal_flash / 0.35, 0.0, 1.0)
    var w: float = minf(board_rect.size.x - 28.0, 320.0)
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.get_center().y - 39.0, w, 78.0)
    draw_rect(Rect2(rect.position + Vector2(0.0, 5.0), rect.size), Color(0.03, 0.08, 0.05, 0.22 * alpha))
    draw_rect(rect, Color(0.05, 0.16, 0.11, 0.96 * alpha))
    draw_rect(rect, Color(0.44, 0.89, 0.65, alpha), false, 3.0)
    draw_string(v11_font, rect.position + Vector2(0.0, 31.0), "目標達成", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, Color(0.96, 1.0, 0.97, alpha))
    draw_string(v11_font, rect.position + Vector2(0.0, 57.0), "+¥%d  次の目標へ" % v08_goal_flash_reward, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Color(1.0, 0.89, 0.55, alpha))

func _v09_policy_name(policy: int) -> String:
    match policy:
        V09Policy.HOMES:
            return "住宅重視"
        V09Policy.JOBS:
            return "雇用重視"
        V09Policy.FLOW:
            return "交通重視"
        _:
            return "方針を選ぶ"

func _v09_draw_policy_chip() -> void:
    var rect: Rect2 = _v09_policy_chip_rect()
    var selected: bool = v09_policy != V09Policy.NONE
    draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.03, 0.08, 0.06, 0.14))
    draw_rect(rect, Color(0.06, 0.15, 0.11, 0.94))
    draw_rect(rect, Color("#5E9B7E") if selected else Color("#D6A750"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(8.0, 12.0), "都市方針", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 7, Color("#8FBCA5"))
    draw_string(v11_font, rect.position + Vector2(8.0, 25.0), _v09_policy_name(v09_policy), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 10, Color("#F3FFF7"))

func _v09_draw_policy_panel() -> void:
    var size: Vector2 = get_viewport_rect().size
    var panel: Rect2 = _v09_policy_panel_rect()
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.04, 0.52))
    draw_rect(Rect2(panel.position + Vector2(0.0, 6.0), panel.size), Color(0.02, 0.06, 0.04, 0.25))
    draw_rect(panel, Color("#10271E"))
    draw_rect(panel, Color("#66A889"), false, 2.0)

    draw_string(v11_font, panel.position + Vector2(16.0, 28.0), "都市方針を選択", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 17, Color("#F4FFF8"))
    var switch_text: String = "初回は無料" if v09_policy == V09Policy.NONE else "変更費用 ¥%d" % V09_POLICY_SWITCH_COST
    draw_string(v11_font, panel.position + Vector2(16.0, 51.0), switch_text, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 10, Color("#A8D2BD"))

    var policies: Array = [
        {"id": V09Policy.HOMES, "title": "住宅重視", "benefit": "住宅が増えやすい・幸福度上昇", "trade": "税収効率が少し低下"},
        {"id": V09Policy.JOBS, "title": "雇用重視", "benefit": "雇用が増えやすい・税収25%上昇", "trade": "幸福度が少し低下"},
        {"id": V09Policy.FLOW, "title": "交通重視", "benefit": "道路容量30%上昇", "trade": "税収効率が少し低下"}
    ]

    for i: int in range(3):
        var item: Dictionary = policies[i] as Dictionary
        var rect: Rect2 = _v09_policy_option_rect(i)
        var active: bool = int(item["id"]) == v09_policy
        var bg: Color = Color("#1C4938") if active else Color("#18372B")
        draw_rect(rect, bg)
        draw_rect(rect, Color("#75D0A3") if active else Color("#3F6C58"), false, 2.0 if active else 1.0)
        draw_rect(Rect2(rect.position, Vector2(5.0, rect.size.y)), _v09_policy_color(int(item["id"])))
        draw_string(v11_font, rect.position + Vector2(14.0, 21.0), String(item["title"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 14, Color("#F4FFF8"))
        draw_string(v11_font, rect.position + Vector2(14.0, 40.0), String(item["benefit"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 9, Color("#BFE6D2"))
        draw_string(v11_font, rect.position + Vector2(14.0, 56.0), String(item["trade"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 8, Color("#E6C89B"))

    draw_string(v11_font, panel.position + Vector2(16.0, panel.size.y - 14.0), "外側をタップして閉じる", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 8, Color("#7FA692"))

func _v10_draw_preview_cost() -> void:
    if not dragging or current_tool != Tool.ROAD:
        return
    var new_count: int = 0
    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if _in_bounds(p) and int(grid[p.y][p.x]) == Cell.EMPTY:
            new_count += 1
    if new_count <= 0:
        return
    var pill: Rect2 = Rect2(board_rect.get_center().x - 68.0, board_rect.end.y - 39.0, 136.0, 29.0)
    draw_rect(pill, Color(0.05, 0.13, 0.09, 0.94))
    draw_rect(pill, Color("#71D0A2"), false, 1.0)
    draw_string(v11_font, pill.position + Vector2(0.0, 20.0), "%dマス  -¥%d" % [new_count, new_count * ROAD_COST], HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 10, Color("#F3FFF7"))

func _v10_draw_projected_effects() -> void:
    if not is_instance_valid(v10_camera) or not is_instance_valid(v10_viewport):
        return
    var vp_size: Vector2 = Vector2(v10_viewport.size)
    for item: Variant in v04_cell_fx:
        var fx: Dictionary = item as Dictionary
        var p: Vector2i = fx["p"] as Vector2i
        var life: float = float(fx["life"])
        var max_life: float = maxf(0.001, float(fx["max_life"]))
        var ratio: float = clampf(life / max_life, 0.0, 1.0)
        var world: Vector3 = _v10_world_position(p, 0.75)
        var projected: Vector2 = v10_camera.unproject_position(world)
        if projected.x < 0.0 or projected.y < 0.0 or projected.x > vp_size.x or projected.y > vp_size.y:
            continue
        var screen: Vector2 = board_rect.position + Vector2(projected.x / vp_size.x * board_rect.size.x, projected.y / vp_size.y * board_rect.size.y)
        var ring_color: Color = Color(0.43, 0.91, 0.67, ratio * 0.76)
        if str(fx["kind"]) == "road":
            ring_color = Color(0.40, 0.88, 0.84, ratio * 0.74)
        draw_circle(screen, 8.0 + (1.0 - ratio) * 7.0, ring_color, false, 2.0)
        var label: String = _v11_fx_label(str(fx["label"]))
        if not label.is_empty():
            draw_string(v11_font, screen + Vector2(-50.0, -11.0 - (1.0 - ratio) * 13.0), label, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 9, Color(0.08, 0.22, 0.15, minf(1.0, ratio * 1.8)))

func _v11_fx_label(source: String) -> String:
    if source.contains("POP"):
        var digits: String = ""
        for c: String in source:
            if c >= "0" and c <= "9":
                digits += c
        return "人口 +" + digits if not digits.is_empty() else "人口"
    if source.contains("JOBS"):
        var digits: String = ""
        for c: String in source:
            if c >= "0" and c <= "9":
                digits += c
        return "雇用 +" + digits if not digits.is_empty() else "雇用"
    return ""
