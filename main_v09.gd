extends "res://main_v08_1.gd"

# MACHI LOOP v0.9 — city policy choice layer.
# Adds a deliberate strategic tradeoff before the 3D vertical slice.

enum V09Policy { NONE, HOMES, JOBS, FLOW }

const V09_POLICY_SWITCH_COST: int = 120
const V09_SAVE_SCHEMA_VERSION: int = 3

var v09_policy: int = V09Policy.NONE
var v09_policy_panel_open: bool = false
var v09_policy_prompted: bool = false

func _process(delta: float) -> void:
    super._process(delta)
    if v09_policy == V09Policy.NONE and population >= 26 and not v09_policy_prompted:
        v09_policy_panel_open = true
        v09_policy_prompted = true
        queue_redraw()

func _draw() -> void:
    super._draw()
    if population >= 26 or v09_policy != V09Policy.NONE:
        _v09_draw_policy_chip()
    if v09_policy_panel_open:
        _v09_draw_policy_panel()

func _pointer_down(pos: Vector2) -> void:
    if v09_policy_panel_open:
        var choice: int = _v09_policy_choice_at(pos)
        if choice != V09Policy.NONE:
            _v09_select_policy(choice)
            return
        if not _v09_policy_panel_rect().has_point(pos):
            v09_policy_panel_open = false
            queue_redraw()
        return

    if (population >= 26 or v09_policy != V09Policy.NONE) and _v09_policy_chip_rect().has_point(pos):
        v09_policy_panel_open = true
        queue_redraw()
        return

    super._pointer_down(pos)

func _choose_building_type() -> int:
    if v09_policy == V09Policy.NONE or v09_policy == V09Policy.FLOW:
        return super._choose_building_type()

    var homes: int = _count_cells(Cell.RESIDENTIAL)
    var commerce: int = _count_cells(Cell.COMMERCIAL)
    var industry: int = _count_cells(Cell.INDUSTRIAL)
    if homes < 2:
        return Cell.RESIDENTIAL

    var estimated_jobs: int = commerce * 8 + industry * 11
    var estimated_pop: int = homes * 13

    if v09_policy == V09Policy.HOMES:
        if float(estimated_jobs) < float(estimated_pop) * 0.42:
            return Cell.COMMERCIAL if commerce <= industry else Cell.INDUSTRIAL
        var home_roll: float = rng.randf()
        if home_roll < 0.72:
            return Cell.RESIDENTIAL
        if home_roll < 0.89:
            return Cell.COMMERCIAL
        return Cell.INDUSTRIAL

    # JOBS policy still keeps enough housing so the city cannot starve itself.
    if float(estimated_pop) < float(estimated_jobs) * 0.72:
        return Cell.RESIDENTIAL
    var jobs_roll: float = rng.randf()
    if jobs_roll < 0.32:
        return Cell.RESIDENTIAL
    if jobs_roll < 0.70:
        return Cell.COMMERCIAL
    return Cell.INDUSTRIAL

func _road_capacity(p: Vector2i) -> float:
    var base_capacity: float = super._road_capacity(p)
    if v09_policy == V09Policy.FLOW:
        return base_capacity * 1.30
    return base_capacity

func _recalculate_city() -> void:
    super._recalculate_city()
    match v09_policy:
        V09Policy.HOMES:
            happiness = mini(100, happiness + 5)
            tax_income = maxi(0, int(round(float(tax_income) * 0.92)))
        V09Policy.JOBS:
            happiness = maxi(35, happiness - 4)
            tax_income = maxi(0, int(round(float(tax_income) * 1.25)))
        V09Policy.FLOW:
            happiness = mini(100, happiness + 2)
            tax_income = maxi(0, int(round(float(tax_income) * 0.90)))

func _v09_select_policy(policy: int) -> void:
    if policy == v09_policy:
        v09_policy_panel_open = false
        queue_redraw()
        return

    var cost: int = 0 if v09_policy == V09Policy.NONE else V09_POLICY_SWITCH_COST
    if cash < cost:
        _toast("NEED Y%d TO SWITCH" % V09_POLICY_SWITCH_COST)
        return

    cash -= cost
    v09_policy = policy
    v09_policy_panel_open = false
    _recalculate_city()
    v04_cash_flash = 0.75
    _toast("POLICY: %s" % _v09_policy_name(policy))
    _v07_save_city()
    queue_redraw()

func _v09_policy_name(policy: int) -> String:
    match policy:
        V09Policy.HOMES:
            return "HOMES"
        V09Policy.JOBS:
            return "JOBS"
        V09Policy.FLOW:
            return "FLOW"
        _:
            return "CHOOSE"

func _v09_policy_chip_rect() -> Rect2:
    var w: float = 112.0
    return Rect2(board_rect.end.x - w - 9.0, board_rect.position.y + 62.0, w, 32.0)

func _v09_draw_policy_chip() -> void:
    var rect: Rect2 = _v09_policy_chip_rect()
    var font: Font = ThemeDB.fallback_font
    var selected: bool = v09_policy != V09Policy.NONE
    draw_rect(Rect2(rect.position + Vector2(0.0, 2.0), rect.size), Color(0.03, 0.08, 0.06, 0.14))
    draw_rect(rect, Color(0.06, 0.15, 0.11, 0.94))
    draw_rect(rect, Color("#5E9B7E") if selected else Color("#D6A750"), false, 1.0)
    draw_string(font, rect.position + Vector2(8.0, 12.0), "CITY POLICY", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 7, Color("#8FBCA5"))
    draw_string(font, rect.position + Vector2(8.0, 25.0), _v09_policy_name(v09_policy), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 11, Color("#F3FFF7"))

