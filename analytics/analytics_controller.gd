extends RefCounted

const EventSchema = preload("res://analytics/analytics_event_schema.gd")
const NoopAdapter = preload("res://analytics/analytics_adapter.gd")

var _adapter: RefCounted
var _common_context: Dictionary = {
    "release_version": "unknown",
    "platform": "unknown",
    "locale": "unknown",
}
var _performance_summary_sent: bool = false

func _init(custom_adapter: RefCounted = null) -> void:
    _adapter = custom_adapter if custom_adapter != null else NoopAdapter.new()

func configure_context(release_version: String, platform: String, locale: String) -> void:
    _common_context["release_version"] = release_version
    _common_context["platform"] = platform
    _common_context["locale"] = locale

func provider_name() -> String:
    if _adapter != null and _adapter.has_method("provider_name"):
        return String(_adapter.call("provider_name"))
    return "unknown"

func reset_session_guards() -> void:
    _performance_summary_sent = false

func track(event_name: String, event_properties: Dictionary = {}) -> bool:
    if event_name == "performance_summary" and _performance_summary_sent:
        return false

    var properties: Dictionary = event_properties.duplicate(true)
    properties["event_schema_version"] = EventSchema.EVENT_SCHEMA_VERSION
    properties["release_version"] = String(_common_context["release_version"])
    properties["platform"] = String(_common_context["platform"])
    properties["locale"] = String(_common_context["locale"])

    var validation: Dictionary = EventSchema.validate_event(event_name, properties)
    if not bool(validation.get("ok", false)):
        return false

    if _adapter == null or not _adapter.has_method("send_event"):
        return false

    var accepted: bool = bool(_adapter.call("send_event", event_name, properties.duplicate(true)))
    if accepted and event_name == "performance_summary":
        _performance_summary_sent = true
    return accepted
