extends SceneTree

func _init() -> void:
    var settings := FeedbackSettings.new()
    _require(settings.sfx_enabled, "sfx default")
    _require(is_equal_approx(settings.sfx_volume, 0.80), "sfx volume default")
    _require(settings.haptics_enabled, "haptics default")

    settings.apply_payload({"sfx_enabled": false, "sfx_volume": 0.35, "haptics_enabled": false})
    _require(not settings.sfx_enabled, "sfx payload")
    _require(is_equal_approx(settings.sfx_volume, 0.35), "sfx volume payload")
    _require(not settings.haptics_enabled, "haptics payload")

    var root := Node.new()
    get_root().add_child(root)
    var controller := FeedbackController.new()
    root.add_child(controller)
    await process_frame
    controller.settings.sfx_enabled = false
    controller.settings.haptics_enabled = false
    controller.arterial_confirm()
    controller.goal_complete()
    controller.tier_up()
    controller.widened()
    controller.demolished()
    controller.insufficient_funds()
    _require(controller.to_payload().has("sfx_volume"), "payload shape")
    root.queue_free()
    print("FEEDBACK_CONTROLLER_OK")
    quit(0)

func _require(condition: bool, label: String) -> void:
    if condition:
        return
    push_error("FEEDBACK_CONTROLLER_FAILED: %s" % label)
    quit(1)
