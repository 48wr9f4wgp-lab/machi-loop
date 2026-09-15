# ADR — Analytics Provider v1

Status: preferred provider selected in 2026-08-26 research; **external integration deferred** pending RC stability/privacy/current-SDK recheck.

## Architecture decision
Keep MACHI LOOP analytics provider-independent: versioned event schema, strict property validation, no-op provider default, no PII/full save payload, and analytics failure never blocking gameplay/save.

The prior research preferred GameAnalytics for game-specific telemetry and Godot support, but this is not authorization to connect or enable it. At RC, re-check the current SDK stability/version, license/binary impact, platform compatibility, privacy/Data safety impact and network-failure behavior. If unsuitable, retain the internal schema and swap provider without changing game/domain logic.

No external identity should be supplied by default. Any future pseudonymous retention identity requires a separate privacy/retention/deletion decision.

Provider keys/secrets must never be committed. Production provider connection requires explicit approval under EXTERNAL_APPROVAL_GATES_V1.md.
