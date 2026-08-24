class_name TrafficModel
extends RefCounted

# Pure strategic traffic-pressure model for MACHI LOOP Functional Build FB-2.
# The model intentionally avoids per-vehicle pathfinding. It converts trip demand,
# road capacity and network-shape metrics into a recoverable city-wide pressure.

static func calculate(
    population: int,
    jobs: int,
    raw_capacity: float,
    road_count: int,
    arterial_count: int,
    widened_count: int,
    intersections: int,
    dead_ends: int,
    components: int,
    cycle_count: int
) -> Dictionary:
    if road_count <= 0:
        return {
            "congestion": 0.0,
            "effective_capacity": 0.0,
            "network_factor": 0.0,
            "income_multiplier": 1.0,
            "happiness_delta": 0.0,
            "status": "none",
            "cause": "none"
        }

    var safe_components: int = maxi(1, components)
    var dead_end_ratio: float = float(dead_ends) / float(maxi(1, road_count))
    var intersection_ratio: float = float(intersections) / float(maxi(1, road_count))
    var arterial_ratio: float = float(arterial_count) / float(maxi(1, road_count))
    var widened_ratio: float = float(widened_count) / float(maxi(1, arterial_count))
    var redundancy: float = clampf(float(cycle_count) / 3.0, 0.0, 1.0)

    # Connected loops and intersections improve network usefulness; fragmented or
    # dead-end-heavy layouts waste nominal road capacity.
    var network_factor: float = 0.78
    network_factor += redundancy * 0.18
    network_factor += clampf(intersection_ratio * 2.8, 0.0, 0.12)
    network_factor += clampf(arterial_ratio * 0.20, 0.0, 0.08)
    network_factor += widened_ratio * 0.04
    network_factor -= clampf(dead_end_ratio * 0.32, 0.0, 0.16)
    network_factor -= float(safe_components - 1) * 0.18
    network_factor = clampf(network_factor, 0.42, 1.12)

    var effective_capacity: float = maxf(1.0, raw_capacity * network_factor)
    var trips: float = float(population) * 0.72 + float(jobs) * 0.32
    var congestion: float = clampf((trips / effective_capacity) * 100.0, 0.0, 160.0)

    var overload: float = maxf(0.0, congestion - 45.0)
    var income_multiplier: float = clampf(1.0 - maxf(0.0, congestion - 55.0) * 0.006, 0.55, 1.0)
    var happiness_delta: float = -overload * 0.32
    if safe_components > 1:
        happiness_delta -= float(safe_components - 1) * 2.5

    var status: String = "good"
    if congestion >= 75.0:
        status = "severe"
    elif congestion >= 52.0:
        status = "warning"

    var cause: String = "capacity"
    if safe_components > 1:
        cause = "disconnected"
    elif dead_end_ratio >= 0.28 and cycle_count == 0:
        cause = "dead_ends"
    elif cycle_count == 0 and road_count >= 8:
        cause = "no_redundancy"
    elif congestion < 52.0:
        cause = "none"

    return {
        "congestion": congestion,
        "effective_capacity": effective_capacity,
        "network_factor": network_factor,
        "income_multiplier": income_multiplier,
        "happiness_delta": happiness_delta,
        "status": status,
        "cause": cause
    }
