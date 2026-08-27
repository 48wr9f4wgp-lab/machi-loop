extends RefCounted

# Default reporter for development and provider-free builds.
# Intentionally performs no network, disk, SDK, platform call, or event retention.

func provider_name() -> String:
    return "noop"

func send_error(_event: Dictionary) -> bool:
    return true
