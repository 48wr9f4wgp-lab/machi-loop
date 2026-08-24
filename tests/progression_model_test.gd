extends SceneTree

const ProgressionModel = preload("res://domain/progression_model.gd")

func _init() -> void:
    _require(ProgressionModel.tier_for_population(0) == 1, "fresh city must start at tier 1")
    _require(ProgressionModel.tier_for_population(90) == 2, "90 population must unlock tier 2")
    _require(ProgressionModel.tier_for_population(200) == 3, "200 population must unlock tier 3")
    _require(ProgressionModel.tier_for_population(360) == 4, "360 population must unlock tier 4")
    _require(ProgressionModel.tier_for_population(650) == 5, "650 population must unlock tier 5")
    _require(ProgressionModel.tier_for_population(1000) == 6, "1000 population must unlock tier 6")

    _require(ProgressionModel.service_slots(1) == 0, "tier 1 should not overload FTUE with city services")
    _require(ProgressionModel.service_slots(2) == 1, "tier 2 should add the first service choice")
    _require(ProgressionModel.service_slots(3) == 2, "tier 3 should expand service strategy")
    _require(ProgressionModel.service_slots(4) == 3, "tier 4 should expand service strategy")
    _require(ProgressionModel.service_slots(5) == 4, "tier 5 should unlock the full service set")
    _require(ProgressionModel.metropolitan_service_cost_multiplier(6) < 1.0, "tier 6 should add a metropolitan efficiency reward")

    _require(ProgressionModel.unlocked_cols(4) == 16, "tier 4 should open all current land")
    _require(ProgressionModel.next_target(5) == 1000, "tier 5 must retain a visible long-term target")

    print("Progression model fixture passed")
    quit(0)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error(message)
    quit(1)
