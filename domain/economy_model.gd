class_name EconomyModel
extends RefCounted

# Pure recurring-economy model for MACHI LOOP FB-3.
# Gross revenue is already adjusted by demand/policy/traffic before entering here.

static func calculate(
    gross_revenue: int,
    arterial_count: int,
    local_count: int,
    widened_count: int,
    city_level: int
) -> Dictionary:
    var road_maintenance: float = float(arterial_count) * 0.34
    road_maintenance += float(local_count) * 0.10
    road_maintenance += float(widened_count) * 0.24
    var city_overhead: float = float(maxi(0, city_level - 1)) * 1.5
    var operating_cost: int = maxi(0, int(round(road_maintenance + city_overhead)))
    var net_balance: int = gross_revenue - operating_cost

    var status: String = "healthy"
    if net_balance < 0:
        status = "deficit"
    elif net_balance <= 3:
        status = "tight"

    return {
        "gross_revenue": maxi(0, gross_revenue),
        "operating_cost": operating_cost,
        "net_balance": net_balance,
        "status": status
    }
