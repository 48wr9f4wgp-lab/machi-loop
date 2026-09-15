# MACHI LOOP — External Approval Gates v1

Status: project safety boundary

A request to continue development does not authorize the following.

## Explicit user approval required
- App Store / Google Play public submission or production rollout.
- Activating paid sales/customer payments.
- Purchasing services or entering paid analytics/crash/hosting/asset/audio/SaaS contracts.
- Connecting production telemetry that starts external data collection.
- Uploading real user/save data externally.
- Destructive production/user-data operations or force-rewriting canonical history.
- Removing/rotating signing credentials without recovery plan.

## Development actions allowed within scope
Feature branches, test builds, automated tests, PRs, docs, static analysis, no-op/provider abstractions, local performance measurement, authorized private device testing, and preparation of Store copy/screenshots/checklists without submission.

“Continue”, “finish” or “release-ready” means prepare and validate a candidate; it does not authorize public submission, paid activation, contracts or destructive data changes.
