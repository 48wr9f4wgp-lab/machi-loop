class_name ProgressionModel
extends RefCounted

const TIER_THRESHOLDS: Array[int] = [0, 90, 200, 360, 650, 1000]
const TIER_NAMES: Array[String] = ["郊外", "小都市", "地方都市", "中核都市", "大都市", "メトロポリス"]
const UNLOCKED_COLS: Array[int] = [8, 11, 14, 16, 16, 16]
const SERVICE_SLOTS: Array[int] = [0, 1, 2, 3, 4, 4]

static func tier_for_population(population: int) -> int:
    var tier: int = 1
    for i: int in range(TIER_THRESHOLDS.size()):
        if population >= TIER_THRESHOLDS[i]:
            tier = i + 1
    return clampi(tier, 1, 6)

static func tier_name(tier: int) -> String:
    return TIER_NAMES[clampi(tier, 1, 6) - 1]

static func unlocked_cols(tier: int) -> int:
    return UNLOCKED_COLS[clampi(tier, 1, 6) - 1]

static func service_slots(tier: int) -> int:
    return SERVICE_SLOTS[clampi(tier, 1, 6) - 1]

static func threshold_for_tier(tier: int) -> int:
    return TIER_THRESHOLDS[clampi(tier, 1, 6) - 1]

static func next_target(tier: int) -> int:
    if tier >= 6:
        return TIER_THRESHOLDS[-1]
    return TIER_THRESHOLDS[tier]

static func progress_to_next(population: int, tier: int) -> float:
    if tier >= 6:
        return 1.0
    var current_threshold: int = threshold_for_tier(tier)
    var next_threshold: int = next_target(tier)
    return clampf(float(population - current_threshold) / float(maxi(1, next_threshold - current_threshold)), 0.0, 1.0)

static func metropolitan_service_cost_multiplier(tier: int) -> float:
    return 0.75 if tier >= 6 else 1.0
