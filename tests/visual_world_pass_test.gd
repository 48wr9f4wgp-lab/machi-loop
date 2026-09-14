extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var script: Script = load("res://main_v21_visual_pass2.gd") as Script
    if script == null:
        _fail("visual pass script did not load")
        return

    var game: Node = script.new() as Node
    root.add_child(game)
    await process_frame
    await process_frame

    if not is_instance_valid(game.v10_viewport) or not is_instance_valid(game.v10_static_root):
        _fail("3D renderer did not initialize")
        return

    for required: String in ["v22_ground", "v22_arterial", "v22_local", "v22_curb", "v22_civic_gold", "v22_vehicle_glass"]:
        if not game.v10_materials.has(required):
            _fail("missing visual material: " + required)
            return

    var arterial_mat: StandardMaterial3D = game.v10_materials["v22_arterial"] as StandardMaterial3D
    var local_mat: StandardMaterial3D = game.v10_materials["v22_local"] as StandardMaterial3D
    if arterial_mat == null or local_mat == null:
        _fail("road hierarchy materials are invalid")
        return
    if arterial_mat.albedo_color.get_luminance() >= local_mat.albedo_color.get_luminance():
        _fail("arterial road must remain visually darker than local roads")
        return

    game.board_rect = Rect2(20.0, 150.0, 390.0, 620.0)
    if game._v09_policy_chip_rect().size.x >= 112.0:
        _fail("policy chip was not compacted")
        return
    if game._v18_service_chip_rect().size.x >= 112.0:
        _fail("service chip was not compacted")
        return

    game._init_grid()
    game.unlocked_cols = game.GRID_W
    game.city_level = 4
    for x: int in range(2, 12):
        game.grid[10][x] = game.Cell.ARTERIAL
    for y: int in range(6, 15):
        game.grid[y][6] = game.Cell.ARTERIAL
    game.grid[9][5] = game.Cell.COMMERCIAL
    game.grid[9][7] = game.Cell.COMMERCIAL
    game.grid[11][5] = game.Cell.RESIDENTIAL
    game.grid[11][7] = game.Cell.INDUSTRIAL
    game._recalculate_city()
    game._v10_sync_scene(true)
    await process_frame

    if not is_instance_valid(game.v22_landmark_node):
        _fail("tier 3+ city did not receive a progression landmark")
        return
    if game.v22_landmark_node.name != "V22CityLandmark":
        _fail("landmark node has unexpected identity")
        return

    var tree_roots: int = 0
    for child: Node in game.v10_static_root.get_children():
        if child.name.begins_with("V22Tree_"):
            tree_roots += 1
    if tree_roots <= 0:
        _fail("organic vegetation pass generated no tree roots")
        return

    game._v10_rebuild_vehicles()
    if game.v10_vehicle_nodes.is_empty():
        _fail("vehicle pass generated no cars")
        return
    var first_car: Node3D = game.v10_vehicle_nodes[0] as Node3D
    if first_car == null or first_car.get_child_count() < 2:
        _fail("miniature vehicle must have body + cabin silhouette")
        return

    print("VISUAL_WORLD_PASS_OK trees=%d vehicles=%d geometry=%d" % [tree_roots, game.v10_vehicle_nodes.size(), game.v10_static_root.get_child_count()])
    game.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("VISUAL_WORLD_PASS_FAILED: " + message)
    quit(1)
