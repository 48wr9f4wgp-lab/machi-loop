extends "res://main_v37_recovery_device_test.gd"

# AXIVA v0.40 — Recoverable Roads.
# The simulation already supported cell-level bulldozing, but the 3D mobile
# interaction exposed removal as tap-only. That made long player-authored
# arterials practically irreversible on iPhone. Removal now supports the same
# axis-locked drag gesture as road construction.
#
# Ordinary R/C/I development remains simulation-owned via v0.22 road guard.
# No save schema change: removed road cells are represented by the existing grid.

var v40_remove_dragging: bool = false
var v40_remove_origin: Vector2i = Vector2i(-1, -1)
var v40_remove_axis: int = V35Axis.NONE
var v40_remove_origin_screen: Vector2 = Vector2.ZERO
var v40_remove_path: Array = []

func _pointer_down(pos: Vector2) -> void:
    # Preserve toolbar/reset/policy handling before claiming a board gesture.
    for id: Variant in tool_rects.keys():
        var rect: Rect2 = tool_rects[id] as Rect2
        if rect.has_point(pos):
            super._pointer_down(pos)
            return

    if current_tool != Tool.BULLDOZE:
        super._pointer_down(pos)
        return

    var cell: Vector2i = _screen_to_cell(pos)
    if not _v40_is_removable_road(cell):
        # Keep inherited feedback for buildings/empty cells.
        super._pointer_down(pos)
        return

    v40_remove_dragging = true
    v40_remove_origin = cell
    v40_remove_origin_screen = pos
    v40_remove_axis = V35Axis.NONE
    v40_remove_path = [cell]
    queue_redraw()

func _pointer_move(pos: Vector2) -> void:
    if not v40_remove_dragging:
        super._pointer_move(pos)
        return

    var cell: Vector2i = _screen_to_cell(pos)
    if not _in_bounds(cell) or cell.x >= unlocked_cols:
        return
    if v40_remove_axis == V35Axis.NONE:
        v40_remove_axis = _v35_choose_axis(v40_remove_origin, cell, v40_remove_origin_screen, pos)
        if v40_remove_axis == V35Axis.NONE:
            return

    var snapped: Vector2i = _v35_snap_to_axis(v40_remove_origin, cell, v40_remove_axis)
    snapped.x = clampi(snapped.x, 0, unlocked_cols - 1)
    snapped.y = clampi(snapped.y, 0, GRID_H - 1)
    v40_remove_path = _v35_straight_path(v40_remove_origin, snapped)
    queue_redraw()

func _pointer_up(pos: Vector2) -> void:
    if not v40_remove_dragging:
        super._pointer_up(pos)
        return

    _v40_commit_remove_path()
    v40_remove_dragging = false
    v40_remove_origin = Vector2i(-1, -1)
    v40_remove_axis = V35Axis.NONE
    v40_remove_path.clear()
    _v10_sync_preview()
    _v10_sync_scene()
    queue_redraw()

func _v40_is_removable_road(p: Vector2i) -> bool:
    if not _in_bounds(p) or p.x >= unlocked_cols:
        return false
    return int(grid[p.y][p.x]) in [Cell.ARTERIAL, Cell.LOCAL]

func _v40_commit_remove_path() -> void:
    var removed: int = 0
    for item: Variant in v40_remove_path:
        var p: Vector2i = item as Vector2i
        if not _v40_is_removable_road(p):
            continue
        if int(grid[p.y][p.x]) == Cell.ARTERIAL:
            widened.erase(_key(p))
        grid[p.y][p.x] = Cell.EMPTY
        removed += 1

    if removed <= 0:
        return

    var cost: int = removed * REMOVE_COST
    cash = maxi(0, cash - cost)
    _toast("撤去  -¥%d" % cost)
    _recalculate_city()
    _v07_save_city()

func _v10_draw_projected_effects() -> void:
    super._v10_draw_projected_effects()
    _v40_draw_remove_preview()

func _v40_draw_remove_preview() -> void:
    if not v40_remove_dragging or v40_remove_path.is_empty():
        return
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var removable: int = 0
    for item: Variant in v40_remove_path:
        var p: Vector2i = item as Vector2i
        if not _v40_is_removable_road(p):
            continue
        removable += 1
        var screen: Vector2 = _v27_project_cell(p, 0.20)
        if screen.x < -100.0:
            continue
        draw_circle(screen, 8.0, Color(0.88, 0.30, 0.22, 0.52), false, 2.0)

    if removable <= 0:
        return
    var pill: Rect2 = Rect2(board_rect.get_center().x - 70.0, board_rect.end.y - 44.0, 140.0, 28.0)
    draw_rect(pill, Color(0.12, 0.08, 0.07, 0.92))
    draw_string(font, pill.position + Vector2(6.0, 19.0), "撤去 %d  -¥%d" % [removable, removable * REMOVE_COST], HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 12.0, 9, Color.WHITE)
