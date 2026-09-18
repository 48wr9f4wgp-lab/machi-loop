extends "res://main_v34_mobile_hud.gd"

# AXIVA v0.35 — mobile road-draw ergonomics + wider early build area.
# Goals:
# - make a single drag produce a clean horizontal OR vertical arterial segment;
# - widen the practical early map without changing GRID_W/H or save schema.
#
# This is intentionally title-specific and leaves the simulation model,
# persistence schema, economy and traffic authority unchanged.

const V35_MIN_OPEN_COLS: int = 12
const V35_TIER2_OPEN_COLS: int = 14
const V35_TIER3_OPEN_COLS: int = 16

enum V35Axis { NONE, HORIZONTAL, VERTICAL }

var v35_drag_origin: Vector2i = Vector2i(-1, -1)
var v35_drag_axis: int = V35Axis.NONE
var v35_drag_origin_screen: Vector2 = Vector2.ZERO

func _ready() -> void:
    # Critical ordering: widen the playable footprint BEFORE the inherited
    # renderer creates its first visible static city. The original v0.35 did a
    # second full rebuild after renderer setup, which produced an all-black
    # replacement city on physical iPhone/Web.
    _v35_prepare_width_before_renderer()
    super._ready()
    queue_redraw()

# Save restore happens in the inherited ready chain before the 3D renderer is
# constructed. Normalize legacy 8/11-column saves here so the renderer still
# receives the final width on its first build instead of requiring a hot rebuild.
func _v07_load_city() -> bool:
    var loaded: bool = super._v07_load_city()
    _v35_prepare_width_before_renderer()
    return loaded

func _v35_prepare_width_before_renderer() -> void:
    unlocked_cols = maxi(unlocked_cols, _v35_desired_unlocked_cols(population))

func _pointer_down(pos: Vector2) -> void:
    super._pointer_down(pos)

    if dragging and current_tool == Tool.ROAD and not drag_path.is_empty():
        v35_drag_origin = drag_path[0] as Vector2i
        v35_drag_origin_screen = pos
        v35_drag_axis = V35Axis.NONE

func _pointer_move(pos: Vector2) -> void:
    if not dragging or current_tool != Tool.ROAD:
        return

    var cell: Vector2i = _screen_to_cell(pos)
    if not _in_bounds(cell) or cell.x >= unlocked_cols:
        return
    if not _in_bounds(v35_drag_origin):
        return

    if v35_drag_axis == V35Axis.NONE:
        v35_drag_axis = _v35_choose_axis(v35_drag_origin, cell, v35_drag_origin_screen, pos)
        if v35_drag_axis == V35Axis.NONE:
            return

    var snapped: Vector2i = _v35_snap_to_axis(v35_drag_origin, cell, v35_drag_axis)
    snapped.x = clampi(snapped.x, 0, unlocked_cols - 1)
    snapped.y = clampi(snapped.y, 0, GRID_H - 1)

    drag_path = _v35_straight_path(v35_drag_origin, snapped)
    _v10_sync_preview()
    queue_redraw()

func _pointer_up(pos: Vector2) -> void:
    super._pointer_up(pos)
    v35_drag_origin = Vector2i(-1, -1)
    v35_drag_axis = V35Axis.NONE

func _check_unlocks() -> void:
    var before_cols: int = unlocked_cols
    super._check_unlocks()

    var desired: int = _v35_desired_unlocked_cols(population)
    if desired > unlocked_cols:
        unlocked_cols = desired

    if unlocked_cols != before_cols:
        _v07_save_city()

func _v35_desired_unlocked_cols(pop: int) -> int:
    if pop >= 200:
        return V35_TIER3_OPEN_COLS
    if pop >= 90:
        return V35_TIER2_OPEN_COLS
    return V35_MIN_OPEN_COLS

func _v35_choose_axis(
    origin: Vector2i,
    current: Vector2i,
    origin_screen: Vector2,
    current_screen: Vector2
) -> int:
    var dx_cells: int = absi(current.x - origin.x)
    var dy_cells: int = absi(current.y - origin.y)
    if dx_cells == 0 and dy_cells == 0:
        return V35Axis.NONE

    # Cell delta is authoritative. Raw touch delta only resolves a 1:1 tie,
    # which is common when the finger sits near a diagonal cell boundary.
    if dx_cells > dy_cells:
        return V35Axis.HORIZONTAL
    if dy_cells > dx_cells:
        return V35Axis.VERTICAL

    var raw: Vector2 = current_screen - origin_screen
    if absf(raw.x) >= absf(raw.y):
        return V35Axis.HORIZONTAL
    return V35Axis.VERTICAL

func _v35_snap_to_axis(origin: Vector2i, current: Vector2i, axis: int) -> Vector2i:
    if axis == V35Axis.HORIZONTAL:
        return Vector2i(current.x, origin.y)
    if axis == V35Axis.VERTICAL:
        return Vector2i(origin.x, current.y)
    return origin

func _v35_straight_path(origin: Vector2i, target: Vector2i) -> Array:
    var result: Array = []
    if origin.x != target.x and origin.y != target.y:
        return result

    for item: Variant in _grid_line(origin, target):
        var p: Vector2i = item as Vector2i
        if _in_bounds(p) and p.x < unlocked_cols:
            result.append(p)
    return result
