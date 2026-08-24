class_name ServiceModel
extends RefCounted

# Pure high-level city-service effects for MACHI LOOP FB-4.
# Services are city-wide strategic levers, not manually placed buildings.

static func summarize(mobility: bool, safety: bool, education: bool, green: bool) -> Dictionary:
    var operating_cost: int = 0
    var road_capacity_multiplier: float = 1.0
    var happiness_bonus: int = 0
    var residential_demand_bonus: int = 0
    var commercial_demand_bonus: int = 0
    var industrial_demand_bonus: int = 0
    var revenue_multiplier: float = 1.0

    if mobility:
        operating_cost += 4
        road_capacity_multiplier *= 1.15
    if safety:
        operating_cost += 3
        happiness_bonus += 5
    if education:
        operating_cost += 4
        commercial_demand_bonus += 10
        revenue_multiplier *= 1.08
    if green:
        operating_cost += 3
        happiness_bonus += 3
        residential_demand_bonus += 10
        industrial_demand_bonus -= 4

    return {
        "operating_cost": operating_cost,
        "road_capacity_multiplier": road_capacity_multiplier,
        "happiness_bonus": happiness_bonus,
        "residential_demand_bonus": residential_demand_bonus,
        "commercial_demand_bonus": commercial_demand_bonus,
        "industrial_demand_bonus": industrial_demand_bonus,
        "revenue_multiplier": revenue_multiplier
    }
