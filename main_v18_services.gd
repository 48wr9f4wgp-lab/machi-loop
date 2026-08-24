extends "res://main_v17_economy.gd"

# MACHI LOOP v0.18 — Functional Build FB-4: high-level city services.
# Strategic city-wide toggles replace repetitive facility placement.

const ServiceModel = preload("res://domain/service_model.gd")
const V18_SAVE_SCHEMA_VERSION: int = 4
const V18_SERVICE_START_COST: int = 140

enum V18Service { MOBILITY, SAFETY, EDUCATION, GREEN }

var v18_mobility: bool = false
var v18_safety: bool = false
var v18_education: bool = false
var v18_green: bool = false
var v18_service_panel_open: bool = false

func _draw() -> void:
    super._draw()
    if city_level >= 2 and not v09_policy_panel_open:
        _v18_draw_service_chip()
    if v18_service_panel_open:
        _v18_draw_service_panel()

func _pointer_down(pos: Vector2) -> void:
    if v18_service_panel_open:
        var choice: int = _v18_service_choice_at(pos)
        if choice >= 0:
            _v18_toggle_service(choice)
            return
        if not _v18_service_panel_rect().has_point(pos):
            v18_service_panel_open = false
            queue_redraw()
        return

    if v09_policy_panel_open:
        super._pointer_down(pos)
        return

    if city_level >= 2 and _v18_service_chip_rect().has_point(pos):
        v18_service_panel_open = true
        queue_redraw()
        return

    super._pointer_down(pos)

func _road_capacity(p: Vector2i) -> float:
    var base_capacity: float = super._road_capacity(p)
    var summary: Dictionary = _v18_service_summary()
    return base_capacity * float(summary["road_capacity_multiplier"])

func _v15_update_demand() -> void:
    super._v15_update_demand()
    var summary: Dictionary = _v18_service_summary()
    v15_residential_demand = clampi(v15_residential_demand + int(summary["residential_demand_bonus"]), 0, 100)
    v15_commercial_demand = clampi(v15_commercial_demand + int(summary["commercial_demand_bonus"]), 0, 100)
    v15_industrial_demand = clampi(v15_industrial_demand + int(summary["industrial_demand_bonus"]), 0, 100)

func _recalculate_city() -> void:
    super._recalculate_city()
    var summary: Dictionary = _v18_service_summary()

    happiness = clampi(happiness + int(summary["happiness_bonus"]), 35, 100)
    v17_gross_revenue = maxi(0, int(round(float(v17_gross_revenue) * float(summary["revenue_multiplier"]))))
    v17_operating_cost += int(summary["operating_cost"])
    v17_net_balance = v17_gross_revenue - v17_operating_cost
    if v17_net_balance < 0:
        v17_economy_status = "deficit"
    elif v17_net_balance <= 3:
        v17_economy_status = "tight"
    else:
        v17_economy_status = "healthy"
    tax_income = maxi(-cash, v17_net_balance)

    # Re-run demand after service happiness/effect modifiers settle.
    _v15_update_demand()

func _v18_service_summary() -> Dictionary:
    return ServiceModel.summarize(v18_mobility, v18_safety, v18_education, v18_green)

func _v18_service_active(service_id: int) -> bool:
    match service_id:
        V18Service.MOBILITY:
            return v18_mobility
        V18Service.SAFETY:
            return v18_safety
        V18Service.EDUCATION:
            return v18_education
        V18Service.GREEN:
            return v18_green
        _:
            return false

func _v18_set_service(service_id: int, active: bool) -> void:
    match service_id:
        V18Service.MOBILITY:
            v18_mobility = active
        V18Service.SAFETY:
            v18_safety = active
        V18Service.EDUCATION:
            v18_education = active
        V18Service.GREEN:
            v18_green = active

func _v18_toggle_service(service_id: int) -> void:
    var active: bool = _v18_service_active(service_id)
    if active:
        _v18_set_service(service_id, false)
        _toast("SERVICE OFF %d" % service_id)
    else:
        if cash < V18_SERVICE_START_COST:
            _toast("SERVICE NEED Y%d" % V18_SERVICE_START_COST)
            return
        cash -= V18_SERVICE_START_COST
        _v18_set_service(service_id, true)
        v04_cash_flash = 0.70
        _toast("SERVICE ON %d" % service_id)

    _recalculate_city()
    _v07_save_city()
    queue_redraw()

func _v18_service_chip_rect() -> Rect2:
    var w: float = 112.0
    return Rect2(board_rect.end.x - w - 9.0, board_rect.position.y + 101.0, w, 34.0)

func _v18_draw_service_chip() -> void:
    var rect: Rect2 = _v18_service_chip_rect()
    var active_count: int = int(v18_mobility) + int(v18_safety) + int(v18_education) + int(v18_green)
    draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.03, 0.08, 0.06, 0.14))
    draw_rect(rect, Color(0.06, 0.15, 0.11, 0.94))
    draw_rect(rect, Color("#5E9B7E"), false, 1.0)
    draw_string(v11_font, rect.position + Vector2(8.0, 13.0), "都市サービス", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 7, Color("#8FBCA5"))
    draw_string(v11_font, rect.position + Vector2(8.0, 27.0), "%d / 4 稼働" % active_count, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 9, Color("#F3FFF7"))

func _v18_service_panel_rect() -> Rect2:
    var size: Vector2 = get_viewport_rect().size
    var w: float = minf(size.x - 28.0, 370.0)
    var h: float = 374.0
    return Rect2((size.x - w) * 0.5, maxf(TOP_H + 12.0, (size.y - h) * 0.5), w, h)

