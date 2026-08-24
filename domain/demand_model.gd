extends RefCounted

# Pure demand calculation for MACHI LOOP Functional Build.
# Outputs normalized 0–100 pressure values. No rendering, save or engine-scene dependency.

static func calculate(
    population: int,
    jobs: int,
    happiness: int,
    congestion: float,
    homes: int,
    commerce: int,
    industry: int
) -> Dictionary:
    var working_population: float = maxf(1.0, float(population) * 0.72)
    var employment_gap: float = float(jobs) - working_population
    var job_surplus_ratio: float = clampf(employment_gap / working_population, -1.0, 1.5)
    var unemployment_ratio: float = clampf(-employment_gap / working_population, 0.0, 1.0)

    var happiness_bonus: float = (float(happiness) - 70.0) * 0.55
    var traffic_penalty: float = maxf(0.0, congestion - 35.0) * 0.55

    # Housing pressure: available jobs pull residents in; unemployment and severe congestion push it down.
    var residential: float = 48.0
    residential += maxf(0.0, job_surplus_ratio) * 42.0
    residential -= unemployment_ratio * 34.0
    residential += happiness_bonus
    residential -= traffic_penalty
    if homes < 2:
        residential = maxf(residential, 88.0)

    # Commercial pressure: population creates spending demand, but excess commercial stock and traffic suppress it.
    var target_commerce: float = maxf(1.0, float(population) / 58.0)
    var commerce_gap_ratio: float = clampf((target_commerce - float(commerce)) / target_commerce, -1.0, 1.0)
    var commercial: float = 38.0
    commercial += commerce_gap_ratio * 34.0
    commercial += clampf(float(population) / 220.0, 0.0, 1.0) * 14.0
    commercial += maxf(0.0, happiness_bonus) * 0.35
    commercial -= traffic_penalty * 0.75

    # Industrial pressure is primarily a job-creation pressure, with oversupply and traffic as brakes.
    var target_industry: float = maxf(1.0, float(population) / 72.0)
    var industry_gap_ratio: float = clampf((target_industry - float(industry)) / target_industry, -1.0, 1.0)
    var industrial: float = 34.0
    industrial += industry_gap_ratio * 28.0
    industrial += unemployment_ratio * 44.0
    industrial -= maxf(0.0, job_surplus_ratio) * 18.0
    industrial -= traffic_penalty * 0.65

    return {
        "residential": int(round(clampf(residential, 0.0, 100.0))),
        "commercial": int(round(clampf(commercial, 0.0, 100.0))),
        "industrial": int(round(clampf(industrial, 0.0, 100.0)))
    }

static func highest(demand: Dictionary) -> String:
    var residential: int = int(demand.get("residential", 0))
    var commercial: int = int(demand.get("commercial", 0))
    var industrial: int = int(demand.get("industrial", 0))
    if residential >= commercial and residential >= industrial:
        return "residential"
    if commercial >= industrial:
        return "commercial"
    return "industrial"
