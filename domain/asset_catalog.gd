class_name AssetCatalog
extends RefCounted

const RESIDENTIAL_VARIANTS: int = 8
const COMMERCIAL_VARIANTS: int = 8
const INDUSTRIAL_VARIANTS: int = 6

static func residential_variant(seed: int, city_tier: int) -> int:
    var pool: int = 5
    if city_tier >= 3:
        pool = 7
    if city_tier >= 4:
        pool = RESIDENTIAL_VARIANTS
    return posmod(seed, pool)

static func commercial_variant(seed: int, city_tier: int) -> int:
    var pool: int = 4
    if city_tier >= 3:
        pool = 6
    if city_tier >= 4:
        pool = COMMERCIAL_VARIANTS
    return posmod(seed, pool)

static func industrial_variant(seed: int, city_tier: int) -> int:
    var pool: int = 4
    if city_tier >= 3:
        pool = INDUSTRIAL_VARIANTS
    return posmod(seed, pool)

static func residential_is_apartment(variant: int) -> bool:
    return variant >= 5

static func commercial_is_highrise(variant: int) -> bool:
    return variant >= 5

static func production_counts() -> Dictionary:
    return {
        "residential": RESIDENTIAL_VARIANTS,
        "commercial": COMMERCIAL_VARIANTS,
        "industrial": INDUSTRIAL_VARIANTS
    }
