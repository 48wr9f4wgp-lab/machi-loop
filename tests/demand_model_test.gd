extends SceneTree

const DemandModel = preload("res://domain/demand_model.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var bootstrap: Dictionary = DemandModel.calculate(0, 0, 100, 0.0, 0, 0, 0)
    _assert_range(bootstrap)
    if int(bootstrap["residential"]) < 80:
        _fail("bootstrap housing demand must be high: %s" % str(bootstrap))
        return

    var jobs_surplus: Dictionary = DemandModel.calculate(130, 150, 92, 25.0, 10, 2, 3)
    var jobs_shortage: Dictionary = DemandModel.calculate(130, 45, 92, 25.0, 10, 2, 3)
    if int(jobs_surplus["residential"]) <= int(jobs_shortage["residential"]):
        _fail("job surplus should increase residential demand: surplus=%s shortage=%s" % [str(jobs_surplus), str(jobs_shortage)])
        return
    if int(jobs_shortage["industrial"]) <= int(jobs_surplus["industrial"]):
        _fail("job shortage should increase industrial demand: shortage=%s surplus=%s" % [str(jobs_shortage), str(jobs_surplus)])
        return

    var commerce_short: Dictionary = DemandModel.calculate(260, 190, 94, 28.0, 20, 1, 5)
    var commerce_over: Dictionary = DemandModel.calculate(260, 190, 94, 28.0, 20, 8, 5)
    if int(commerce_short["commercial"]) <= int(commerce_over["commercial"]):
        _fail("commercial undersupply should increase commercial demand: short=%s over=%s" % [str(commerce_short), str(commerce_over)])
        return

    var clear_roads: Dictionary = DemandModel.calculate(220, 160, 96, 22.0, 16, 4, 4)
    var gridlock: Dictionary = DemandModel.calculate(220, 160, 96, 110.0, 16, 4, 4)
    if int(gridlock["residential"]) >= int(clear_roads["residential"]):
        _fail("severe congestion should reduce residential demand: clear=%s gridlock=%s" % [str(clear_roads), str(gridlock)])
        return
    if int(gridlock["commercial"]) >= int(clear_roads["commercial"]):
        _fail("severe congestion should reduce commercial demand: clear=%s gridlock=%s" % [str(clear_roads), str(gridlock)])
        return

    print("DEMAND_MODEL_OK bootstrap=%s jobs_shortage=%s gridlock=%s" % [str(bootstrap), str(jobs_shortage), str(gridlock)])
    quit(0)

func _assert_range(values: Dictionary) -> void:
    for key: String in ["residential", "commercial", "industrial"]:
        var value: int = int(values.get(key, -1))
        if value < 0 or value > 100:
            _fail("demand out of range %s=%d" % [key, value])
            return

func _fail(message: String) -> void:
    push_error("DEMAND_MODEL_FAILED: " + message)
    quit(1)
