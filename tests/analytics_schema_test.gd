extends SceneTree

const EventSchema = preload("res://analytics/analytics_event_schema.gd")

var _failed: bool = false

func _init() -> void:
    var common: Dictionary = {
        "event_schema_version": 1,
        "release_version": "0.22B-test",
        "platform": "Web",
        "locale": "ja_JP",
    }

    var valid_session: Dictionary = common.duplicate()
    valid_session.merge({
        "returning_user": false,
        "save_schema_version": 6,
        "city_tier": 1,
        "population_band": "0_49",
    })
    _check(bool(EventSchema.validate_event("session_start", valid_session).get("ok", false)), "valid session_start rejected")

    var unknown_event: Dictionary = EventSchema.validate_event("made_up_event", common)
    _check(not bool(unknown_event.get("ok", true)), "unknown event accepted")

    var unknown_property: Dictionary = valid_session.duplicate()
    unknown_property["mystery"] = 1
    _check(not bool(EventSchema.validate_event("session_start", unknown_property).get("ok", true)), "unknown property accepted")

    var pii_property: Dictionary = common.duplicate()
    pii_property["email"] = "blocked@example.invalid"
    _check(not bool(EventSchema.validate_event("ftue_start", pii_property).get("ok", true)), "PII-like property accepted")

    var wrong_type: Dictionary = valid_session.duplicate()
    wrong_type["city_tier"] = "1"
    _check(not bool(EventSchema.validate_event("session_start", wrong_type).get("ok", true)), "wrong property type accepted")

    var valid_setting: Dictionary = common.duplicate()
    valid_setting.merge({"key": "sfx_enabled", "value": "false"})
    _check(bool(EventSchema.validate_event("settings_change", valid_setting).get("ok", false)), "allowed settings key/value rejected")

    var invalid_setting_key: Dictionary = common.duplicate()
    invalid_setting_key.merge({"key": "free_form_setting", "value": "true"})
    _check(not bool(EventSchema.validate_event("settings_change", invalid_setting_key).get("ok", true)), "arbitrary settings key accepted")

    var invalid_setting_value: Dictionary = common.duplicate()
    invalid_setting_value.merge({"key": "haptics_enabled", "value": "free form user value"})
    _check(not bool(EventSchema.validate_event("settings_change", invalid_setting_value).get("ok", true)), "arbitrary settings value accepted")

    if _failed:
        quit(1)
        return
    print("ANALYTICS_SCHEMA_OK")
    quit(0)

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    _failed = true
    push_error("ANALYTICS_SCHEMA_FAILED: " + message)
