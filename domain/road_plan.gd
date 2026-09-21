extends RefCounted

# AXIVA: one authoritative quote for preview, confirmation and mutation.
# Cell values match main_mobile.gd; the integration test checks this contract.
static func quote(grid: Array, path: Array, open_cols: int, road_cost: int, prices: Dictionary) -> Dictionary:
    var result: Dictionary = {
        "valid": true, "cells": [], "acquired": [], "before": [],
        "build_count": 0, "acquisition_count": 0, "upgrade_count": 0,
        "construction_cost": 0, "acquisition_cost": 0, "total_cost": 0
    }
    var seen: Dictionary = {}
    for value: Variant in path:
        if not value is Vector2i:
            result["valid"] = false
            return result
        var p: Vector2i = value
        if p.y < 0 or p.y >= grid.size() or p.x < 0 or p.x >= open_cols:
            result["valid"] = false
            return result
        var row: Array = grid[p.y]
        if p.x >= row.size():
            result["valid"] = false
            return result
        if seen.has(p):
            continue
        seen[p] = true
        var cell: int = int(row[p.x])
        if cell < 0 or cell > 5:
            result["valid"] = false
            return result
        if cell == 1:
            continue
        result["cells"].append(p)
        result["before"].append(cell)
        if cell == 2:
            result["upgrade_count"] += 1
        elif cell >= 3:
            result["acquired"].append(p)
            result["acquisition_cost"] += int(prices.get(cell, 0))
    result["build_count"] = result["cells"].size()
    result["acquisition_count"] = result["acquired"].size()
    result["construction_cost"] = int(result["build_count"]) * road_cost
    result["total_cost"] = int(result["construction_cost"]) + int(result["acquisition_cost"])
    return result
