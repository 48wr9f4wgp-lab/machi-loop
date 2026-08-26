# MACHI LOOP — Production Audio / Haptics Plan

Last verified: 2026-08-26
Status: production target; v0.22A runtime PCM remains an implementation placeholder until device listening tests
Scope: mobile-first Web/PWA development surface, native iOS/Android production path

## Objective

MACHI LOOP's core interaction is not a generic menu flow. The player commits a main road, observes autonomous city growth, solves pressure, completes city goals, and reaches larger city tiers. Audio/haptics must reinforce that value hierarchy without turning repeated city management into noise.

Feedback sequence:

`input → immediate acknowledgement → result → audio/haptic reinforcement → reward recognition → next action cue`

Important states must remain understandable with sound and haptics disabled.

## Feedback hierarchy

### Tier 1 — Navigation
Examples:
- settings open/close
- simple UI toggle
- non-critical panel interaction

Target:
- very short/subtle click if used
- normally no haptic or very light transient only
- never compete with gameplay/reward sounds

### Tier 2 — Work / city edit
Examples:
- main-road commit
- road widen
- bulldoze

Target:
- fast confirmation, roughly 80–220 ms for frequent operations
- road commit: positive but restrained construction confirmation
- widen: related sound family with upward/capacity cue
- bulldoze: short downward/removal cue
- light haptic where supported

Road editing can happen repeatedly, so strong haptics or long sounds are prohibited here.

### Tier 3 — Reward
Examples:
- city goal complete
- meaningful unlock

Target:
- recognizably more valuable than road editing
- roughly 200–450 ms audio phrase
- medium haptic transient
- visual reward and sound start should be tightly synchronized

### Tier 4 — Major reward
Examples:
- city tier up
- major district/city milestone

Target:
- strongest positive feedback in normal progression
- roughly 350–700 ms sting, still short enough for repeated mobile play
- strong but short haptic transient
- presentation must remain below cinematic interruption levels

### Warning / blocked action
Examples:
- insufficient cash
- invalid/locked action where explicit feedback is needed

Target:
- sonically distinct from rewards
- short low warning/error cue
- no strong haptic by default
- never rely on red/color alone; text/icon/visual state must explain the failure

## v0.22A placeholder policy

The runtime-generated PCM SFX in v0.22A are acceptable for functional verification because they prove:
- event routing
- ordering
- cooldown/duplicate suppression
- settings behavior
- save persistence
- browser playback

They are **not automatically production-final audio**.

Before Release Candidate, each sound must pass real speaker/headphone listening and category consistency review. If synthesized PCM sounds thin, fatiguing, click/pop, or cause first-use hitch, replace them with authored or properly licensed production assets.

## Production asset policy

Allowed:
- original authored SFX
- commissioned SFX
- generated sound for which commercial rights are clearly established
- commercial/royalty-free libraries whose license explicitly allows the intended distribution

Not allowed:
- extracting audio from other games/apps
- unclear-license files
- copying recognizable competitor sound motifs
- shipping temporary/dev sounds because tests merely pass

Keep a source/license record for every external production audio asset.

## Mix targets

Relative priority:
1. major reward / critical warning
2. goal reward
3. road-edit confirmation
4. navigation
5. ambient city layer
6. music bed

Principles:
- frequent road actions must not be louder than milestone rewards
- avoid multiple full-volume sounds stacking in the same feedback batch
- preserve the v0.22A event order: action result → goal reward → tier reward
- cooldown/deduplication stays part of production behavior
- avoid clipping when action + reward events coincide

Exact LUFS/dB targets are deferred until real production assets exist; do not invent precision before listening measurement.

## Haptics target

Semantic map:
- navigation: none / very light
- road commit: light
- widen/bulldoze: light
- city goal complete: medium
- city tier up: strong transient
- insufficient cash: none by default

Rules:
- `less is more`
- importance × frequency determines strength
- repeated frequent actions never use strong vibration
- same semantic event uses the same haptic family
- visual/audio/haptic timing should feel causally linked
- haptics OFF must fully suppress physical output
- Web unsupported path remains safe no-op

The current adapter abstraction should be preserved. Native iOS/Android implementation may improve the physical output later without changing game/domain logic.

## Accessibility

Required:
- all critical success/failure states remain visually understandable with SFX OFF
- no critical information is haptic-only
- SFX ON/OFF
- Haptics ON/OFF
- later music integration should add Music ON/OFF independently
- reduced-motion support is handled in the broader accessibility pass

## Device validation matrix

### Web/PWA
- iPhone Safari/home-screen build speaker
- headphones/earbuds
- SFX ON/OFF and reload persistence
- confirm no audio node growth or repeated overlap
- Web haptics no-op remains error-free

### Android native
- at least one representative mid-range physical device
- speaker + headphones
- haptic strength hierarchy
- background/resume behavior
- verify required vibration configuration/permission in actual package

### iOS native
- physical iPhone required
- speaker + headphones
- compare light/medium/strong semantic feel
- background/resume/audio-session behavior
- confirm frequent road actions do not become irritating

## Game-feel audit for key events

Score each event 0–10 on:
- input response
- visual confirmation
- sound clarity
- haptic appropriateness
- reward/value clarity
- satisfaction
- speed
- next-action clarity
- consistency
- accessibility

Anything below 8/10 remains a polish task.

Initial priority:
1. main-road commit
2. city goal complete
3. city tier up
4. widen
5. bulldoze
6. insufficient cash

## Performance constraints

For each feedback asset/effect track:
- duration
- trigger frequency
- maximum simultaneous count
- audio memory
- first-use decode/generation cost
- haptic call frequency

Hard risk:
- visible frame hitch on first SFX
- unbounded AudioStreamPlayer/node growth
- persistent audio after scene/app lifecycle transition
- haptic spam during repeated road edits

## Release acceptance

Audio/Haptics is not production-complete until:
- real-device listening performed
- native haptics tested where applicable
- frequent actions are non-fatiguing
- value hierarchy is obvious without being excessive
- SFX/Haptics settings persist
- sound/haptic disabled modes preserve gameplay clarity
- no license ambiguity
- no material performance regression
- automated Feedback fixtures continue to pass
