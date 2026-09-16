# MACHI LOOP — Third-Party License Inventory v1

Status: pre-RC inventory

## Godot Engine
Runtime/export engine; MIT. Before RC include appropriate Godot attribution/license access and review notices for the exact engine version.

## Noto Sans CJK JP subset
Japanese font generated in CI from Noto CJK. Before RC record exact package/font version, preserve required OFL notices/metadata, and re-audit if the font source changes.

## fontTools / CI infrastructure
fontTools is build-time subsetting only. GitHub Actions/godot-ci are development infrastructure, not intended runtime dependencies. Freeze relevant versions for reproducibility and confirm they are not bundled unnecessarily.

## Audio
Current feedback sounds are programmatically generated. Any future production SFX/BGM must record source, asset ID, commercial license, attribution, redistribution/modification rights and proof where applicable. Never extract competitor audio.

## Analytics / crash SDKs
Current architecture is provider-independent/no-op. If a provider is actually integrated, record exact SDK version, license, source, platform dependencies, privacy destination and Store disclosure impact.

## Art / models / textures
Current city kit is project-generated/procedural. Any external production asset requires provenance and commercial-rights entry.

## Release blocker
Any runtime asset/SDK with unknown commercial rights, missing required notice or unclear provenance blocks Release Candidate.
