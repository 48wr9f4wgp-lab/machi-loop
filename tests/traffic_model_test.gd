extends SceneTree

const TrafficModel = preload("res://domain/traffic_model.gd")

func _init() -> void:
    var connected: Dictionary = TrafficModel.calculate(260, 180, 620.0, 30, 14, 2, 5, 3, 1, 2)
    var fragmented: Dictionary = TrafficModel.calculate(260, 180, 620.0, 30, 14, 2, 2, 10, 3, 0)
    _require(float(connected["congestion"]) < float(fragmented["congestion"]), "connected network should outperform fragmented network")

    var line_network: Dictionary = TrafficModel.calculate(260, 180, 500.0, 24, 10, 0, 1, 8, 1, 0)
    var loop_network: Dictionary = TrafficModel.calculate(260, 180, 500.0, 24, 10, 0, 4, 2, 1, 2)
    _require(float(loop_network["congestion"]) < float(line_network["congestion"]), "redundant/looped network should reduce traffic pressure")

    var narrow: Dictionary = TrafficModel.calculate(320, 220, 430.0, 26, 12, 0, 3, 4, 1, 1)
    var widened: Dictionary = TrafficModel.calculate(320, 220, 620.0, 26, 12, 5, 3, 4, 1, 1)
    _require(float(widened["congestion"]) < float(narrow["congestion"]), "widening must be a valid recovery action")
    _require(float(narrow["income_multiplier"]) <= float(widened["income_multiplier"]), "traffic recovery should protect operating income")

    var disconnected: Dictionary = TrafficModel.calculate(180, 120, 500.0, 18, 8, 0, 1, 6, 2, 0)
    _require(str(disconnected["cause"]) == "disconnected", "fragmented roads should expose a clear cause")

    print("Traffic model fixture passed")
    quit(0)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error(message)
    quit(1)
