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
    if absf(hit.x) > 1.0 or absf(hit.z) > 1.0:
        _fail("camera center ray misses city center: %s" % str(hit))
        return

    print("RENDER_FIXTURE_OK ray=%s hit=%s geometry=%d" % [str(ray_dir), str(hit), game.v10_static_root.get_child_count()])
    game.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("RENDER_FIXTURE_FAILED: " + message)
    quit(1)