func _v18_service_option_rect(index: int) -> Rect2:
    var panel: Rect2 = _v18_service_panel_rect()
    return Rect2(panel.position.x + 16.0, panel.position.y + 68.0 + float(index) * 68.0, panel.size.x - 32.0, 58.0)

func _v18_service_choice_at(pos: Vector2) -> int:
    for i: int in range(4):
        if _v18_service_option_rect(i).has_point(pos):
            return i
    return -1

func _v18_draw_service_panel() -> void:
    var size: Vector2 = get_viewport_rect().size
    var panel: Rect2 = _v18_service_panel_rect()
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.04, 0.54))
    draw_rect(Rect2(panel.position + Vector2(0.0, 6.0), panel.size), Color(0.02, 0.06, 0.04, 0.25))
    draw_rect(panel, Color("#10271E"))
    draw_rect(panel, Color("#66A889"), false, 2.0)

    draw_string(v11_font, panel.position + Vector2(16.0, 27.0), "都市サービス", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 17, Color("#F4FFF8"))
    draw_string(v11_font, panel.position + Vector2(16.0, 49.0), "開始 ¥140・停止無料 / 維持費は収支へ反映", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 9, Color("#A8D2BD"))

    var rows: Array = [
        {"title": "交通支援", "benefit": "道路容量 +15%", "cost": "維持費 ¥4", "color": Color("#6EB6D2")},
        {"title": "安全", "benefit": "幸福 +5", "cost": "維持費 ¥3", "color": Color("#D68A70")},
        {"title": "教育", "benefit": "商業需要 +10・収入 +8%", "cost": "維持費 ¥4", "color": Color("#D4B45F")},
        {"title": "緑化", "benefit": "住宅需要 +10・幸福 +3", "cost": "工業需要 -4 / 維持費 ¥3", "color": Color("#72B981")}
    ]

    for i: int in range(4):
        var item: Dictionary = rows[i] as Dictionary
        var rect: Rect2 = _v18_service_option_rect(i)
        var active: bool = _v18_service_active(i)
        draw_rect(rect, Color("#1C4938") if active else Color("#18372B"))
        draw_rect(rect, Color("#75D0A3") if active else Color("#3F6C58"), false, 2.0 if active else 1.0)
        draw_rect(Rect2(rect.position, Vector2(5.0, rect.size.y)), item["color"] as Color)
        draw_string(v11_font, rect.position + Vector2(14.0, 20.0), String(item["title"]) + ("  ON" if active else "  OFF"), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 13, Color("#F4FFF8"))
        draw_string(v11_font, rect.position + Vector2(14.0, 38.0), String(item["benefit"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 9, Color("#BFE6D2"))
        draw_string(v11_font, rect.position + Vector2(14.0, 52.0), String(item["cost"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 8, Color("#E6C89B"))

    draw_string(v11_font, panel.position + Vector2(16.0, panel.size.y - 14.0), "外側をタップして閉じる", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 8, Color("#7FA692"))

func _v11_banner_text(source: String) -> String:
    if source.begins_with("SERVICE NEED"):
        return "サービス開始には ¥%d 必要" % V18_SERVICE_START_COST
    if source.begins_with("SERVICE ON"):
        return "都市サービスを開始"
    if source.begins_with("SERVICE OFF"):
        return "都市サービスを停止"
    return super._v11_banner_text(source)

# Save schema v4 adds persistent city-service toggles while preserving v3/v2/v1 migration.
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
        "schema_version": V18_SAVE_SCHEMA_VERSION,
        "payload_json": payload_json,
        "checksum": payload_json.sha256_text()
    }

    var temp_file: FileAccess = FileAccess.open(V08_SAVE_TEMP_PATH, FileAccess.WRITE)
    if temp_file == null:
        return
    temp_file.store_string(JSON.stringify(envelope))
    temp_file.close()

    if FileAccess.file_exists(SAVE_PATH):
        if _v18_path_is_valid(SAVE_PATH):
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
    if _v18_load_from_path(SAVE_PATH):
        return true
    if _v18_load_from_path(V08_SAVE_BACKUP_PATH):
        if FileAccess.file_exists(SAVE_PATH):
            DirAccess.remove_absolute(SAVE_PATH)
        _v07_save_city()
        return true
    return false

func _v18_load_from_path(path: String) -> bool:
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

    if schema == V18_SAVE_SCHEMA_VERSION:
        var payload_json: String = str(root.get("payload_json", ""))
        if payload_json.is_empty() or payload_json.sha256_text() != str(root.get("checksum", "")):
            return false
        var payload_variant: Variant = JSON.parse_string(payload_json)
        if not payload_variant is Dictionary:
            return false
        var payload: Dictionary = payload_variant as Dictionary
        if not _v08_apply_payload(payload, false):
            return false
        v09_policy = clampi(int(payload.get("policy_id", V09Policy.NONE)), V09Policy.NONE, V09Policy.FLOW)
        var services_variant: Variant = payload.get("services", {})
        var services: Dictionary = services_variant as Dictionary if services_variant is Dictionary else {}
        v18_mobility = bool(services.get("mobility", false))
        v18_safety = bool(services.get("safety", false))
        v18_education = bool(services.get("education", false))
        v18_green = bool(services.get("green", false))
        _recalculate_city()
        return true

    if _v09_load_from_path(path):
        v18_mobility = false
        v18_safety = false
        v18_education = false
        v18_green = false
        _recalculate_city()
        return true
    return false

func _v18_path_is_valid(path: String) -> bool:
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
    if int(root.get("schema_version", 0)) == V18_SAVE_SCHEMA_VERSION:
        var payload_json: String = str(root.get("payload_json", ""))
        return not payload_json.is_empty() and payload_json.sha256_text() == str(root.get("checksum", ""))
    return _v09_path_is_valid(path)
