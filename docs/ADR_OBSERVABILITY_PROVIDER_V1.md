# ADR — Observability / Crash Reporting Strategy v1

Status: provider strategy selected; final native-provider enablement deferred to RC evidence.

MACHI LOOP keeps a provider-agnostic observability foundation: bounded semantic breadcrumbs, strict code/severity/context allowlists, PII/secret rejection, no-op reporter default, and no gameplay/save dependency on reporting success.

## Decision
Prefer a single provider footprint if the final approved analytics provider can supply sufficient crash/error evidence. If RC/native testing cannot provide required crash-free/session, ANR, stack/symbolication or platform reliability evidence, evaluate a dedicated native crash provider as a separate decision rather than an automatic dependency.

Approved diagnostic concepts include release version, platform class, screen, city tier, save schema, bounded actions and normalized error code/severity/stage. Never attach identity, precise location, free-form user text, full save state, credentials/secrets or unbounded logs.

Before production reporting: record exact SDK/version/license/cost, verify native/offline behavior, inventory final data fields/destinations, update Store privacy disclosures, test controlled failure, and obtain required explicit approval.
