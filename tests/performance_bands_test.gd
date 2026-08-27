extends SceneTree

const Bands = preload("res://performance/performance_bands.gd")

var _failed: bool = false

func _init() -> void:
    _check(Bands.is_valid_state("P3_MID"), "known performance state rejected")
    _check(not Bands.is_valid_state("MID"), "unknown performance state accepted")
    _check(Bands.fps_band(59.7) == "55_60", "60fps band mismatch")
    _check(Bands.fps_band(28.0) == "lt_30", "low fps band mismatch")
    _check(Bands.slow_frame_rate_band(0.005) == "lt_1pct", "slow-frame low band mismatch")
    _check(Bands.slow_frame_rate_band(0.20) == "gte_15pct", "slow-frame high band mismatch")
    _check(Bands.startup_ms_band(1800) == "lt_2000", "startup band mismatch")
    _check(Bands.startup_ms_band(5200) == "gte_5000", "startup high band mismatch")
    _check(Bands.geometry_band(69) == "50_99", "geometry band mismatch")

    if _failed:
        quit(1)
        return
    print("PERFORMANCE_BANDS_OK")
    quit(0)

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    _failed = true
    push_error("PERFORMANCE_BANDS_FAILED: " + message)
