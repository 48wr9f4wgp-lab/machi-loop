extends RefCounted

var sent_events: Array[Dictionary] = []

func send_error(event: Dictionary) -> bool:
    # Development default: accept the normalized event locally but perform no
    # network, disk, SDK, or platform call. Tests may inspect sent_events.
    sent_events.append(event.duplicate(true))
    return true

func clear() -> void:
    sent_events.clear()
