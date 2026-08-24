extends SceneTree

const EconomyModel = preload("res://domain/economy_model.gd")

func _init() -> void:
    var healthy: Dictionary = EconomyModel.calculate(32, 16, 24, 2, 3)
    _require(int(healthy["net_balance"]) > 0, "normal developed city should remain profitable")

    var overbuilt: Dictionary = EconomyModel.calculate(12, 70, 30, 12, 3)
    _require(int(overbuilt["net_balance"]) < 0, "severely overbuilt road network should be able to run a deficit")
    _require(str(overbuilt["status"]) == "deficit", "negative operating balance should be exposed as deficit")

    var trimmed: Dictionary = EconomyModel.calculate(12, 24, 12, 2, 3)
    _require(int(trimmed["operating_cost"]) < int(overbuilt["operating_cost"]), "removing excess road capacity must reduce recurring costs")
    _require(int(trimmed["net_balance"]) > int(overbuilt["net_balance"]), "network trimming must be a financial recovery path")

    var no_widen: Dictionary = EconomyModel.calculate(22, 22, 18, 0, 2)
    var many_widened: Dictionary = EconomyModel.calculate(22, 22, 18, 10, 2)
    _require(int(many_widened["operating_cost"]) > int(no_widen["operating_cost"]), "widening should have a recurring tradeoff")

    print("Economy model fixture passed")
    quit(0)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error(message)
    quit(1)
