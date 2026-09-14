class_name FeedbackSettings
extends RefCounted

var sfx_enabled: bool = true
var sfx_volume: float = 0.80
var haptics_enabled: bool = true

func apply_payload(payload: Dictionary) -> void:
    sfx_enabled = bool(payload.get("sfx_enabled", true))
    sfx_volume = clampf(float(payload.get("sfx_volume", 0.80)), 0.0, 1.0)
    haptics_enabled = bool(payload.get("haptics_enabled", true))

func to_payload() -> Dictionary:
    return {
        "sfx_enabled": sfx_enabled,
        "sfx_volume": sfx_volume,
        "haptics_enabled": haptics_enabled
    }
