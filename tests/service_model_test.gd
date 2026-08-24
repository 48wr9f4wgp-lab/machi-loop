extends SceneTree

const ServiceModel = preload("res://domain/service_model.gd")

func _init() -> void:
    var none: Dictionary = ServiceModel.summarize(false, false, false, false)
    _require(int(none["operating_cost"]) == 0, "inactive services should not cost money")

    var mobility: Dictionary = ServiceModel.summarize(true, false, false, false)
    _require(float(mobility["road_capacity_multiplier"]) > 1.0, "mobility must improve road capacity")
    _require(int(mobility["operating_cost"]) > 0, "mobility must have a recurring cost")

    var safety: Dictionary = ServiceModel.summarize(false, true, false, false)
    _require(int(safety["happiness_bonus"]) > 0, "safety must improve happiness")

    var education: Dictionary = ServiceModel.summarize(false, false, true, false)
    _require(int(education["commercial_demand_bonus"]) > 0, "education must change growth pressure")
    _require(float(education["revenue_multiplier"]) > 1.0, "education must improve city value")

    var green: Dictionary = ServiceModel.summarize(false, false, false, true)
    _require(int(green["residential_demand_bonus"]) > 0, "green service must improve residential demand")
    _require(int(green["industrial_demand_bonus"]) < 0, "green service must create an industrial tradeoff")

    var all_on: Dictionary = ServiceModel.summarize(true, true, true, true)
    _require(int(all_on["operating_cost"]) >= 14, "running every service must create meaningful budget pressure")

    print("Service model fixture passed")
    quit(0)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error(message)
    quit(1)
