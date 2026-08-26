extends SceneTree

const Schema = preload("res://observability/observability_schema.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    if not Schema.is_valid_severity("warning") or not Schema.is_valid_severity("critical"):
        _fail("expected severities rejected")
        return
    if Schema.is_valid_severity("debug"):
        _fail("debug must not be accepted in release observability schema")
        return
    if not Schema.is_safe_code("save_recovery_failed"):
        _fail("safe snake_case code rejected")
        return
    if Schema.is_safe_code("Save Recovery Failed"):
        _fail("free-form/space error code accepted")
        return
    var unsafe: Dictionary = {"email": "person@example.com", "stage": "load"}
    if not Schema.contains_banned_key(unsafe):
        _fail("banned PII key not detected")
        return
    var sanitized: Dictionary = Schema.sanitize_context({
        "release_version": "0.22A",
        "city_tier": 3,
        "stage": "load",
        "unknown": "drop",
        "email": "drop@example.com",
    })
    if sanitized.has("email") or sanitized.has("unknown"):
        _fail("unsafe/unknown context survived sanitize: %s" % str(sanitized))
        return
    if str(sanitized.get("release_version", "")) != "0.22A" or int(sanitized.get("city_tier", -1)) != 3:
        _fail("allowed context was lost: %s" % str(sanitized))
        return

    print("OBSERVABILITY_SCHEMA_OK")
    quit(0)

func _fail(message: String) -> void:
    push_error("OBSERVABILITY_SCHEMA_FAILED: " + message)
    quit(1)
