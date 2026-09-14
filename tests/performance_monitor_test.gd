extends SceneTree

const PerformanceMonitor = preload("res://performance/performance_monitor.gd")

var _failed: bool = false

func _init() -> void:
    var monitor: RefCounted = PerformanceMonitor.new()
    _check(bool(monitor.begin("P3_MID", 1800, 69, 4)), "valid performance state rejected")
    _check(not bool(monitor.begin("BAD_STATE")), "invalid performance state accepted")
    _check(bool(monitor.begin("P3_MID", 1800, 69, 4)), "monitor did not reset after invalid begin")

    for _i: int in range(600):
        monitor.sample_frame(1.0 / 60.0)
    var stable: Dictionary = monitor.snapshot()
    _check(int(stable.get("sample_count", 0)) == 600, "stable sample count mismatch")
    _check(absf(float(stable.get("avg_fps", 0.0)) - 60.0) < 0.5, "stable average fps mismatch")
    _check(float(stable.get("p95_frame_ms", 99.0)) < 18.0, "stable p95 frame time too high")
    _check(not bool(monitor.has_hard_regression()), "stable 60fps run marked hard regression")

    var summary: Dictionary = monitor.analytics_summary("mobile_unknown")
    _check(String(summary.get("avg_fps_band", "")) == "55_60", "analytics fps band mismatch")
    _check(String(summary.get("startup_ms_band", "")) == "lt_2000", "analytics startup band mismatch")
    _check(String(summary.get("geometry_band", "")) == "50_99", "analytics geometry band mismatch")
    _check(int(summary.get("city_tier", 0)) == 4, "analytics city tier mismatch")

    _check(bool(monitor.begin("P5_METRO", 4200, 250, 6)), "stress state begin failed")
    for _i: int in range(150):
        monitor.sample_frame(1.0 / 25.0)
    _check(bool(monitor.has_hard_regression()), "sustained sub-30fps segment did not trip hard regression")

    _check(bool(monitor.begin("P1_FTUE", 1000, 30, 1)), "input-latency state begin failed")
    monitor.record_interaction_latency(120.0)
    _check(bool(monitor.has_hard_regression()), "100ms+ input stall did not trip hard regression")

    _check(bool(monitor.begin("P4_DENSE", 2500, 160, 5)), "rolling-window state begin failed")
    for _i: int in range(1400):
        monitor.sample_frame(1.0 / 60.0)
    var rolling: Dictionary = monitor.snapshot()
    _check(int(rolling.get("sample_count", 0)) == 1200, "rolling sample window is unbounded")
    _check(int(rolling.get("sample_window_sec", 0)) in [19, 20], "rolling sample window duration inconsistent")
    _check(float(rolling.get("slow_frame_rate", 1.0)) < 0.001, "rolling slow-frame rate drifted")

    if _failed:
        quit(1)
        return
    print("PERFORMANCE_MONITOR_OK")
    quit(0)

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    _failed = true
    push_error("PERFORMANCE_MONITOR_FAILED: " + message)
