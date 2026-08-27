extends "res://main_v19_progression.gd"

# v0.19 release guard — normalize migrated progression/service state.
# This keeps pre-v0.19 saves valid while enforcing the six-tier rules immediately after load.

func _v10_scene_hash() -> int:
    # Production asset selection is tier-aware. Once progression expanded beyond
    # the old district unlocks, city_level can change while unlocked_cols and the
    # grid remain unchanged (notably tiers 4 -> 5 -> 6). Include tier explicitly
    # so existing buildings rebuild into the newly unlocked skyline kit immediately.
    var parent_hash: int = super._v10_scene_hash()
    return (str(parent_hash) + "|tier:" + str(city_level)).hash()

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
