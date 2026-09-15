# MACHI LOOP — Third-Party License Inventory v1

Status: pre-RC inventory
Verified: 2026-08-26

## 1. Godot Engine

Role: game engine/runtime/exported project.
License: MIT License.

Godot's official compliance documentation states that distributed games must comply with the engine license and recommends including the Godot license text or an acceptable license link/credits mechanism. Godot also contains compatible third-party components whose notices should be retained appropriately.

Official references:
- https://docs.godotengine.org/en/stable/about/complying_with_licenses.html
- https://godotengine.org/license/

### RC action
- [ ] Include Godot MIT attribution/license access in the shipped product or accompanying legal/credits material.
- [ ] Review Godot third-party notices for the exact exported engine version.
- [ ] Prefer obtaining license/copyright information from the exact engine build rather than an outdated copied list.

## 2. Noto Sans CJK JP subset

Role: Japanese game font.
Current build behavior: CI installs Debian `fonts-noto-cjk`, resolves `Noto Sans CJK JP`, then uses `fontTools.subset` and `assets/jp_charset.txt` to generate `generated/MachiLoopJP.otf`.

Current repository evidence:
- `.github/workflows/deploy-pages.yml` contains the font generation step.
- `assets/jp_charset.txt` contains the selected character set; the original font binary is not checked into `assets/`.

Upstream Noto CJK current releases are under the SIL Open Font License 1.1. The OFL allows embedding/modification/redistribution subject to its conditions, including preserving required copyright/license information when redistributed.

Official/upstream references:
- https://github.com/notofonts/noto-cjk
- https://openfontlicense.org/open-font-license-official-text/

### RC action
- [ ] Record the actual Noto package/font version used for final artifacts.
- [ ] Verify the generated subset retains appropriate license/copyright metadata.
- [ ] Bundle or expose the required OFL copyright/license notice with the final app/distribution.
- [ ] If the font source/build method changes, re-audit the license instead of assuming this entry still applies.

## 3. fontTools

Role: build-time font subsetting only.
It is installed in CI via the distribution package and is not intentionally bundled as a runtime SDK.

### RC action
- [ ] Confirm no unnecessary build-tool package is bundled into the game artifact.
- [ ] If build-distribution obligations change, record exact package/version/license.

## 4. GitHub Actions / godot-ci

Role: development/CI infrastructure, not intended as runtime product content.
Current CI uses:
- `actions/checkout`
- `barichello/godot-ci` container

### RC action
- [ ] Pin/freeze relevant build versions for reproducibility.
- [ ] Confirm they are not runtime dependencies in the shipped application.

## 5. Audio

v0.22A currently reports programmatically generated PCM feedback sounds. These are project-generated functional placeholders and do not rely on third-party sound files according to the Codex report.

If production SFX/BGM assets are introduced later:
- source/provider;
- exact asset identifier;
- license;
- commercial-use right;
- attribution requirement;
- redistribution restriction;
- modification right;
- proof/receipt where applicable
must be added here before RC.

Never extract sounds/music from competitor games.

## 6. Analytics / crash SDKs

Current intended remote foundation is provider-independent/no-op. No external provider SDK should be considered part of the final inventory until it is actually integrated.

If GameAnalytics or another provider is added:
- exact SDK version;
- license;
- repository/source;
- binary/platform dependencies;
- privacy/data destination;
- Store disclosure impact
must be added here.

## 7. Art / models / textures

The current production city visual kit is procedurally/generated from project code and primitives in the repository rather than a third-party art pack, based on the current remote structure. If external production models, textures, icons, VFX, or UI packs are introduced, each must receive a license/provenance entry.

## Release blocker

Any runtime asset/SDK with unknown commercial rights, missing required notice, or unclear provenance is a Release Block until resolved or removed.
