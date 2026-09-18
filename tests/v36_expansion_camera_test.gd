extends SceneTree

const GameClass = preload("res://main_v36_expansion_camera.gd")

func _init() -> void:
    var game = GameClass.new()

    _expect(is_equal_approx(game.V36_EXPANSION_CAMERA_SECONDS, 0.72), "camera reveal duration changed")
    _expect(is_equal_approx(game._v36_expansion_progress(0.0), 0.0), "expansion must start at zero")
    _expect(is_equal_approx(game._v36_expansion_progress(game.V36_EXPANSION_CAMERA_SECONDS), 1.0), "expansion must finish at one")

    var half: float = game._v36_expansion_progress(game.V36_EXPANSION_CAMERA_SECONDS * 0.5)
    _expect(absf(half - 0.5) < 0.0001, "smoothstep midpoint drifted")

    var quarter: float = game._v36_expansion_progress(game.V36_EXPANSION_CAMERA_SECONDS * 0.25)
    var three_quarter: float = game._v36_expansion_progress(game.V36_EXPANSION_CAMERA_SECONDS * 0.75)
    _expect(quarter < 0.25, "camera reveal no longer eases in")
    _expect(three_quarter > 0.75, "camera reveal no longer eases out")
    _expect(game._v36_expansion_progress(-1.0) == 0.0, "negative elapsed escaped clamp")
    _expect(game._v36_expansion_progress(99.0) == 1.0, "large elapsed escaped clamp")

    # Regression guard: v0.36 must intercept the v0.24 immediate runtime camera
    # apply instead of reintroducing a direct expansion snap.
    var source: String = FileAccess.get_file_as_string("res://main_v36_expansion_camera.gd")
    var apply_start: int = source.find("func _v24_apply_camera() -> void:")
    var begin_start: int = source.find("func _v36_begin_expansion_camera", apply_start)
    _expect(apply_start >= 0 and begin_start > apply_start, "camera interception block missing")
    var apply_block: String = source.substr(apply_start, begin_start - apply_start)
    _expect(apply_block.contains("_v36_should_defer_camera_apply()"), "runtime expansion interception removed")
    _expect(apply_block.contains("return"), "deferred camera path no longer blocks immediate parent apply")

    print("V36_EXPANSION_CAMERA_OK")
    game.free()
    quit(0)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V36_EXPANSION_CAMERA_FAILED: " + message)
    quit(1)
