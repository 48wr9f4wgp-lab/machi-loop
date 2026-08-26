extends SceneTree

const Controller = preload("res://observability/observability_controller.gd")
const NoopCrashReporter = preload("res://observability/noop_crash_reporter.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var reporter: RefCounted = NoopCrashReporter.new()
    var controller: RefCounted = Controller.new(reporter)

    if not controller.record_breadcrumb("arterial_commit", {"city_tier": 2, "stage": "play"}):
        _fail("valid breadcrumb rejected")
        return
    if controller.record_breadcrumb("bad action", {}):
        _fail("invalid breadcrumb action accepted")
        return
    if controller.record_breadcrumb("policy_change", {"email": "person@example.com"}):
        _fail("PII-bearing breadcrumb accepted")
        return

    for index: int in range(40):
        if not controller.record_breadcrumb("simulation_step", {"city_tier": index % 6 + 1}):
            _fail("ring-buffer breadcrumb rejected")
            return
    var breadcrumbs: Array[Dictionary] = controller.breadcrumb_snapshot()
    if breadcrumbs.size() != 32:
        _fail("breadcrumb ring must cap at 32, got %d" % breadcrumbs.size())
        return

    if not controller.report_error("save_write_failed", "critical", {
        "release_version": "0.22A",
        "platform": "Web",
        "save_schema_version": 6,
        "stage": "write",
    }):
        _fail("valid error report rejected")
        return

    if controller.report_error("save failed with user text", "critical", {}):
        _fail("free-form error code accepted")
        return
    if controller.report_error("save_write_failed", "fatal", {}):
        _fail("unknown severity accepted")
        return
    if controller.report_error("save_write_failed", "error", {"token": "secret"}):
        _fail("secret-bearing report accepted")
        return

    var events: Array[Dictionary] = reporter.get("sent_events")
    if events.size() != 1:
        _fail("expected exactly one accepted report, got %d" % events.size())
        return
    var event: Dictionary = events[0]
    if str(event.get("code", "")) != "save_write_failed":
        _fail("wrong error code in normalized event")
        return
    if Array(event.get("breadcrumbs", [])).size() != 32:
        _fail("normalized event did not carry bounded breadcrumbs")
        return

    print("OBSERVABILITY_CONTROLLER_OK breadcrumbs=%d" % breadcrumbs.size())
    quit(0)

func _fail(message: String) -> void:
    push_error("OBSERVABILITY_CONTROLLER_FAILED: " + message)
    quit(1)
