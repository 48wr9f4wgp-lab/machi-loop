class_name FeedbackController
extends Node

var settings: FeedbackSettings = FeedbackSettings.new()
var audio: AudioFeedback
var haptics: HapticsAdapter

func _ready() -> void:
    audio = AudioFeedback.new()
    add_child(audio)
    audio.setup(settings)
    haptics = HapticsAdapter.new(settings)

func apply_payload(payload: Dictionary) -> void:
    settings.apply_payload(payload)

func to_payload() -> Dictionary:
    return settings.to_payload()

func arterial_confirm() -> void:
    audio.play("arterial")
    haptics.light()

func goal_complete() -> void:
    audio.play("goal")
    haptics.medium()

func tier_up() -> void:
    audio.play("tier")
    haptics.strong()

func widened() -> void:
    audio.play("widen")
    haptics.light()

func demolished() -> void:
    audio.play("demolish")
    haptics.light()

func insufficient_funds() -> void:
    audio.play("insufficient")
    haptics.medium()
