extends "res://main_v16_traffic.gd"

# MACHI LOOP v0.17 — Functional Build FB-3: operating economy & recovery.
# Roads now create recurring costs. Overbuilding can produce a deficit, while
# removing unnecessary roads returns a small salvage amount and lowers upkeep.

const EconomyModel = preload("res://domain/economy_model.gd")

var v17_gross_revenue: int = 0
var v17_operating_cost: int = 0
var v17_net_balance: int = 0
var v17_economy_status: String = "healthy"

func _draw() -> void:
    super._draw()
    if not v09_policy_panel_open and v17_net_balance < 0:
        _v17_draw_deficit_warning()

func _recalculate_city() -> void:
    super._recalculate_city()
    var metrics: Dictionary = _v16_network_metrics()
    var arterial_count: int = int(metrics["arterial_count"])
    var local_count: int = maxi(0, int(metrics["road_count"]) - arterial_count)
    var economy: Dictionary = EconomyModel.calculate(
        maxi(0, tax_income),
        arterial_count,
        local_count,
        int(metrics["widened_count"]),
        city_level
    )
    v17_gross_revenue = int(economy["gross_revenue"])
    v17_operating_cost = int(economy["operating_cost"])
    v17_net_balance = int(economy["net_balance"])
    v17_economy_status = str(economy["status"])

    # The parent simulation adds tax_income every collection interval. Clamp the
    # applied loss to current cash so persistence never observes negative money.
    tax_income = maxi(-cash, v17_net_balance)

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

    var balance_color: Color = Color("#BCE0CD")
    if v17_net_balance < 0:
        balance_color = Color("#FFAF8C")
    elif v17_net_balance <= 3:
        balance_color = Color("#FFD28C")
    draw_string(v11_font, Vector2(cards_x, 108.0), "収支 %s   幸福 %d%%" % [_v17_signed_yen(v17_net_balance), happiness], HORIZONTAL_ALIGNMENT_LEFT, 220.0, 10, balance_color)
    var next_text: String = "最大都市" if city_level >= 4 else "次の地区 %d/%d" % [population, _v04_next_unlock_target()]
    draw_string(v11_font, Vector2(size.x - 142.0, 108.0), next_text, HORIZONTAL_ALIGNMENT_RIGHT, 126.0, 8, Color("#A6CCB9"))

    var bar: Rect2 = Rect2(cards_x, 115.0, cards_w, 6.0)
    draw_rect(bar, Color("#29463A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * _v04_unlock_progress(), bar.size.y)), Color("#71D0A2"))

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
        Tool.BULLDOZE: "道路は資金回収",
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
        draw_string(v11_font, rect.position + Vector2(30.0, 46.0), str(subs[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 38.0, 8, sub_fg)

func _bulldoze(p: Vector2i) -> void:
    if not _in_bounds(p):
        return
    var original: int = int(grid[p.y][p.x])
    var was_widened: bool = widened.has(_key(p))
    super._bulldoze(p)
    if original not in [Cell.ARTERIAL, Cell.LOCAL] or int(grid[p.y][p.x]) != Cell.EMPTY:
        return

    var salvage: int = 4 if original == Cell.ARTERIAL else 2
    if was_widened:
        salvage += 4
    # Parent removal paid REMOVE_COST. Reverse it and then add the salvage value.
    cash += REMOVE_COST + salvage
    v04_cash_flash = 0.55
    _recalculate_city()
    _toast("SALVAGE +Y%d" % salvage)
    _v07_save_city()
    queue_redraw()

func _v11_banner_text(source: String) -> String:
    if source.begins_with("SALVAGE +Y"):
        var value: String = source.trim_prefix("SALVAGE +Y")
        return "道路撤去・資金 +¥%s回収" % value
    return super._v11_banner_text(source)

func _v17_signed_yen(value: int) -> String:
    if value > 0:
        return "+¥%d" % value
    if value < 0:
        return "-¥%d" % absi(value)
    return "±¥0"

func _v17_draw_deficit_warning() -> void:
    var w: float = minf(board_rect.size.x - 28.0, 224.0)
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + 166.0, w, 47.0)
    draw_rect(Rect2(rect.position + Vector2(0.0, 3.0), rect.size), Color(0.05, 0.03, 0.02, 0.18))
    draw_rect(rect, Color(0.26, 0.10, 0.07, 0.94))
    draw_rect(rect, Color("#E17B61"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(10.0, 18.0), "財政赤字 %s   維持費 ¥%d" % [_v17_signed_yen(v17_net_balance), v17_operating_cost], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 9, Color("#FFF1EA"))
    draw_string(v11_font, rect.position + Vector2(10.0, 36.0), "不要道路を撤去して維持費を削減", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 8, Color("#FFD3C6"))
