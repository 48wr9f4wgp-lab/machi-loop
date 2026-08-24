class_name FtueModel
extends RefCounted

const DRAW_ROAD: int = 0
const WATCH_GROWTH: int = 1
const BUILD_TO_POLICY: int = 2
const CHOOSE_POLICY: int = 3
const COMPLETE: int = 4

static func infer_stage(arterial_cells: int, population: int, policy_id: int, city_level: int) -> int:
    if policy_id > 0 or city_level >= 2:
        return COMPLETE
    if population >= 26:
        return CHOOSE_POLICY
    if population > 0:
        return BUILD_TO_POLICY
    if arterial_cells >= 6:
        return WATCH_GROWTH
    return DRAW_ROAD

static func normalize(saved_stage: int, arterial_cells: int, population: int, policy_id: int, city_level: int) -> int:
    var inferred: int = infer_stage(arterial_cells, population, policy_id, city_level)
    return clampi(maxi(saved_stage, inferred), DRAW_ROAD, COMPLETE)

static func title(stage: int) -> String:
    match stage:
        DRAW_ROAD:
            return "幹線道路を6マス引く"
        WATCH_GROWTH:
            return "街の自動成長を見る"
        BUILD_TO_POLICY:
            return "人口26まで街を育てる"
        CHOOSE_POLICY:
            return "最初の都市方針を選ぶ"
        _:
            return "街づくり開始"

static func detail(stage: int) -> String:
    match stage:
        DRAW_ROAD:
            return "緑の土地をドラッグ。生活道路と建物は街が自動でつくる。"
        WATCH_GROWTH:
            return "道路沿いに建物が生え、人口と収入が増える。"
        BUILD_TO_POLICY:
            return "都市需要の住・商・工を見ながら、次の成長を待つ。"
        CHOOSE_POLICY:
            return "都市方針をタップ。住宅・雇用・交通から街の方向性を決める。"
        _:
            return "あとは都市の問題を道路と政策で解決する。"
