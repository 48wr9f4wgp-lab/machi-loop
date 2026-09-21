extends "res://main.gd"
# Current entry point with persistence isolated. No input, transaction, traffic,
# growth or renderer overrides: regression tests must exercise the real game.
func _v30_detect_fresh_session() -> bool:
    return true

func _v37_detect_recovery_session() -> bool:
    return false
