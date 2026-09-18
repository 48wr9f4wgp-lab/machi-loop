extends "res://main_v36_1_expansion_reveal.gd"

# AXIVA v0.37 — deterministic physical-device Recovery Gate mode.
#
# Web URL ?recovery=1 starts from a seeded severe-congestion city so the real
# player interaction can validate:
#   congestion -> bypass intervention -> visible recovery -> resumed growth
#
# The mode is ephemeral and never reads, writes, resets or deletes the player's
# normal city / FTUE persistence. Normal launches are unchanged.

var v37_recovery_session: bool = false
var v37_fixture_seed_count: int = 0

func _ready() -> void:
    # Must be known before the inherited v0.7 load hook executes.
    v37_recovery_session = _v37_detect_recovery_session()
    super._ready()
    if v37_recovery_session:
        queue_redraw()

func _v37_detect_recovery_session() -> bool:
    if not OS.has_feature("web"):
        return false
    var query_value: Variant = JavaScriptBridge.eval("window.location.search", true)
    return _v37_query_requests_recovery(str(query_value))

func _v37_query_requests_recovery(query: String) -> bool:
    var normalized: String = query.strip_edges()
    if normalized.begins_with("?"):
        normalized = normalized.substr(1)
    if normalized.is_empty():
        return false
    for raw_part: String in normalized.split("&"):
        if raw_part.strip_edges() == "recovery=1":
            return true
    return false

# v0.7 calls this before the 3D renderer is created. Seed here so the first
# renderer build already sees the final fixture, avoiding a second startup rebuild.
func _v07_load_city() -> bool:
    if not v37_recovery_session:
        return super._v07_load_city()
    _v37_seed_recovery_fixture()
    return false

func _v37_seed_recovery_fixture() -> void:
    _init_grid()
    widened.clear()

    unlocked_cols = GRID_W
    city_level = 4
    cash = 3000
    tick_count = 0
    paused = false
    current_tool = Tool.ROAD
    v04_first_growth_seeded = true

    # Suppress first-city choreography: this mode begins at the structural
    # congestion beat, not at FTUE.
    v23_birth_started = true
    v23_birth_announced = true
    v28_sequence_active = false
    v29_recovery_stage = V29_STAGE_NONE
    v29_hotspot_cells.clear()
    v29_bypass_cells.clear()
    v29_intervention_count = 0
    v29_recovery_count = 0
    v29_growth_resume_count = 0
    v29_completion_count = 0

    # Same deterministic topology used by the v0.29 model regression:
    # one overloaded east-west arterial with no redundant cycle.
    for x: int in range(3, 13):
        grid[10][x] = Cell.ARTERIAL

    for x: int in range(4, 12):
        grid[8][x] = Cell.RESIDENTIAL
        grid[12][x] = Cell.RESIDENTIAL

    for x: int in range(4, 8):
        grid[7][x] = Cell.RESIDENTIAL
        grid[6][x] = Cell.COMMERCIAL
        grid[14][x] = Cell.INDUSTRIAL

    _recalculate_city()
    v37_fixture_seed_count += 1

# Recovery validation is disposable. Never touch the user's normal persistence.
func _v07_save_city() -> void:
    if v37_recovery_session:
        return
    super._v07_save_city()

func _v20_load_ftue_stage() -> int:
    if v37_recovery_session:
        return FtueModel.COMPLETE
    return super._v20_load_ftue_stage()

func _v20_save_ftue() -> void:
    if v37_recovery_session:
        return
    super._v20_save_ftue()

# v0.33 RESET normally deletes persistent city state before reloading. In this
# test mode RESET must only reload the same ephemeral recovery fixture.
func _v33_delete_persistent_city_state() -> void:
    if v37_recovery_session:
        return
    super._v33_delete_persistent_city_state()
