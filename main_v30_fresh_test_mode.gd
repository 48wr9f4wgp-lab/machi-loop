extends "res://main_v29_congestion_recovery.gd"

# MACHI LOOP v0.30 — deterministic fresh-session test mode.
# Web URL ?fresh=1 starts from an empty city without reading OR overwriting the
# player's normal city save. This is a development/device-validation path only.

var v30_fresh_session: bool = false

func _ready() -> void:
    v30_fresh_session = _v30_detect_fresh_session()
    super._ready()
    if v30_fresh_session:
        # Keep the first-frame state explicit after the inherited ready chain.
        v23_birth_started = false
        v23_birth_announced = false
        v23_birth_road_count = 0
        v23_birth_population = 0
        v23_alert_text = ""
        queue_redraw()

func _v30_detect_fresh_session() -> bool:
    if not OS.has_feature("web"):
        return false
    var query_value: Variant = JavaScriptBridge.eval("window.location.search", true)
    return _v30_query_requests_fresh(str(query_value))

func _v30_query_requests_fresh(query: String) -> bool:
    var normalized: String = query.strip_edges()
    if normalized.begins_with("?"):
        normalized = normalized.substr(1)
    if normalized.is_empty():
        return false
    for raw_part: String in normalized.split("&"):
        var part: String = raw_part.strip_edges()
        if part == "fresh=1":
            return true
    return false

# Parent ready/load uses dynamic dispatch, so this blocks restore before any
# persisted city state can enter the runtime.
func _v07_load_city() -> bool:
    if v30_fresh_session:
        return false
    return super._v07_load_city()

# A fresh validation session is intentionally ephemeral. Never rotate backups,
# autosave, or overwrite the player's normal city while ?fresh=1 is active.
func _v07_save_city() -> void:
    if v30_fresh_session:
        return
    super._v07_save_city()
