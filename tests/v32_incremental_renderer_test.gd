extends SceneTree

const GameClass = preload("res://main_v32_incremental_renderer.gd")

func _init() -> void:
    var game = GameClass.new()
    game._init_grid()

    # Functional/headless fixtures may exercise simulation before renderer setup.
    # Renderer sync must remain a safe no-op and must not arm incremental state.
    game._v10_sync_scene()
    _expect(not game.v32_snapshot_ready, "renderer-less sync armed incremental snapshot")

    game._v32_capture_snapshot()
    game.v32_snapshot_ready = true

    _expect(game._v32_cell_transition_is_incremental(game.Cell.EMPTY, game.Cell.LOCAL), "EMPTY -> LOCAL must be incremental")
    _expect(game._v32_cell_transition_is_incremental(game.Cell.EMPTY, game.Cell.RESIDENTIAL), "EMPTY -> RESIDENTIAL must be incremental")
    _expect(game._v32_cell_transition_is_incremental(game.Cell.EMPTY, game.Cell.COMMERCIAL), "EMPTY -> COMMERCIAL must be incremental")
    _expect(game._v32_cell_transition_is_incremental(game.Cell.EMPTY, game.Cell.INDUSTRIAL), "EMPTY -> INDUSTRIAL must be incremental")
    _expect(not game._v32_cell_transition_is_incremental(game.Cell.EMPTY, game.Cell.ARTERIAL), "player arterial edits require structural rebuild")
    _expect(not game._v32_cell_transition_is_incremental(game.Cell.LOCAL, game.Cell.EMPTY), "deletion requires structural rebuild")
    _expect(not game._v32_cell_transition_is_incremental(game.Cell.RESIDENTIAL, game.Cell.COMMERCIAL), "parcel type replacement requires structural rebuild")

    game.grid[3][2] = game.Cell.LOCAL
    game.grid[4][2] = game.Cell.RESIDENTIAL
    var growth_changes: Array = game._v32_collect_cell_changes()
    _expect(growth_changes.size() == 2, "expected two autonomous growth deltas")
    _expect(game._v32_changes_are_incremental(growth_changes), "ordinary autonomous growth must avoid full rebuild")
    _expect(not game._v32_scalar_state_requires_full_rebuild(), "unchanged scalar state requested full rebuild")

    game._v32_capture_snapshot()
    game.grid[5][2] = game.Cell.ARTERIAL
    var arterial_changes: Array = game._v32_collect_cell_changes()
    _expect(not game._v32_changes_are_incremental(arterial_changes), "arterial topology edit must fall back to full rebuild")

    game._v32_capture_snapshot()
    game.unlocked_cols += 1
    _expect(game._v32_scalar_state_requires_full_rebuild(), "unlock boundary change must rebuild")

    print("V32_INCREMENTAL_RENDERER_OK")
    game.free()
    quit(0)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V32_INCREMENTAL_RENDERER_FAILED: " + message)
    quit(1)
