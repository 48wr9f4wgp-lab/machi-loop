extends SceneTree

const FtueModel = preload("res://domain/ftue_model.gd")

func _init() -> void:
    _require(FtueModel.infer_stage(0, 0, 0, 1) == FtueModel.DRAW_ROAD, "fresh city must start with road drawing")
    _require(FtueModel.infer_stage(5, 0, 0, 1) == FtueModel.DRAW_ROAD, "short road must keep the first instruction")
    _require(FtueModel.infer_stage(6, 0, 0, 1) == FtueModel.WATCH_GROWTH, "six arterial cells must advance to growth observation")
    _require(FtueModel.infer_stage(6, 13, 0, 1) == FtueModel.BUILD_TO_POLICY, "first residents must advance the FTUE")
    _require(FtueModel.infer_stage(6, 26, 0, 1) == FtueModel.CHOOSE_POLICY, "population 26 must unlock the first management decision")
    _require(FtueModel.infer_stage(6, 26, 1, 1) == FtueModel.COMPLETE, "choosing a policy must complete FTUE")
    _require(FtueModel.infer_stage(12, 120, 0, 2) == FtueModel.COMPLETE, "existing progressed saves must never replay FTUE")
    _require(FtueModel.normalize(FtueModel.DRAW_ROAD, 6, 26, 0, 1) == FtueModel.CHOOSE_POLICY, "restored FTUE must catch up to city state")
    _require(FtueModel.normalize(FtueModel.COMPLETE, 0, 0, 0, 1) == FtueModel.COMPLETE, "FTUE state must never regress")

    print("FTUE model fixture passed")
    quit(0)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error(message)
    quit(1)
