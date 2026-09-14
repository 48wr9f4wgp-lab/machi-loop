extends SceneTree

const AnalyticsController = preload("res://analytics/analytics_controller.gd")

class CaptureAdapter:
    extends RefCounted
    var events: Array = []

    func provider_name() -> String:
        return "capture"

    func send_event(event_name: String, properties: Dictionary) -> bool:
        events.append({"event_name": event_name, "properties": properties.duplicate(true)})
        return true

var _failed: bool = false

func _init() -> void:
    var adapter: CaptureAdapter = CaptureAdapter.new()
    var controller: RefCounted = AnalyticsController.new(adapter)
    controller.configure_context("0.22B-test", "Web", "ja_JP")

    _check(controller.provider_name() == "capture", "provider name not exposed")
    _check(bool(controller.track("ftue_start")), "valid no-property event was rejected")
    _check(adapter.events.size() == 1, "valid event was not delivered exactly once")

    if adapter.events.size() == 1:
        var properties: Dictionary = adapter.events[0]["properties"] as Dictionary
        _check(int(properties.get("event_schema_version", -1)) == 1, "schema version not injected")
        _check(String(properties.get("release_version", "")) == "0.22B-test", "release version not injected")
        _check(String(properties.get("platform", "")) == "Web", "platform not injected")
        _check(String(properties.get("locale", "")) == "ja_JP", "locale not injected")

    _check(not bool(controller.track("unknown_event")), "unknown event was delivered")
    _check(adapter.events.size() == 1, "invalid event reached adapter")

    var perf: Dictionary = {
        "sample_window_sec": 30,
        "avg_fps_band": "55_60",
        "slow_frame_rate_band": "lt_1pct",
        "startup_ms_band": "lt_2000",
        "city_tier": 4,
        "geometry_band": "50_99",
        "device_class": "mobile_unknown",
    }
    _check(bool(controller.track("performance_summary", perf)), "first performance summary rejected")
    _check(not bool(controller.track("performance_summary", perf)), "second performance summary was not rate-limited")
    _check(adapter.events.size() == 2, "performance summary delivery count incorrect")

    controller.reset_session_guards()
    _check(bool(controller.track("performance_summary", perf)), "performance summary did not reset for new session")
    _check(adapter.events.size() == 3, "post-reset performance summary not delivered")

    var noop_controller: RefCounted = AnalyticsController.new()
    noop_controller.configure_context("0.22B-test", "Web", "ja_JP")
    _check(noop_controller.provider_name() == "noop", "default adapter is not no-op")
    _check(bool(noop_controller.track("ftue_start")), "no-op adapter should accept valid event without network dependency")

    if _failed:
        quit(1)
        return
    print("ANALYTICS_CONTROLLER_OK")
    quit(0)

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    _failed = true
    push_error("ANALYTICS_CONTROLLER_FAILED: " + message)
