class_name HapticsAdapter
extends RefCounted

var settings: FeedbackSettings

func _init(p_settings: FeedbackSettings) -> void:
    settings = p_settings

func light() -> void:
    _pulse(18, 0.35)

func medium() -> void:
    _pulse(32, 0.55)

func strong() -> void:
    _pulse(55, 0.80)

func _pulse(duration_ms: int, amplitude: float) -> void:
    if settings == null or not settings.haptics_enabled:
        return
    if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
        return
    Input.vibrate_handheld(duration_ms, amplitude)
