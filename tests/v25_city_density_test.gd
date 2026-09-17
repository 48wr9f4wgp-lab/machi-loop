extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var script: Script = load("res://main_v25_city_density.gd") as Script
    if script == null:
        _fail("v0.25 script did not load")
        return

    var game: Node = script.new() as Node
    root.add_child(game)
    await process_frame
    await process_frame

    if not is_instance_valid(game.v10_viewport) or not is_instance_valid(game.v10_static_root):
        _fail("3D renderer did not initialize")
        return

    if game.tool_rects.size() != 3 or game.tool_rects.has(99):
        _fail("city-first toolbar must expose exactly road/widen/remove")
        return

    for required: String in ["v25_walk", "v25_facade_light", "v25_leaf_mid", "v25_planter"]:
        if not game.v10_materials.has(required):
            _fail("missing v0.25 visual material: " + required)
            return

    game._init_grid()
    game.unlocked_cols = game.GRID_W
    game.city_level = 4

    for x: int in range(2, 13):
        game.grid[10][x] = game.Cell.ARTERIAL
    for y: int in range(7, 14):
        game.grid[y][7] = game.Cell.ARTERIAL

    game.grid[9][4] = game.Cell.RESIDENTIAL
    game.grid[9][5] = game.Cell.RESIDENTIAL
    game.grid[9][8] = game.Cell.COMMERCIAL
    game.grid[9][9] = game.Cell.COMMERCIAL
    game.grid[11][4] = game.Cell.RESIDENTIAL
    game.grid[11][5] = game.Cell.INDUSTRIAL
    game.grid[11][8] = game.Cell.COMMERCIAL
    game.grid[11][9] = game.Cell.INDUSTRIAL

    game._recalculate_city()
    game._v10_sync_scene(true)
    await process_frame

    if game.v25_infill_count < 4:
        _fail("mature city parcels did not receive enough secondary massing")
        return
    if game.v25_arterial_detail_count <= 0:
        _fail("arterial streetscape detailing was not generated")
        return
    if game.v25_vegetation_cluster_count <= 0:
        _fail("open-land vegetation clusters were not generated")
        return

    var vegetation_nodes: int = 0
    for child: Node in game.v10_static_root.get_children():
        if child.name.begins_with("V25Vegetation_"):
            vegetation_nodes += 1
    if vegetation_nodes != game.v25_vegetation_cluster_count:
        _fail("vegetation counter does not match rendered cluster roots")
        return

    print("V25_CITY_DENSITY_OK infill=%d arterial=%d vegetation=%d geometry=%d" % [
        game.v25_infill_count,
        game.v25_arterial_detail_count,
        game.v25_vegetation_cluster_count,
        game.v10_static_root.get_child_count()
    ])
    game.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("V25_CITY_DENSITY_FAILED: " + message)
    quit(1)
