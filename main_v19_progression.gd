extends "res://main_v18_services.gd"

# MACHI LOOP v0.19 — Functional Build FB-5: six-tier progression.
# Higher city tiers expand management capacity instead of only inflating numbers.

const ProgressionModel = preload("res://domain/progression_model.gd")
const V19_SAVE_SCHEMA_VERSION: int = 5

func _draw_header(size: Vector2) -> void:
    draw_rect(Rect2(0.0, 0.0, size.x, TOP_H), Color("#10261D"))
    draw_rect(Rect2(0.0, TOP_H - 3.0, size.x, 3.0), Color("#71D0A2"))
    var latin: Font = ThemeDB.fallback_font

    draw_string(latin, Vector2(MARGIN + 4.0, 28.0), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color("#F7FFF9"))
    draw_string(v11_font, Vector2(MARGIN + 4.0, 47.0), "街の流れをつくり、都市を育てる。", HORIZONTAL_ALIGNMENT_LEFT, size.x - 120.0, 10, Color("#9BC9B4"))

    var level_rect: Rect2 = Rect2(size.x - 94.0, 12.0, 80.0, 25.0)
    draw_rect(level_rect, Color("#1A3A2E"))
    draw_rect(level_rect, Color("#4D7865"), false, 1.0)
    draw_string(v11_font, level_rect.position + Vector2(0.0, 17.0), "LV%d %s" % [city_level, ProgressionModel.tier_name(city_level)], HORIZONTAL_ALIGNMENT_CENTER, level_rect.size.x, 8, Color("#DDF4E7"))

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

    var next_text: String
    if city_level >= 6:
        next_text = "最高ランク"
    else:
        next_text = "次 %d/%d" % [population, ProgressionModel.next_target(city_level)]
    draw_string(v11_font, Vector2(size.x - 142.0, 108.0), next_text, HORIZONTAL_ALIGNMENT_RIGHT, 126.0, 8, Color("#A6CCB9"))

    var bar: Rect2 = Rect2(cards_x, 115.0, cards_w, 6.0)
    draw_rect(bar, Color("#29463A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * ProgressionModel.progress_to_next(population, city_level), bar.size.y)), Color("#71D0A2"))

func _check_unlocks() -> void:
    var target_level: int = ProgressionModel.tier_for_population(population)
    var target_cols: int = ProgressionModel.unlocked_cols(target_level)
    if target_level <= city_level and target_cols <= unlocked_cols:
        return

    var previous_level: int = city_level
    city_level = maxi(city_level, target_level)
    unlocked_cols = maxi(unlocked_cols, target_cols)
    var reward: int = 180 * city_level
    if city_level > previous_level:
        cash += reward
        v04_cash_flash = 0.85
        v04_level_flash = 0.95
        _toast("CITY LV %d  +Y%d" % [city_level, reward])
        _recalculate_city()
        _v07_save_city()

func _v04_next_unlock_target() -> int:
    return ProgressionModel.next_target(city_level)

func _v04_unlock_progress() -> float:
    return ProgressionModel.progress_to_next(population, city_level)

func _v18_toggle_service(service_id: int) -> void:
    if _v18_service_active(service_id):
        super._v18_toggle_service(service_id)
        return

    var active_count: int = _v19_active_service_count()
    var slot_limit: int = ProgressionModel.service_slots(city_level)
    if active_count >= slot_limit:
        _toast("SERVICE SLOTS FULL")
        return
    super._v18_toggle_service(service_id)

func _v18_draw_service_chip() -> void:
    var rect: Rect2 = _v18_service_chip_rect()
    var active_count: int = _v19_active_service_count()
    var slot_limit: int = ProgressionModel.service_slots(city_level)
    draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.03, 0.08, 0.06, 0.14))
    draw_rect(rect, Color(0.06, 0.15, 0.11, 0.94))
    draw_rect(rect, Color("#5E9B7E"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(8.0, 13.0), "都市サービス", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 7, Color("#8FBCA5"))
    draw_string(v11_font, rect.position + Vector2(8.0, 27.0), "%d / %d 枠" % [active_count, slot_limit], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 9, Color("#F3FFF7"))

func _v18_draw_service_panel() -> void:
    super._v18_draw_service_panel()
    var panel: Rect2 = _v18_service_panel_rect()
    draw_string(v11_font, panel.position + Vector2(panel.size.x - 110.0, 27.0), "利用枠 %d/%d" % [_v19_active_service_count(), ProgressionModel.service_slots(city_level)], HORIZONTAL_ALIGNMENT_RIGHT, 94.0, 8, Color("#A8D2BD"))

func _recalculate_city() -> void:
    super._recalculate_city()
    if city_level >= 6:
        var service_summary: Dictionary = _v18_service_summary()
        var full_service_cost: int = int(service_summary["operating_cost"])
        var discounted_cost: int = int(round(float(full_service_cost) * ProgressionModel.metropolitan_service_cost_multiplier(city_level)))
        var rebate: int = maxi(0, full_service_cost - discounted_cost)
        if rebate > 0:
            v17_operating_cost = maxi(0, v17_operating_cost - rebate)
            v17_net_balance = v17_gross_revenue - v17_operating_cost
            v17_economy_status = "deficit" if v17_net_balance < 0 else ("tight" if v17_net_balance <= 3 else "healthy")
            tax_income = maxi(-cash, v17_net_balance)

func _v08_draw_goal_card() -> void:
    if v08_goal_stage < V08_GOAL_COUNT:
        super._v08_draw_goal_card()
        return

    var w: float = minf(board_rect.size.x - 24.0, 330.0)
    var h: float = 58.0
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.end.y - h - 10.0, w, h)
    draw_rect(Rect2(rect.position + Vector2(0.0, 3.0), rect.size), Color(0.04, 0.09, 0.07, 0.15))
    draw_rect(rect, Color(0.055, 0.14, 0.105, 0.94))
    draw_rect(rect, Color("#42705B"), false, 1.0)

    if city_level >= 6:
        draw_string(v11_font, rect.position + Vector2(12.0, 22.0), "都市ランク完成", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 9, Color("#86B89F"))
        draw_string(v11_font, rect.position + Vector2(12.0, 44.0), "メトロポリス到達", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 14, Color("#E9FFF2"))
        return

    var next_tier: int = city_level + 1
    var target: int = ProgressionModel.next_target(city_level)
    draw_string(v11_font, rect.position + Vector2(12.0, 17.0), "次の都市ランク", HORIZONTAL_ALIGNMENT_LEFT, 130.0, 8, Color("#86B89F"))
    draw_string(v11_font, rect.position + Vector2(12.0, 36.0), ProgressionModel.tier_name(next_tier), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 13, Color("#F4FFF8"))
    draw_string(v11_font, rect.position + Vector2(12.0, 51.0), "人口 %d / %d" % [population, target], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 9, Color("#B9DDCB"))
    var bar: Rect2 = Rect2(rect.position.x + 12.0, rect.end.y - 5.0, rect.size.x - 24.0, 3.0)
    draw_rect(bar, Color("#28483A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * ProgressionModel.progress_to_next(population, city_level), bar.size.y)), Color("#71D0A2"))

func _v19_active_service_count() -> int:
    return int(v18_mobility) + int(v18_safety) + int(v18_education) + int(v18_green)

func _v11_banner_text(source: String) -> String:
    if source == "SERVICE SLOTS FULL":
        return "都市ランクを上げるとサービス枠が増加"
    if source.begins_with("CITY LV"):
        return "都市ランク上昇  %s" % ProgressionModel.tier_name(city_level)
    return super._v11_banner_text(source)

# Save schema v5 stores city tiers 1–6 while retaining service/policy state and migration.
func _v07_save_city() -> void:
    if not _v07_has_meaningful_state() and not FileAccess.file_exists(SAVE_PATH):
        return

    var payload: Dictionary = {
        "grid": grid,
        "widened": widened.duplicate(true),
        "cash": cash,
        "unlocked_cols": unlocked_cols,
        "city_level": city_level,
        "tick_count": tick_count,
        "first_growth_seeded": v04_first_growth_seeded,
        "rng_state": str(rng.state),
        "goal_stage": v08_goal_stage,
        "policy_id": v09_policy,
        "services": {
            "mobility": v18_mobility,
            "safety": v18_safety,
            "education": v18_education,
            "green": v18_green
        }
    }
    var payload_json: String = JSON.stringify(payload)
    var envelope: Dictionary = {
        "schema_version": V19_SAVE_SCHEMA_VERSION,
        "payload_json": payload_json,
        "checksum": payload_json.sha256_text()
    }

    var temp_file: FileAccess = FileAccess.open(V08_SAVE_TEMP_PATH, FileAccess.WRITE)
    if temp_file == null:
        return
    temp_file.store_string(JSON.stringify(envelope))
    temp_file.close()

    if FileAccess.file_exists(SAVE_PATH):
        if _v19_path_is_valid(SAVE_PATH):
            if FileAccess.file_exists(V08_SAVE_BACKUP_PATH):
                DirAccess.remove_absolute(V08_SAVE_BACKUP_PATH)
            if DirAccess.rename_absolute(SAVE_PATH, V08_SAVE_BACKUP_PATH) != OK:
                return
        else:
            DirAccess.remove_absolute(SAVE_PATH)

    if DirAccess.rename_absolute(V08_SAVE_TEMP_PATH, SAVE_PATH) != OK:
        if FileAccess.file_exists(V08_SAVE_BACKUP_PATH) and not FileAccess.file_exists(SAVE_PATH):
            DirAccess.rename_absolute(V08_SAVE_BACKUP_PATH, SAVE_PATH)
        return

    v07_last_saved_tick = tick_count

func _v07_load_city() -> bool:
    if _v19_load_from_path(SAVE_PATH):
        return true
    if _v19_load_from_path(V08_SAVE_BACKUP_PATH):
        if FileAccess.file_exists(SAVE_PATH):
            DirAccess.remove_absolute(SAVE_PATH)
        _v07_save_city()
        return true
    return false

func _v19_load_from_path(path: String) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return false
    var raw: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(raw)
    if not parsed is Dictionary:
        return false
    var root: Dictionary = parsed as Dictionary
    var schema: int = int(root.get("schema_version", 0))

    if schema == V19_SAVE_SCHEMA_VERSION:
        var payload_json: String = str(root.get("payload_json", ""))
        if payload_json.is_empty() or payload_json.sha256_text() != str(root.get("checksum", "")):
            return false
        var payload_variant: Variant = JSON.parse_string(payload_json)
        if not payload_variant is Dictionary:
            return false
        var payload: Dictionary = payload_variant as Dictionary
        if not _v08_apply_payload(payload, false):
            return false
        city_level = clampi(int(payload.get("city_level", city_level)), 1, 6)
        unlocked_cols = clampi(int(payload.get("unlocked_cols", ProgressionModel.unlocked_cols(city_level))), START_UNLOCKED_COLS, GRID_W)
        v09_policy = clampi(int(payload.get("policy_id", V09Policy.NONE)), V09Policy.NONE, V09Policy.FLOW)
        var services_variant: Variant = payload.get("services", {})
        var services: Dictionary = services_variant as Dictionary if services_variant is Dictionary else {}
        v18_mobility = bool(services.get("mobility", false))
        v18_safety = bool(services.get("safety", false))
        v18_education = bool(services.get("education", false))
        v18_green = bool(services.get("green", false))
        _recalculate_city()
        return true

    if _v18_load_from_path(path):
        _recalculate_city()
        return true
    return false

func _v19_path_is_valid(path: String) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return false
    var raw: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(raw)
    if not parsed is Dictionary:
        return false
    var root: Dictionary = parsed as Dictionary
    if int(root.get("schema_version", 0)) == V19_SAVE_SCHEMA_VERSION:
        var payload_json: String = str(root.get("payload_json", ""))
        return not payload_json.is_empty() and payload_json.sha256_text() == str(root.get("checksum", ""))
    return _v18_path_is_valid(path)
