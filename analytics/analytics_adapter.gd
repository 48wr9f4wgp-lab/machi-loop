extends RefCounted

# Default analytics provider. Intentionally performs no network or disk I/O.
# A real provider must implement the same send_event contract and is a separate approval decision.

func provider_name() -> String:
    return "noop"

func send_event(_event_name: String, _properties: Dictionary) -> bool:
    return true
