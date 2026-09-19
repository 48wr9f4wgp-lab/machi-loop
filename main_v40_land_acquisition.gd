extends "res://main_v37_recovery_device_test.gd"

# AXIVA v0.40 — arterial land acquisition / player recoverability.
#
# Change Packet
# Goal:
# - let the player route a NEW strategic arterial through simulation-owned R/C/I;
# - interpret displaced development as land acquisition, not direct demolition;
# - preserve autonomous city authority while preventing mature development from
#   permanently locking the board.
# Non-goals:
# - no manual building bulldoze;
# - no unlimited undo;
# - no save-schema change;
# - no production/release work.
#
# Acceptance:
# - road preview treats R/C/I as purchasable and shows acquisition count/cost;
# - commit atomically replaces purchased R/C/I with arterial cells;
# - insufficient cash leaves the city untouched;
# - existing arterial cells remain reusable at zero construction/acquisition cost;
# - ordinary building REMOVE remains blocked by the inherited road guard.

const V40_ACQUISITION_RESIDENTIAL: int = 20
const V40_ACQUISITION_COMMERCIAL: int = 32
const V40_ACQUISITION_INDUSTRIAL: int = 28

var v40_last_acquired_buildings: int = 0
var v40_last_acquisition_cost: int = 0

func _commit_arterial() -> void:
    var build_cells: Array[Vector2i] = []
    var acquired_cells: Array[Vector2i] = []
    var construction_cost: int = 0
    var acquisition_cost: int = 0

    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if not _in_bounds(p) or p.x >= unlocked_cols:
            continue
        var cell: int = int(grid[p.y][p.x])
        if cell == Cell.ARTERIAL:
            continue
        if not _v40_can_route_arterial_through(cell):
            continue
        build_cells.append(p)
        construction_cost += ROAD_COST
        if _v40_is_development(cell):
            acquired_cells.append(p)
            acquisition_cost += _v40_acquisition_cost(cell)

    if build_cells.is_empty():
        return

    var total_cost: int = construction_cost + acquisition_cost
    if cash < total_cost:
        _toast("NOT ENOUGH CASH")
        return

    cash -= total_cost
    for p: Vector2i in build_cells:
        widened.erase(_key(p))
        grid[p.y][p.x] = Cell.ARTERIAL

    v40_last_acquired_buildings = acquired_cells.size()
    v40_last_acquisition_cost = acquisition_cost

    if acquired_cells.is_empty():
        _toast("MAIN ROAD  -Y%d" % total_cost)
    else:
        _toast("LAND ACQUIRED %d  -Y%d" % [acquired_cells.size(), total_cost])

    _recalculate_city()
    _v07_save_city()
    queue_redraw()

func _v40_can_route_arterial_through(cell: int) -> bool:
    return cell in [
        Cell.EMPTY,
        Cell.ARTERIAL,
        Cell.RESIDENTIAL,
        Cell.COMMERCIAL,
        Cell.INDUSTRIAL
    ]

func _v40_is_development(cell: int) -> bool:
    return cell in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]

func _v40_acquisition_cost(cell: int) -> int:
    match cell:
        Cell.RESIDENTIAL:
            return V40_ACQUISITION_RESIDENTIAL
        Cell.COMMERCIAL:
            return V40_ACQUISITION_COMMERCIAL
        Cell.INDUSTRIAL:
            return V40_ACQUISITION_INDUSTRIAL
        _:
            return 0

func _v40_preview_metrics() -> Dictionary:
    var build_count: int = 0
    var acquisition_count: int = 0
    var acquisition_cost: int = 0

    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if not _in_bounds(p) or p.x >= unlocked_cols:
            continue
        var cell: int = int(grid[p.y][p.x])
        if cell == Cell.ARTERIAL or not _v40_can_route_arterial_through(cell):
            continue
        build_count += 1
        if _v40_is_development(cell):
            acquisition_count += 1
            acquisition_cost += _v40_acquisition_cost(cell)

    return {
        "build_count": build_count,
        "acquisition_count": acquisition_count,
        "construction_cost": build_count * ROAD_COST,
        "acquisition_cost": acquisition_cost,
        "total_cost": build_count * ROAD_COST + acquisition_cost
    }

func _v10_sync_preview() -> void:
    if not is_instance_valid(v10_preview_root):
        return
    _v10_clear_children(v10_preview_root)
    if not dragging or current_tool != Tool.ROAD:
        return

    for item: Variant in drag_path:
        var p: Vector2i = item as Vector2i
        if not _in_bounds(p) or p.x >= unlocked_cols:
            continue
        var cell: int = int(grid[p.y][p.x])
        var valid: bool = _v40_can_route_arterial_through(cell)
        var material: Material = v10_materials["preview_ok"] as Material if valid else v10_materials["preview_bad"] as Material
        _v10_add_box(v10_preview_root, _v10_world_position(p, 0.13), Vector3(0.84, 0.05, 0.84), material, false)

func _v10_draw_preview_cost() -> void:
    if not dragging or current_tool != Tool.ROAD:
        return
    var metrics: Dictionary = _v40_preview_metrics()
    var build_count: int = int(metrics["build_count"])
    if build_count <= 0:
        return

    var acquisition_count: int = int(metrics["acquisition_count"])
    var total_cost: int = int(metrics["total_cost"])
    var text: String = "%dマス  -¥%d" % [build_count, total_cost]
    if acquisition_count > 0:
        text = "買収 %d棟  合計 -¥%d" % [acquisition_count, total_cost]

    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var width: float = 176.0 if acquisition_count > 0 else 136.0
    var pill: Rect2 = Rect2(board_rect.get_center().x - width * 0.5, board_rect.end.y - 39.0, width, 29.0)
    draw_rect(pill, Color(0.05, 0.13, 0.09, 0.94))
    draw_rect(pill, Color("#71D0A2"), false, 1.0)
    draw_string(font, pill.position + Vector2(0.0, 20.0), text, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 10, Color("#F3FFF7"))

func _v11_banner_text(source: String) -> String:
    if source.begins_with("LAND ACQUIRED "):
        var parts: PackedStringArray = source.split(" ")
        if parts.size() >= 3:
            return "用地買収 %s棟・幹線道路を整備" % parts[2]
        return "用地を買収し、幹線道路を整備"
    return super._v11_banner_text(source)
