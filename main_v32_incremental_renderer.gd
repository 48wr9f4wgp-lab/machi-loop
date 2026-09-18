extends "res://main_v31_device_stability.gd"

# AXIVA v0.32 — incremental renderer.
# Physical iPhone recordings showed a repeatable full-screen jump at the 0.85 s
# simulation cadence. v0.31 removed congestion-only invalidation and hid rebuild
# clears, but ordinary autonomous growth still rebuilt the entire production 3D
# city. v0.32 keeps full rebuilds for rare structural edits and updates normal
# local-road / building growth cell-by-cell.
#
# Simulation, traffic, economy, save data and player authority are unchanged.

var v32_snapshot_ready: bool = false
var v32_grid_snapshot: Array = []
var v32_widened_snapshot: Dictionary = {}
var v32_unlocked_snapshot: int = -1
var v32_city_level_snapshot: int = -1
var v32_policy_snapshot: int = -1

var v32_full_sync_count: int = 0
var v32_incremental_sync_count: int = 0
var v32_incremental_cell_count: int = 0

func _v10_sync_scene(force: bool = false) -> void:
    if force or not v32_snapshot_ready:
        _v32_full_sync()
        return

    var changes: Array = _v32_collect_cell_changes()
    if _v32_scalar_state_requires_full_rebuild() or not _v32_changes_are_incremental(changes):
        _v32_full_sync()
        return

    # A tick may change only traffic/economy state. Vehicle reconciliation is
    # cheap and keeps traffic presentation current without touching static city.
    if changes.is_empty():
        _v10_rebuild_vehicles()
        v10_scene_signature = _v10_scene_hash()
        queue_redraw()
        return

    for item: Variant in changes:
        var change: Dictionary = item as Dictionary
        var p: Vector2i = change["p"] as Vector2i
        var after: int = int(change["after"])
        _v32_remove_known_empty_cell_decor(p)
        if after == Cell.LOCAL:
            _v10_add_road(p, Cell.LOCAL)
        else:
            _v10_add_building(p, after)
        v32_incremental_cell_count += 1

    # v0.31 reconciles vehicle nodes by delta rather than recreating them.
    _v10_rebuild_vehicles()
    _v10_sync_preview()
    v10_scene_signature = _v10_scene_hash()
    _v32_capture_snapshot()
    v32_incremental_sync_count += 1
    queue_redraw()

func _v32_full_sync() -> void:
    super._v10_sync_scene(true)
    _v32_capture_snapshot()
    v32_snapshot_ready = true
    v32_full_sync_count += 1

func _v32_capture_snapshot() -> void:
    v32_grid_snapshot.clear()
    for row_value: Variant in grid:
        var row: Array = row_value as Array
        v32_grid_snapshot.append(row.duplicate())
    v32_widened_snapshot = widened.duplicate(true)
    v32_unlocked_snapshot = unlocked_cols
    v32_city_level_snapshot = city_level
    v32_policy_snapshot = v09_policy

func _v32_collect_cell_changes() -> Array:
    var changes: Array = []
    if v32_grid_snapshot.size() != grid.size():
        changes.append({"p": Vector2i(-1, -1), "before": -999, "after": -998})
        return changes

    for y: int in range(grid.size()):
        var current_row: Array = grid[y] as Array
        var previous_row: Array = v32_grid_snapshot[y] as Array
        if previous_row.size() != current_row.size():
            changes.append({"p": Vector2i(-1, -1), "before": -999, "after": -998})
            return changes
        for x: int in range(current_row.size()):
            var before: int = int(previous_row[x])
            var after: int = int(current_row[x])
            if before != after:
                changes.append({
                    "p": Vector2i(x, y),
                    "before": before,
                    "after": after
                })
    return changes

func _v32_changes_are_incremental(changes: Array) -> bool:
    for item: Variant in changes:
        var change: Dictionary = item as Dictionary
        if not _v32_cell_transition_is_incremental(int(change["before"]), int(change["after"])):
            return false
    return true

func _v32_cell_transition_is_incremental(before: int, after: int) -> bool:
    if before != Cell.EMPTY:
        return false
    return after in [
        Cell.LOCAL,
        Cell.RESIDENTIAL,
        Cell.COMMERCIAL,
        Cell.INDUSTRIAL
    ]

func _v32_scalar_state_requires_full_rebuild() -> bool:
    if v32_unlocked_snapshot != unlocked_cols:
        return true
    if v32_city_level_snapshot != city_level:
        return true
    if v32_policy_snapshot != v09_policy:
        return true
    return JSON.stringify(v32_widened_snapshot) != JSON.stringify(widened)

func _v32_remove_known_empty_cell_decor(p: Vector2i) -> void:
    if not is_instance_valid(v10_static_root):
        return

    # v0.25 open-land vegetation has deterministic cell names. Remove only that
    # known decoration when the simulation consumes the parcel. Legacy unnamed
    # decorations are left untouched rather than risking deletion of road/world
    # geometry that belongs to another cell.
    var target_name: String = "V25Vegetation_%d_%d" % [p.x, p.y]
    for child: Node in v10_static_root.get_children():
        if child.name == target_name:
            child.queue_free()
            break
