extends SceneTree

const GameClass = preload("res://main_v35_road_draw_map_scale.gd")

func _init() -> void:
    var game = GameClass.new()
    game._init_grid()
    game.unlocked_cols = game.START_UNLOCKED_COLS
    game.population = 0
    game._v35_prepare_width_before_renderer()

    _expect(game.unlocked_cols == 12, "pre-render width normalization failed")
    _expect(game.V35_MIN_OPEN_COLS == 12, "fresh build area must expose 12 columns")
    _expect(game.V35_MIN_OPEN_COLS > game.START_UNLOCKED_COLS, "v0.35 did not widen early map")
    _expect(game.V35_MIN_OPEN_COLS <= game.GRID_W, "fresh build width exceeds backing grid")
    _expect(game._v35_desired_unlocked_cols(0) == 12, "fresh width mismatch")
    _expect(game._v35_desired_unlocked_cols(89) == 12, "pre-tier2 width mismatch")
    _expect(game._v35_desired_unlocked_cols(90) == 14, "tier2 width mismatch")
    _expect(game._v35_desired_unlocked_cols(199) == 14, "tier2 width regressed")
    _expect(game._v35_desired_unlocked_cols(200) == 16, "tier3 width mismatch")

    # Regression for the physical-iPhone black-map failure: v0.35 must not
    # force a second full static-city rebuild from its ready hook.
    var source: String = FileAccess.get_file_as_string("res://main_v35_road_draw_map_scale.gd")
    var ready_start: int = source.find("func _ready() -> void:")
    var pointer_start: int = source.find("func _pointer_down", ready_start)
    var ready_block: String = source.substr(ready_start, pointer_start - ready_start)
    _expect(not ready_block.contains("_v10_sync_scene(true)"), "ready hook reintroduced forced full rebuild")

    var origin := Vector2i(4, 8)

    var horizontal_axis: int = game._v35_choose_axis(
        origin,
        Vector2i(10, 9),
        Vector2(100.0, 100.0),
        Vector2(260.0, 126.0)
    )
    _expect(horizontal_axis == game.V35Axis.HORIZONTAL, "mostly-horizontal gesture did not lock horizontal")
    var h_target: Vector2i = game._v35_snap_to_axis(origin, Vector2i(10, 9), horizontal_axis)
    _expect(h_target == Vector2i(10, 8), "horizontal snap changed row")
    var h_path: Array = game._v35_straight_path(origin, h_target)
    _expect(h_path.size() == 7, "horizontal road cell count changed")
    for item: Variant in h_path:
        _expect((item as Vector2i).y == origin.y, "horizontal road contains vertical wobble")

    var vertical_axis: int = game._v35_choose_axis(
        origin,
        Vector2i(5, 15),
        Vector2(100.0, 100.0),
        Vector2(120.0, 310.0)
    )
    _expect(vertical_axis == game.V35Axis.VERTICAL, "mostly-vertical gesture did not lock vertical")
    var v_target: Vector2i = game._v35_snap_to_axis(origin, Vector2i(5, 15), vertical_axis)
    _expect(v_target == Vector2i(4, 15), "vertical snap changed column")
    var v_path: Array = game._v35_straight_path(origin, v_target)
    _expect(v_path.size() == 8, "vertical road cell count changed")
    for item: Variant in v_path:
        _expect((item as Vector2i).x == origin.x, "vertical road contains horizontal wobble")

    var tie_horizontal: int = game._v35_choose_axis(
        origin,
        Vector2i(6, 10),
        Vector2(100.0, 100.0),
        Vector2(180.0, 145.0)
    )
    _expect(tie_horizontal == game.V35Axis.HORIZONTAL, "touch delta did not resolve diagonal tie horizontally")

    print("V35_ROAD_DRAW_MAP_SCALE_OK")
    game.free()
    quit(0)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V35_ROAD_DRAW_MAP_SCALE_FAILED: " + message)
    quit(1)
