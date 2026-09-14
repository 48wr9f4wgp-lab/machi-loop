extends "res://main_v19_progression.gd"

# v0.19 release guard — normalize migrated progression/service state and keep
# presentation state coherent with the six-tier simulation rules.

func _process(delta: float) -> void:
    var city_time_before: float = v04_time
    super._process(delta)
    if paused:
        # Pause represents the city clock. Freeze the animation clock used by
        # vehicles/building growth so resume does not jump ahead visually.
        v04_time = city_time_before
        if is_instance_valid(v10_vehicle_root):
            _v10_update_vehicles()

func _v10_scene_hash() -> int:
    # Production asset selection is tier-aware. Tiers 4 -> 5 -> 6 can change
    # while unlocked_cols/grid stay unchanged, so city_level must participate in
    # the signature or existing buildings can remain on an older asset tier.
    var parent_hash: int = super._v10_scene_hash()
    return (str(parent_hash) + "|tier:" + str(city_level)).hash()

func _v08_apply_payload(data: Dictionary, legacy: bool) -> bool:
    # Checksum protects byte integrity, but a previously buggy build or manually
    # rewritten envelope can still contain semantically impossible cell values.
    # Reject those states so the existing loader can fall back to the backup.
    var grid_variant: Variant = data.get("grid", [])
    if not grid_variant is Array:
        return false
    var saved_grid: Array = grid_variant as Array
    if saved_grid.size() != GRID_H:
        return false
    for y: int in range(GRID_H):
        var row_variant: Variant = saved_grid[y]
        if not row_variant is Array:
            return false
        var row: Array = row_variant as Array
        if row.size() != GRID_W:
            return false
        for x: int in range(GRID_W):
            var cell_value: int = int(row[x])
            if cell_value < Cell.EMPTY or cell_value > Cell.INDUSTRIAL:
                return false

    if not super._v08_apply_payload(data, legacy):
        return false

    # Stale widen flags are harmless but should not survive migration/recovery.
    # Keep only true flags pointing at an in-bounds arterial cell.
    var normalized_widened: Dictionary = {}
    for key_variant: Variant in widened.keys():
        var key: String = str(key_variant)
        if not bool(widened[key_variant]):
            continue
        var parts: PackedStringArray = key.split(":")
        if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
            continue
        var p: Vector2i = Vector2i(parts[0].to_int(), parts[1].to_int())
        if _in_bounds(p) and int(grid[p.y][p.x]) == Cell.ARTERIAL:
            normalized_widened[key] = true
    widened = normalized_widened
    return true

func _v19_load_from_path(path: String) -> bool:
    var loaded: bool = super._v19_load_from_path(path)
    if not loaded:
        return false

    var inferred_level: int = ProgressionModel.tier_for_population(population)
    city_level = maxi(city_level, inferred_level)
    unlocked_cols = maxi(unlocked_cols, ProgressionModel.unlocked_cols(city_level))
    _v19_enforce_service_slots()
    _recalculate_city()
    return true

func _v19_enforce_service_slots() -> void:
    var limit: int = ProgressionModel.service_slots(city_level)
    var active: Array[int] = []
    if v18_mobility:
        active.append(V18Service.MOBILITY)
    if v18_safety:
        active.append(V18Service.SAFETY)
    if v18_education:
        active.append(V18Service.EDUCATION)
    if v18_green:
        active.append(V18Service.GREEN)

    if active.size() <= limit:
        return

    # Deterministic migration priority: mobility -> safety -> education -> green.
    v18_mobility = false
    v18_safety = false
    v18_education = false
    v18_green = false
    for i: int in range(mini(limit, active.size())):
        match int(active[i]):
            V18Service.MOBILITY:
                v18_mobility = true
            V18Service.SAFETY:
                v18_safety = true
            V18Service.EDUCATION:
                v18_education = true
            V18Service.GREEN:
                v18_green = true