func _v09_policy_panel_rect() -> Rect2:
    var size: Vector2 = get_viewport_rect().size
    var w: float = minf(size.x - 28.0, 370.0)
    var h: float = 330.0
    return Rect2((size.x - w) * 0.5, maxf(TOP_H + 18.0, (size.y - h) * 0.5), w, h)

func _v09_policy_option_rect(index: int) -> Rect2:
    var panel: Rect2 = _v09_policy_panel_rect()
    return Rect2(panel.position.x + 16.0, panel.position.y + 77.0 + float(index) * 76.0, panel.size.x - 32.0, 64.0)

func _v09_policy_choice_at(pos: Vector2) -> int:
    for i: int in range(3):
        if _v09_policy_option_rect(i).has_point(pos):
            return [V09Policy.HOMES, V09Policy.JOBS, V09Policy.FLOW][i]
    return V09Policy.NONE

func _v09_draw_policy_panel() -> void:
    var size: Vector2 = get_viewport_rect().size
    var panel: Rect2 = _v09_policy_panel_rect()
    var font: Font = ThemeDB.fallback_font

    draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.04, 0.52))
    draw_rect(Rect2(panel.position + Vector2(0.0, 6.0), panel.size), Color(0.02, 0.06, 0.04, 0.25))
    draw_rect(panel, Color("#10271E"))
    draw_rect(panel, Color("#66A889"), false, 2.0)

    draw_string(font, panel.position + Vector2(16.0, 28.0), "CHOOSE CITY POLICY", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 18, Color("#F4FFF8"))
    var switch_text: String = "FIRST CHOICE FREE" if v09_policy == V09Policy.NONE else "SWITCH COST Y%d" % V09_POLICY_SWITCH_COST
    draw_string(font, panel.position + Vector2(16.0, 51.0), switch_text, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 10, Color("#A8D2BD"))

    var policies: Array = [
        {"id": V09Policy.HOMES, "title": "HOMES", "benefit": "MORE RESIDENTIAL  +HAPPY", "trade": "LOWER TAX EFFICIENCY"},
        {"id": V09Policy.JOBS, "title": "JOBS", "benefit": "MORE JOBS  +25% TAX", "trade": "SMALL HAPPY PENALTY"},
        {"id": V09Policy.FLOW, "title": "FLOW", "benefit": "+30% ROAD CAPACITY", "trade": "LOWER TAX EFFICIENCY"}
    ]

    for i: int in range(3):
        var item: Dictionary = policies[i] as Dictionary
        var rect: Rect2 = _v09_policy_option_rect(i)
        var active: bool = int(item["id"]) == v09_policy
        var bg: Color = Color("#1C4938") if active else Color("#18372B")
        draw_rect(rect, bg)
        draw_rect(rect, Color("#75D0A3") if active else Color("#3F6C58"), false, 2.0 if active else 1.0)
        draw_rect(Rect2(rect.position, Vector2(5.0, rect.size.y)), _v09_policy_color(int(item["id"])))
        draw_string(font, rect.position + Vector2(14.0, 21.0), String(item["title"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 15, Color("#F4FFF8"))
        draw_string(font, rect.position + Vector2(14.0, 40.0), String(item["benefit"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 9, Color("#BFE6D2"))
        draw_string(font, rect.position + Vector2(14.0, 56.0), String(item["trade"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 8, Color("#E6C89B"))

    draw_string(font, panel.position + Vector2(16.0, panel.size.y - 14.0), "TAP OUTSIDE TO CLOSE", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 32.0, 8, Color("#7FA692"))

func _v09_policy_color(policy: int) -> Color:
    match policy:
        V09Policy.HOMES:
            return Color("#7FCF8A")
        V09Policy.JOBS:
            return Color("#7FB9DE")
        V09Policy.FLOW:
            return Color("#E5BC64")
        _:
            return Color("#7FA692")

# Save schema v3 adds city policy while preserving v0.8/v0.7 migration and recovery.
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
        "policy_id": v09_policy
    }
    var payload_json: String = JSON.stringify(payload)
    var envelope: Dictionary = {
        "schema_version": V09_SAVE_SCHEMA_VERSION,
        "payload_json": payload_json,
        "checksum": payload_json.sha256_text()
    }

    var temp_file: FileAccess = FileAccess.open(V08_SAVE_TEMP_PATH, FileAccess.WRITE)
    if temp_file == null:
        return
    temp_file.store_string(JSON.stringify(envelope))
    temp_file.close()

    if FileAccess.file_exists(SAVE_PATH):
        if _v09_path_is_valid(SAVE_PATH):
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
    if _v09_load_from_path(SAVE_PATH):
        return true
    if _v09_load_from_path(V08_SAVE_BACKUP_PATH):
        if FileAccess.file_exists(SAVE_PATH):
            DirAccess.remove_absolute(SAVE_PATH)
        _v07_save_city()
        return true
    return false

func _v09_load_from_path(path: String) -> bool:
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
    if schema == V09_SAVE_SCHEMA_VERSION:
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
        return true

    if schema == V08_SAVE_SCHEMA_VERSION or int(root.get("version", 0)) == 1:
        if not _v08_load_from_path(path):
            return false
        v09_policy = V09Policy.NONE
        return true
    return false

func _v09_path_is_valid(path: String) -> bool:
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
    if schema == V09_SAVE_SCHEMA_VERSION or schema == V08_SAVE_SCHEMA_VERSION:
        var payload_json: String = str(root.get("payload_json", ""))
        return not payload_json.is_empty() and payload_json.sha256_text() == str(root.get("checksum", ""))
    return int(root.get("version", 0)) == 1
