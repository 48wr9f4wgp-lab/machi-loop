extends "res://main_v37_recovery_device_test.gd"

# AXIVA v0.42 repairs the v0.40 transaction boundary. The result below is the
# single source for feedback, first growth, progression, recovery and storage.
# No provisional EMPTY cells, partial payment or save-schema change.
const RoadPlan = preload("res://domain/road_plan.gd")
const V40_ACQUISITION_RESIDENTIAL: int = 20
const V40_ACQUISITION_COMMERCIAL: int = 32
const V40_ACQUISITION_INDUSTRIAL: int = 28

var v40_last_acquired_buildings: int = 0
var v40_last_acquisition_cost: int = 0
var v40_commit_count: int = 0
var v40_last_result: Dictionary = {}

func _v40_preview_metrics() -> Dictionary:
    return RoadPlan.quote(grid, drag_path, unlocked_cols, ROAD_COST, {
        Cell.RESIDENTIAL: V40_ACQUISITION_RESIDENTIAL,
        Cell.COMMERCIAL: V40_ACQUISITION_COMMERCIAL,
        Cell.INDUSTRIAL: V40_ACQUISITION_INDUSTRIAL
    })

func _commit_arterial() -> void:
    var plan: Dictionary = _v40_preview_metrics()
    v40_last_result = {"committed": false}
    if not bool(plan["valid"]) or int(plan["build_count"]) == 0:
        return
    if cash < int(plan["total_cost"]):
        _toast("NOT ENOUGH CASH")
        if v22_feedback != null:
            v22_feedback.insufficient_funds()
        return

    var first_road: bool = _count_cells(Cell.ARTERIAL) == 0
    var prior_recovery: int = v29_recovery_stage
    cash -= int(plan["total_cost"])
    for value: Variant in plan["cells"]:
        var p: Vector2i = value
        grid[p.y][p.x] = Cell.ARTERIAL
        widened.erase(_key(p))
        # Remove stale growth timing only for parcels actually acquired.
        v27_growth_schedule.erase(_key(p))
    v40_commit_count += 1
    v40_last_acquired_buildings = int(plan["acquisition_count"])
    v40_last_acquisition_cost = int(plan["acquisition_cost"])
    v40_last_result = plan.duplicate(true)
    v40_last_result["committed"] = true
    _v40_finish_road_commit(plan, first_road, prior_recovery)

func _v40_finish_road_commit(plan: Dictionary, first_road: bool, prior_recovery: int) -> void:
    # Reconstitute all active road-commit responsibilities, not just the old
    # goal assertion. Tested through current main + real touch event objects.
    _recalculate_city()
    v23_birth_started = true
    v23_birth_road_count = _count_cells(Cell.ARTERIAL)
    for value: Variant in plan["cells"]:
        _v04_add_fx(value, "road", "")
    if first_road and not v04_first_growth_seeded and population == 0:
        # Dynamic dispatch reaches v27 birth pulse and v28 choreography.
        _v04_seed_first_growth()
    if population > 0 and not v23_birth_announced:
        v23_birth_announced = true
        v23_birth_population = population
    _v08_evaluate_goal()
    _v20_refresh_ftue(true)
    if v22_feedback != null:
        v22_feedback.arterial_confirm()
    if prior_recovery in [V29_STAGE_PROBLEM, V29_STAGE_INTERVENTION]:
        var committed: Array[Vector2i] = []
        for value: Variant in plan["cells"]:
            committed.append(value)
        _v29_register_intervention(committed)
    if int(plan["acquisition_count"]) > 0:
        _toast("用地買収 %d棟・幹線開通 -¥%d" % [plan["acquisition_count"], plan["total_cost"]])
    elif not first_road:
        _toast("幹線開通 -¥%d" % plan["total_cost"])
    # Save final progression and currency, never an intermediate transaction.
    _v07_save_city()
    _v10_sync_scene()
    queue_redraw()

func _v40_can_route_arterial_through(cell: int) -> bool:
    return cell >= Cell.EMPTY and cell <= Cell.INDUSTRIAL

func _v40_is_development(cell: int) -> bool:
    return cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]

func _v40_acquisition_cost(cell: int) -> int:
    return int({Cell.RESIDENTIAL: 20, Cell.COMMERCIAL: 32, Cell.INDUSTRIAL: 28}.get(cell, 0))

func _v10_sync_preview() -> void:
    if not is_instance_valid(v10_preview_root):
        return
    _v10_clear_children(v10_preview_root)
    if not dragging or current_tool != Tool.ROAD:
        return
    var plan: Dictionary = _v40_preview_metrics()
    var affordable: bool = bool(plan["valid"]) and cash >= int(plan["total_cost"])
    for value: Variant in drag_path:
        var p: Vector2i = value
        if not _in_bounds(p) or p.x >= unlocked_cols:
            continue
        var key: String = "preview_ok" if affordable else "preview_bad"
        _v10_add_box(v10_preview_root, _v10_world_position(p, 0.15),
            Vector3(0.84, 0.05, 0.84), v10_materials[key] as Material, false)

func _v10_draw_preview_cost() -> void:
    if not dragging or current_tool != Tool.ROAD:
        return
    var plan: Dictionary = _v40_preview_metrics()
    if int(plan["build_count"]) == 0:
        return
    var text: String = "%dマス・合計 ¥%d" % [plan["build_count"], plan["total_cost"]]
    if int(plan["acquisition_count"]) > 0:
        text = "買収 %d棟・合計 ¥%d" % [plan["acquisition_count"], plan["total_cost"]]
    if cash < int(plan["total_cost"]):
        text += "・資金不足"
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var w: float = minf(300.0, board_rect.size.x - 24.0)
    var pill: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.end.y - 46.0, w, 34.0)
    draw_rect(pill, Color(0.05, 0.13, 0.09, 0.94))
    draw_string(font, pill.position + Vector2(8.0, 23.0), text,
        HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 16.0, 11, Color("#F3FFF7"))

func _v11_banner_text(source: String) -> String:
    # Pass Japanese action text through the existing localized banner.
    if source.begins_with("用地買収") or source.begins_with("幹線開通"):
        return source
    return super._v11_banner_text(source)
