extends "res://main_v22_feedback.gd"

# Canonical road-management guard: ordinary R/C/I development is simulation-owned.
func _bulldoze(p: Vector2i) -> void:
    if not _in_bounds(p):
        return
    var original: int = int(grid[p.y][p.x])
    if original in [Cell.RESIDENTIAL, Cell.COMMERCIAL, Cell.INDUSTRIAL]:
        _toast("SELECT A MAIN ROAD")
        return
    super._bulldoze(p)
