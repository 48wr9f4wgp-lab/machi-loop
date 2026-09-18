extends SceneTree

const GameClass = preload("res://main_v31_device_stability.gd")

func _init() -> void:
    var game = GameClass.new()
    game._init_grid()

    # Congestion-only changes must not invalidate static geometry anymore.
    var base_hash: int = game._v10_scene_hash()
    game.congestion = 97.0
    var congestion_hash: int = game._v10_scene_hash()
    _expect(base_hash == congestion_hash, "congestion-only state rebuilt static geometry")

    # Real structural changes must still invalidate the renderer.
    game.grid[4][3] = game.Cell.ARTERIAL
    var road_hash: int = game._v10_scene_hash()
    _expect(road_hash != base_hash, "road topology change did not invalidate static geometry")

    game.grid[5][3] = game.Cell.RESIDENTIAL
    var building_hash: int = game._v10_scene_hash()
    _expect(building_hash != road_hash, "building growth did not invalidate static geometry")

    # Progression-dependent silhouettes must remain in the visual signature.
    game.city_level = 2
    var level_hash: int = game._v10_scene_hash()
    _expect(level_hash != building_hash, "city level change did not invalidate static geometry")

    # Camera settling helper must resolve long-tail fractional drift to exact rest.
    game.board_rect = Rect2(Vector2.ZERO, Vector2(430.0, 762.0))
    game.v10_camera = Camera3D.new()
    game.add_child(game.v10_camera)
    game.v28_sequence_active = false
    var target: Vector3 = game._v28_base_camera_target()
    var target_size: float = game._v28_base_camera_size()
    game.v28_camera_target = target + Vector3(0.01, 0.0, -0.01)
    game.v28_camera_size = target_size + 0.01
    _expect(game._v31_snap_camera_if_settled(), "near-rest camera did not snap")
    _expect(game.v28_camera_target.is_equal_approx(target), "camera target retained fractional drift")
    _expect(is_equal_approx(game.v28_camera_size, target_size), "camera size retained fractional drift")

    print("V31_DEVICE_STABILITY_OK")
    game.free()
    quit(0)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V31_DEVICE_STABILITY_FAILED: " + message)
    quit(1)
