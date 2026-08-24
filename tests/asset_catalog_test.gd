extends SceneTree

const AssetCatalog = preload("res://domain/asset_catalog.gd")

func _init() -> void:
    var counts: Dictionary = AssetCatalog.production_counts()
    _require(int(counts["residential"]) >= 8, "production residential kit must expose at least 8 silhouettes")
    _require(int(counts["commercial"]) >= 8, "production commercial kit must expose at least 8 silhouettes")
    _require(int(counts["industrial"]) >= 6, "production industrial kit must expose at least 6 silhouettes")

    for seed: int in range(64):
        _require(AssetCatalog.residential_variant(seed, 1) < 5, "tier 1 must stay low-rise residential")
        _require(AssetCatalog.commercial_variant(seed, 1) < 4, "tier 1 must avoid commercial high-rise forms")
        _require(AssetCatalog.industrial_variant(seed, 1) < 4, "tier 1 must use the compact industrial kit")

    var saw_res_apartment: bool = false
    var saw_com_highrise: bool = false
    for seed: int in range(64):
        if AssetCatalog.residential_is_apartment(AssetCatalog.residential_variant(seed, 4)):
            saw_res_apartment = true
        if AssetCatalog.commercial_is_highrise(AssetCatalog.commercial_variant(seed, 4)):
            saw_com_highrise = true
    _require(saw_res_apartment, "tier 4 must introduce apartment silhouettes")
    _require(saw_com_highrise, "tier 4 must introduce commercial skyline silhouettes")

    print("ASSET_CATALOG_OK")
    quit(0)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("ASSET_CATALOG_FAILED: " + message)
    quit(1)
