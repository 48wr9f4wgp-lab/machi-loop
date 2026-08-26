extends RefCounted

const Schema = preload("res://observability/observability_schema.gd")
const NoopCrashReporter = preload("res://observability/noop_crash_reporter.gd")

const MAX_BREADCRUMBS: int = 32

var _reporter: RefCounted
var _breadcrumbs: Array[Dictionary] = []

func _init(reporter: RefCounted = null) -> void:
    _reporter = reporter if reporter != null else NoopCrashReporter.new()

func set_reporter(reporter: RefCounted) -> void:
    _reporter = reporter if reporter != null else NoopCrashReporter.new()

func record_breadcrumb(action_code: String, context: Dictionary = {}) -> bool:
    if not Schema.is_safe_code(action_code):
        return false
    if Schema.contains_banned_key(context):
        return false
    var normalized: Dictionary = {
        "action": action_code,
        "context": Schema.sanitize_context(context),
    }
    _breadcrumbs.append(normalized)
    if _breadcrumbs.size() > MAX_BREADCRUMBS:
        _breadcrumbs.pop_front()
    return true

func report_error(error_code: String, severity: String, context: Dictionary = {}) -> bool:
    if not Schema.is_safe_code(error_code):
        return false
    if not Schema.is_valid_severity(severity):
        return false
    if Schema.contains_banned_key(context):
        return false
    if _reporter == null or not _reporter.has_method("send_error"):
        return false
    var event: Dictionary = {
        "code": error_code,
        "severity": severity,
        "context": Schema.sanitize_context(context),
        "breadcrumbs": _breadcrumbs.duplicate(true),
    }
    return bool(_reporter.call("send_error", event))

func breadcrumb_snapshot() -> Array[Dictionary]:
    return _breadcrumbs.duplicate(true)

func clear_breadcrumbs() -> void:
    _breadcrumbs.clear()
