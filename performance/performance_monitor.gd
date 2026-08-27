extends RefCounted

const Bands = preload("res://performance/performance_bands.gd")

const MAX_FRAME_SAMPLES: int = 1200
const SLOW_FRAME_MS: float = 25.0
const BELOW_30_FRAME_MS: float = 1000.0 / 30.0
const HARD_BELOW_30_DURATION_SEC: float = 5.0
const HARD_INPUT_STALL_MS: float = 100.0

var state_name: String = "P0_EMPTY"
var startup_ms: int = -1
var geometry_count: int = -1
var city_tier: int = 1

var _frame_ms: Array = []
var _window_elapsed_sec: float = 0.0
var _slow_frame_count: int = 0
var _current_below_30_sec: float = 0.0
var _max_below_30_sec: float = 0.0
var _max_interaction_latency_ms: float = 0.0

func begin(sample_state: String, measured_startup_ms: int = -1, measured_geometry_count: int = -1, measured_city_tier: int = 1) -> bool:
    if not Bands.is_valid_state(sample_state):
        return false
    state_name = sample_state
    startup_ms = measured_startup_ms
    geometry_count = measured_geometry_count
    city_tier = measured_city_tier
    _frame_ms.clear()
    _window_elapsed_sec = 0.0
    _slow_frame_count = 0
    _current_below_30_sec = 0.0
    _max_below_30_sec = 0.0
    _max_interaction_latency_ms = 0.0
    return true

func sample_frame(delta_sec: float) -> void:
    if delta_sec <= 0.0:
        return
    var frame_ms: float = delta_sec * 1000.0
    _frame_ms.append(frame_ms)
    _window_elapsed_sec += delta_sec
    if frame_ms > SLOW_FRAME_MS:
        _slow_frame_count += 1

    if _frame_ms.size() > MAX_FRAME_SAMPLES:
        var removed_ms: float = float(_frame_ms.pop_front())
        _window_elapsed_sec = maxf(0.0, _window_elapsed_sec - removed_ms / 1000.0)
        if removed_ms > SLOW_FRAME_MS:
            _slow_frame_count = maxi(0, _slow_frame_count - 1)

    if frame_ms >= BELOW_30_FRAME_MS:
        _current_below_30_sec += delta_sec
        _max_below_30_sec = maxf(_max_below_30_sec, _current_below_30_sec)
    else:
        _current_below_30_sec = 0.0

func record_interaction_latency(latency_ms: float) -> void:
    if latency_ms <= 0.0:
        return
    _max_interaction_latency_ms = maxf(_max_interaction_latency_ms, latency_ms)

func snapshot() -> Dictionary:
    if _frame_ms.is_empty():
        return {
            "state": state_name,
            "sample_count": 0,
            "sample_window_sec": 0,
            "avg_fps": 0.0,
            "avg_frame_ms": 0.0,
            "p95_frame_ms": 0.0,
            "worst_frame_ms": 0.0,
            "slow_frame_rate": 0.0,
            "max_below_30_sec": _max_below_30_sec,
            "max_interaction_latency_ms": _max_interaction_latency_ms,
            "startup_ms": startup_ms,
            "geometry_count": geometry_count,
            "city_tier": city_tier,
        }

    var total_ms: float = 0.0
    var worst_ms: float = 0.0
    for value_variant: Variant in _frame_ms:
        var value: float = float(value_variant)
        total_ms += value
        worst_ms = maxf(worst_ms, value)
    var avg_ms: float = total_ms / float(_frame_ms.size())
    var avg_fps: float = 1000.0 / avg_ms if avg_ms > 0.0 else 0.0
    var sorted: Array = _frame_ms.duplicate()
    sorted.sort()
    var p95_index: int = clampi(int(floor(float(sorted.size() - 1) * 0.95)), 0, sorted.size() - 1)
    var p95_ms: float = float(sorted[p95_index])
    var slow_rate: float = float(_slow_frame_count) / float(maxi(1, _frame_ms.size()))

    return {
        "state": state_name,
        "sample_count": _frame_ms.size(),
        "sample_window_sec": int(round(_window_elapsed_sec)),
        "avg_fps": avg_fps,
        "avg_frame_ms": avg_ms,
        "p95_frame_ms": p95_ms,
        "worst_frame_ms": worst_ms,
        "slow_frame_rate": slow_rate,
        "max_below_30_sec": _max_below_30_sec,
        "max_interaction_latency_ms": _max_interaction_latency_ms,
        "startup_ms": startup_ms,
        "geometry_count": geometry_count,
        "city_tier": city_tier,
    }

func analytics_summary(device_class: String) -> Dictionary:
    var data: Dictionary = snapshot()
    return {
        "sample_window_sec": int(data["sample_window_sec"]),
        "avg_fps_band": Bands.fps_band(float(data["avg_fps"])),
        "slow_frame_rate_band": Bands.slow_frame_rate_band(float(data["slow_frame_rate"])),
        "startup_ms_band": Bands.startup_ms_band(startup_ms),
        "city_tier": city_tier,
        "geometry_band": Bands.geometry_band(geometry_count),
        "device_class": device_class,
    }

func has_hard_regression() -> bool:
    return _max_below_30_sec >= HARD_BELOW_30_DURATION_SEC or _max_interaction_latency_ms >= HARD_INPUT_STALL_MS
