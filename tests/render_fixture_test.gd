extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn") as PackedScene
    if packed == null:
        _fail("main.tscn did not load")
        return

    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    if not is_instance_valid(game.v10_viewport):
        _fail("3D SubViewport was not created")
        return
    if not is_instance_valid(game.v10_camera) or not game.v10_camera.is_inside_tree():
        _fail("3D camera is not inside SceneTree")
        return
    if not game.v10_camera.current:
        _fail("3D camera is not current")
        return
    if not is_instance_valid(game.v10_static_root) or game.v10_static_root.get_child_count() == 0:
        _fail("3D city geometry was not generated")
        return

    var vp_size: Vector2 = Vector2(game.v10_viewport.size)
    var center: Vector2 = vp_size * 0.5
    var ray_origin: Vector3 = game.v10_camera.project_ray_origin(center)
    var ray_dir: Vector3 = game.v10_camera.project_ray_normal(center)
    if ray_dir.y >= -0.15:
        _fail("camera center ray is not aimed at the ground")
        return

    var t: float = -ray_origin.y / ray_dir.y
    if t <= 0.0:
        _fail("camera center ray does not intersect ground in front")
        return
    var hit: Vector3 = ray_origin + ray_dir * t

    # v0.14 intentionally frames the currently unlocked/buildable district rather than
    # the full 16-column map center. Assert that the center ray lands inside that active area.
    var min_x: float = -float(game.GRID_W) * 0.5 - 0.5
    var max_x: float = -float(game.GRID_W) * 0.5 + float(game.unlocked_cols) + 0.5
    var min_z: float = -float(game.GRID_H) * 0.5 - 0.5
    var max_z: float = float(game.GRID_H) * 0.5 + 0.5
    if hit.x < min_x or hit.x > max_x or hit.z < min_z or hit.z > max_z:
        _fail("camera center ray misses active district: %s bounds=[%.2f..%.2f, %.2f..%.2f]" % [str(hit), min_x, max_x, min_z, max_z])
        return

    var expected_x: float = -float(game.GRID_W) * 0.5 + float(game.unlocked_cols) * 0.5
    if absf(hit.x - expected_x) > 1.5:
        _fail("camera framing is not centered on active district: %s expected_x=%.2f" % [str(hit), expected_x])
        return

    print("RENDER_FIXTURE_OK ray=%s hit=%s geometry=%d" % [str(ray_dir), str(hit), game.v10_static_root.get_child_count()])
    game.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("RENDER_FIXTURE_FAILED: " + message)
    quit(1)
