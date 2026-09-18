extends SceneTree

const GameClass = preload("res://main_v36_1_expansion_reveal.gd")

func _init() -> void:
    var game = GameClass.new()

    var g12: Dictionary = game._v361_land_geometry(12.0)
    _expect(is_equal_approx(float(g12["open_width"]), 12.0), "12-col open width wrong")
    _expect(is_equal_approx(float(g12["locked_width"]), 4.0), "12-col locked width wrong")
    _expect(is_equal_approx(float(g12["boundary_x"]), 4.0), "12-col boundary wrong")

    var g13: Dictionary = game._v361_land_geometry(13.0)
    _expect(is_equal_approx(float(g13["open_width"]), 13.0), "mid-reveal open width wrong")
    _expect(is_equal_approx(float(g13["locked_width"]), 3.0), "mid-reveal locked width wrong")
    _expect(is_equal_approx(float(g13["boundary_x"]), 5.0), "mid-reveal boundary wrong")

    var g14: Dictionary = game._v361_land_geometry(14.0)
    _expect(is_equal_approx(float(g14["open_width"]), 14.0), "14-col open width wrong")
    _expect(is_equal_approx(float(g14["locked_width"]), 2.0), "14-col locked width wrong")

    var g16: Dictionary = game._v361_land_geometry(16.0)
    _expect(is_equal_approx(float(g16["open_width"]), 16.0), "16-col open width wrong")
    _expect(is_equal_approx(float(g16["locked_width"]), 0.0), "full unlock retained locked land")
    _expect(is_equal_approx(float(g16["boundary_x"]), 8.0), "full-unlock boundary target wrong")

    # Regression guard: runtime unlocks must not rebuild the static city while
    # the reveal is active. The final forced sync happens only after camera end.
    var source: String = FileAccess.get_file_as_string("res://main_v36_1_expansion_reveal.gd")
    var sync_start: int = source.find("func _v10_sync_scene(force: bool = false) -> void:")
    var process_start: int = source.find("func _process", sync_start)
    _expect(sync_start >= 0 and process_start > sync_start, "sync interception missing")
    var sync_block: String = source.substr(sync_start, process_start - sync_start)
    _expect(sync_block.contains("v361_land_reveal_active and not force"), "reveal no longer defers runtime rebuild")
    _expect(sync_block.contains("return"), "deferred runtime sync no longer returns early")

    print("V361_EXPANSION_REVEAL_OK")
    game.free()
    quit(0)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V361_EXPANSION_REVEAL_FAILED: " + message)
    quit(1)
