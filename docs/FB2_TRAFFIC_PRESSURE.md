# FB-2 — Traffic Pressure & Recovery

Status: implementation target

## Player-facing rule
Traffic is a strategic pressure, not a microscopic vehicle simulator. A road network can have enough nominal asphalt and still perform poorly when it is fragmented, dead-end-heavy or lacks alternate routes.

## Inputs
- trip demand from population and jobs;
- total road capacity;
- main-road share;
- widening;
- connected components;
- dead ends;
- intersections;
- cycle/redundancy count.

## Consequences
Severe traffic reduces happiness, operating income and autonomous growth through the existing demand/growth loop.

## Recovery actions
- connect separated road groups;
- create alternate routes/loops;
- add a new main road to increase useful capacity;
- widen overloaded main roads;
- use the traffic-oriented city policy.

## Guardrail
Traffic pressure may materially slow a city, but ordinary play must retain a practical recovery path. FB-2 does not add unrecoverable gridlock or hidden per-vehicle pathfinding.
