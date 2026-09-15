# MACHI LOOP — External Approval Gates v1

Status: project safety boundary

The following actions are **not** implied by a request to continue development and must not be executed automatically.

## Explicit user approval required

### Public distribution
- Submit an App Store build for public review/release.
- Submit a Google Play build for public production release.
- Make a previously private/staging distribution public.
- Expand a staged rollout to production users when that creates external impact.

### Money / contracts
- Activate a paid live app price or start accepting customer payments.
- Purchase Apple/Google/developer services on the user's behalf.
- Enter a paid analytics, crash-reporting, hosting, asset, audio, or SaaS contract.
- Enable paid advertising/UA campaigns.

### External data/services
- Create or connect a production analytics workspace/provider when doing so starts external data collection, unless the user has explicitly approved that integration.
- Enable crash telemetry to a third-party production endpoint.
- Upload real user/save data to an external service.

### Destructive / irreversible repository or data operations
- Delete production/user data.
- Force-push/rewind canonical history where existing work can be lost.
- Delete the only copy of a save migration/recovery fixture or release artifact.
- Rotate/remove signing credentials without an explicit recovery plan.

## Development actions that do not require a separate approval

When consistent with current task scope and project rules:
- feature branches;
- local/test builds;
- automated tests;
- draft PRs;
- documentation;
- static analysis;
- no-op/provider abstractions;
- local performance measurement;
- private device install/testing using already-authorized local credentials;
- preparing Store copy/screenshots/checklists without submitting them.

## AI handoff rule

Every Codex task packet that approaches Store/provider/release work must restate the stop condition. “Continue,” “finish,” or “make it release-ready” means prepare and validate a candidate; it does not authorize public submission, paid activation, contracts, or destructive data changes.
