extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var script: Script = load("res://main_v26_urban_hierarchy.gd") as Script
    if script == null:
        _fail("v0.26 script did not load")
        return

    var game: Node = script.new() as Node
    root.add_child(game)
    await process_frame
    await process_frame

    if not is_instance_valid(game.v10_viewport) or not is_instance_valid(game.v10_static_root):
        _fail("3D renderer did not initialize")
        return

    for required: String in ["v26_core_stone", "v26_core_glass", "v26_tree_leaf", "v26_car_red", "v26_wheel"]:
        if not game.v10_materials.has(required):
            _fail("missing v0.26 visual material: " + required)
            return

    game._init_grid()
    game.unlocked_cols = game.GRID_W
    game.city_level = 4

    for x: int in range(3, 13):
        game.grid[10][x] = game.Cell.ARTERIAL
    for y: int in range(6, 15):
        game.grid[y][7] = game.Cell.ARTERIAL

    for p: Vector2i in [
        Vector2i(5, 9), Vector2i(6, 9), Vector2i(8, 9), Vector2i(9, 9),
        Vector2i(5, 11), Vector2i(6, 11), Vector2i(8, 11), Vector2i(9, 11)
    ]:
        game.grid[p.y][p.x] = game.Cell.RESIDENTIAL

    for p: Vector2i in [Vector2i(6, 8), Vector2i(8, 8), Vector2i(6, 12), Vector2i(8, 12)]:
        game.grid[p.y][p.x] = game.Cell.COMMERCIAL

    for p: Vector2i in [Vector2i(4, 9), Vector2i(10, 11)]:
        game.grid[p.y][p.x] = game.Cell.INDUSTRIAL

    game._recalculate_city()
    game._v10_sync_scene(true)
    await process_frame

    if game.v26_core_tower_count <= 0:
        _fail("road-defined center generated no core tower crowns")
        return
    if game.v26_street_tree_count <= 0:
        _fail("arterial streets generated no street trees")
        return
    if game.v26_vehicle_target_count <= 8:
        _fail("active mature city did not receive enough traffic motion")
        return
    if game.v10_vehicle_nodes.size() != game.v26_vehicle_target_count:
        _fail("vehicle target count does not match rendered vehicles")
        return

    var first_car: Node3D = game.v10_vehicle_nodes[0] as Node3D
    if first_car == null or first_car.get_child_count() < 4:
        _fail("v0.26 miniature vehicle silhouette is incomplete")
        return

    game.congestion = 120.0
    game._v10_update_vehicles()
    if game.v26_vehicle_flow_multiplier >= 0.50:
        _fail("high congestion did not visibly slow traffic motion")
        return

    print("V26_URBAN_HIERARCHY_OK core=%d trees=%d vehicles=%d flow=%.2f" % [
        game.v26_core_tower_count,
        game.v26_street_tree_count,
        game.v26_vehicle_target_count,
        game.v26_vehicle_flow_multiplier
    ])
    game.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("V26_URBAN_HIERARCHY_FAILED: " + message)
    quit(1)
