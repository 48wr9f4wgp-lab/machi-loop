# FB-4 — High-Level City Services

Status: implementation target

## Interaction model
City services are strategic city-wide toggles, not repetitive facility placement. They unlock from city level 2 and can be activated/deactivated from one management panel.

## Services
- Mobility / 交通支援: +15% road capacity, recurring cost 4.
- Safety / 安全: +5 happiness, recurring cost 3.
- Education / 教育: +10 commercial demand and +8% gross revenue, recurring cost 4.
- Green / 緑化: +10 residential demand, +3 happiness, -4 industrial demand, recurring cost 3.

## Economy
Each inactive→active transition costs 140 cash. Deactivation is free. Recurring service costs flow through the FB-3 operating balance, so activating every benefit creates budget pressure.

## Persistence
Service state is durable state and upgrades the save envelope to schema v4 with existing checksum, atomic replacement, backup recovery and v3/v2/v1 migration.

## Guardrails
- no service requires placing one building per neighborhood;
- each service must visibly affect at least one city metric or growth pattern;
- all services may be turned off to recover operating budget;
- service effects cannot create an unrecoverable city state.
