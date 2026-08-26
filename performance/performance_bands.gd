extends RefCounted

const VALID_STATES: Array[String] = ["P0_EMPTY", "P1_FTUE", "P2_SMALL", "P3_MID", "P4_DENSE", "P5_METRO"]

static func is_valid_state(state_name: String) -> bool:
    return VALID_STATES.has(state_name)

static func fps_band(avg_fps: float) -> String:
    if avg_fps < 30.0:
        return "lt_30"
    if avg_fps < 45.0:
        return "30_44"
    if avg_fps < 55.0:
        return "45_54"
    if avg_fps <= 60.5:
        return "55_60"
    return "gt_60"

static func slow_frame_rate_band(rate: float) -> String:
    if rate < 0.01:
        return "lt_1pct"
    if rate < 0.05:
        return "1_5pct"
    if rate < 0.15:
        return "5_15pct"
    return "gte_15pct"

static func startup_ms_band(startup_ms: int) -> String:
    if startup_ms < 0:
        return "unknown"
    if startup_ms < 2000:
        return "lt_2000"
    if startup_ms < 3000:
        return "2000_2999"
    if startup_ms < 5000:
        return "3000_4999"
    return "gte_5000"

static func geometry_band(geometry_count: int) -> String:
    if geometry_count < 0:
        return "unknown"
    if geometry_count < 50:
        return "lt_50"
    if geometry_count < 100:
        return "50_99"
    if geometry_count < 200:
        return "100_199"
    if geometry_count < 400:
        return "200_399"
    return "gte_400"
