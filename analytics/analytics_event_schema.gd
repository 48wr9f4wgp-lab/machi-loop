extends RefCounted

const EVENT_SCHEMA_VERSION: int = 1

const COMMON_PROPERTIES: Dictionary = {
    "event_schema_version": TYPE_INT,
    "release_version": TYPE_STRING,
    "platform": TYPE_STRING,
    "locale": TYPE_STRING,
}

const EVENT_SCHEMAS: Dictionary = {
    "session_start": {
        "properties": {"returning_user": TYPE_BOOL, "save_schema_version": TYPE_INT, "city_tier": TYPE_INT, "population_band": TYPE_STRING},
        "required": ["returning_user", "save_schema_version", "city_tier", "population_band"],
    },
    "session_end": {
        "properties": {"duration_sec": TYPE_INT, "actions_count": TYPE_INT, "roads_committed": TYPE_INT, "goals_completed": TYPE_INT, "tier_delta": TYPE_INT, "cash_delta_band": TYPE_STRING},
        "required": ["duration_sec", "actions_count", "roads_committed", "goals_completed", "tier_delta", "cash_delta_band"],
    },
    "ftue_start": {"properties": {}, "required": []},
    "ftue_step": {
        "properties": {"step_id": TYPE_STRING, "elapsed_sec": TYPE_INT},
        "required": ["step_id", "elapsed_sec"],
    },
    "ftue_complete": {
        "properties": {"total_sec": TYPE_INT},
        "required": ["total_sec"],
    },
    "arterial_commit": {
        "properties": {"cells": TYPE_INT, "cost": TYPE_INT, "cash_after_band": TYPE_STRING, "traffic_before_band": TYPE_STRING},
        "required": ["cells", "cost", "cash_after_band", "traffic_before_band"],
    },
    "road_widen": {
        "properties": {"cost": TYPE_INT, "traffic_before_band": TYPE_STRING},
        "required": ["cost", "traffic_before_band"],
    },
    "road_bulldoze": {
        "properties": {"refund": TYPE_INT, "maintenance_delta_band": TYPE_STRING},
        "required": ["refund", "maintenance_delta_band"],
    },
    "action_blocked": {
        "properties": {"action": TYPE_STRING, "reason": TYPE_STRING},
        "required": ["action", "reason"],
    },
    "city_goal_complete": {
        "properties": {"goal_id": TYPE_STRING, "reward": TYPE_INT, "elapsed_session_sec": TYPE_INT},
        "required": ["goal_id", "reward", "elapsed_session_sec"],
    },
    "city_tier_up": {
        "properties": {"from_tier": TYPE_INT, "to_tier": TYPE_INT, "population": TYPE_INT},
        "required": ["from_tier", "to_tier", "population"],
    },
    "district_unlock": {
        "properties": {"district_index": TYPE_INT, "population": TYPE_INT},
        "required": ["district_index", "population"],
    },
    "policy_change": {
        "properties": {"from_policy": TYPE_STRING, "to_policy": TYPE_STRING, "cost": TYPE_INT},
        "required": ["from_policy", "to_policy", "cost"],
    },
    "service_toggle": {
        "properties": {"service_id": TYPE_STRING, "enabled": TYPE_BOOL, "active_service_count": TYPE_INT, "service_slot_limit": TYPE_INT},
        "required": ["service_id", "enabled", "active_service_count", "service_slot_limit"],
    },
    "settings_change": {
        "properties": {"key": TYPE_STRING, "value": TYPE_STRING},
        "required": ["key", "value"],
    },
    "save_write_failed": {
        "properties": {"schema_version": TYPE_INT, "stage": TYPE_STRING},
        "required": ["schema_version", "stage"],
    },
    "save_recovered": {
        "properties": {"schema_version": TYPE_INT, "source": TYPE_STRING},
        "required": ["schema_version", "source"],
    },
    "migration_success": {
        "properties": {"from_schema": TYPE_INT, "to_schema": TYPE_INT},
        "required": ["from_schema", "to_schema"],
    },
    "migration_failed": {
        "properties": {"from_schema": TYPE_INT, "target_schema": TYPE_INT, "stage": TYPE_STRING},
        "required": ["from_schema", "target_schema", "stage"],
    },
    "performance_summary": {
        "properties": {"sample_window_sec": TYPE_INT, "avg_fps_band": TYPE_STRING, "slow_frame_rate_band": TYPE_STRING, "startup_ms_band": TYPE_STRING, "city_tier": TYPE_INT, "geometry_band": TYPE_STRING, "device_class": TYPE_STRING},
        "required": ["sample_window_sec", "avg_fps_band", "slow_frame_rate_band", "startup_ms_band", "city_tier", "geometry_band", "device_class"],
    },
}

const ENUM_VALUES: Dictionary = {
    "ftue_step": {
        "step_id": ["first_main_road", "first_growth_seen", "first_goal_complete", "first_traffic_problem", "first_management_choice"],
    },
    "action_blocked": {
        "reason": ["insufficient_cash", "locked_area", "invalid_cell"],
    },
    "policy_change": {
        "from_policy": ["none", "homes", "jobs", "flow"],
        "to_policy": ["none", "homes", "jobs", "flow"],
    },
    "settings_change": {
        "key": ["sfx_enabled", "haptics_enabled"],
    },
    "save_recovered": {
        "source": ["backup", "default_fallback"],
    },
}

const FORBIDDEN_PROPERTY_KEYS: Array[String] = [
    "name",
    "email",
    "address",
    "precise_location",
    "gps",
    "latitude",
    "longitude",
    "free_text",
    "user_text",
    "save_payload",
    "save_data",
    "token",
    "secret",
    "device_id",
    "advertising_id",
]

static func validate_event(event_name: String, properties: Dictionary) -> Dictionary:
    if not EVENT_SCHEMAS.has(event_name):
        return _invalid("unknown_event")

    for key_variant: Variant in properties.keys():
        var key: String = String(key_variant)
        if FORBIDDEN_PROPERTY_KEYS.has(key):
            return _invalid("forbidden_property:%s" % key)

    var schema: Dictionary = EVENT_SCHEMAS[event_name] as Dictionary
    var allowed: Dictionary = COMMON_PROPERTIES.duplicate()
    var event_properties: Dictionary = schema.get("properties", {}) as Dictionary
    for key_variant: Variant in event_properties.keys():
        allowed[String(key_variant)] = event_properties[key_variant]

    for key_variant: Variant in properties.keys():
        var key: String = String(key_variant)
        if not allowed.has(key):
            return _invalid("unknown_property:%s" % key)
        if not _matches_type(properties[key_variant], int(allowed[key])):
            return _invalid("wrong_type:%s" % key)

    for common_key: String in ["event_schema_version", "release_version", "platform", "locale"]:
        if not properties.has(common_key):
            return _invalid("missing_property:%s" % common_key)

    if int(properties.get("event_schema_version", -1)) != EVENT_SCHEMA_VERSION:
        return _invalid("unsupported_schema_version")

    var required: Array = schema.get("required", []) as Array
    for key_variant: Variant in required:
        var key: String = String(key_variant)
        if not properties.has(key):
            return _invalid("missing_property:%s" % key)

    if ENUM_VALUES.has(event_name):
        var enum_rules: Dictionary = ENUM_VALUES[event_name] as Dictionary
        for key_variant: Variant in enum_rules.keys():
            var key: String = String(key_variant)
            if properties.has(key):
                var allowed_values: Array = enum_rules[key_variant] as Array
                if not allowed_values.has(properties[key]):
                    return _invalid("invalid_value:%s" % key)

    return {"ok": true, "error": ""}

static func _matches_type(value: Variant, expected_type: int) -> bool:
    if expected_type == TYPE_FLOAT:
        return typeof(value) in [TYPE_FLOAT, TYPE_INT]
    return typeof(value) == expected_type

static func _invalid(error: String) -> Dictionary:
    return {"ok": false, "error": error}
