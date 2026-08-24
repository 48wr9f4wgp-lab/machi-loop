extends "res://main_v19_release.gd"

# MACHI LOOP v0.20 — Functional Build FB-6: final first-time user experience.
# One persistent instruction at a time: road -> growth/reward -> demand -> first policy decision.

const FtueModel = preload("res://domain/ftue_model.gd")
const V20_FTUE_SAVE_PATH: String = "user://machi_loop_ftue_v1.json"
const V20_FTUE_TEMP_PATH: String = "user://machi_loop_ftue_v1.tmp"
const V20_FTUE_SCHEMA: int = 1

var v20_ftue_stage: int = FtueModel.DRAW_ROAD

func _ready() -> void:
    super._ready()
    v20_ftue_stage = _v20_load_ftue_stage()
    _v20_refresh_ftue(false)
    queue_redraw()

func _exit_tree() -> void:
    _v20_save_ftue()
    super._exit_tree()

func _simulation_tick() -> void:
    super._simulation_tick()
    _v20_refresh_ftue(true)

func _commit_arterial() -> void:
    super._commit_arterial()
    _v20_refresh_ftue(true)

func _v09_select_policy(policy: int) -> void:
    var before: int = v09_policy
    super._v09_select_policy(policy)
    if v09_policy != before:
        _v20_refresh_ftue(true)

func _draw_v06_first_action_coach() -> void:
    if v20_ftue_stage != FtueModel.DRAW_ROAD:
        return
    _v20_draw_first_road_coach()

func _v08_draw_goal_card() -> void:
    if v20_ftue_stage < FtueModel.COMPLETE:
        _v20_draw_ftue_card()
        return
    super._v08_draw_goal_card()

func _v11_banner_text(source: String) -> String:
    if source == "FTUE COMPLETE":
        return "基本操作完了・ここからは自分の街を育てよう"
    return super._v11_banner_text(source)

func _v20_refresh_ftue(show_complete_toast: bool) -> void:
    var inferred: int = FtueModel.infer_stage(
        _count_cells(Cell.ARTERIAL),
        population,
        v09_policy,
        city_level
    )
    if inferred <= v20_ftue_stage:
        return
    var was_complete: bool = v20_ftue_stage >= FtueModel.COMPLETE
    v20_ftue_stage = inferred
    _v20_save_ftue()
    if show_complete_toast and not was_complete and v20_ftue_stage >= FtueModel.COMPLETE:
        _toast("FTUE COMPLETE")
    queue_redraw()

func _v20_draw_first_road_coach() -> void:
    var pulse: float = 0.5 + 0.5 * sin(v04_time * 3.0)
    var w: float = minf(board_rect.size.x - 30.0, 330.0)
    var card: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.position.y + 18.0, w, 82.0)
    draw_rect(Rect2(card.position + Vector2(0.0, 4.0), card.size), Color(0.05, 0.11, 0.08, 0.16))
    draw_rect(card, Color(0.055, 0.14, 0.105, 0.96))
    draw_rect(card, Color(0.44, 0.84, 0.64, 0.55 + pulse * 0.30), false, 2.0)
    draw_rect(Rect2(card.position, Vector2(5.0, card.size.y)), Color("#71D0A2"))
    draw_string(v11_font, card.position + Vector2(14.0, 24.0), "1  幹線道路を6マス引く", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 28.0, 13, Color("#F4FFF8"))
    draw_string(v11_font, card.position + Vector2(14.0, 46.0), "緑の土地をドラッグ", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 28.0, 10, Color("#BDE4D1"))
    draw_string(v11_font, card.position + Vector2(14.0, 66.0), "生活道路と建物は街が自動でつくる", HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 28.0, 9, Color("#93BFA9"))
    var y: float = card.position.y + 46.0
    var x2: float = card.end.x - 18.0
    draw_line(Vector2(x2 - 38.0, y), Vector2(x2, y), Color("#71D0A2"), 3.0)
    draw_line(Vector2(x2, y), Vector2(x2 - 8.0, y - 5.0), Color("#71D0A2"), 3.0)
    draw_line(Vector2(x2, y), Vector2(x2 - 8.0, y + 5.0), Color("#71D0A2"), 3.0)

func _v20_draw_ftue_card() -> void:
    var w: float = minf(board_rect.size.x - 24.0, 336.0)
    var h: float = 76.0
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.end.y - h - 10.0, w, h)
    draw_rect(Rect2(rect.position + Vector2(0.0, 3.0), rect.size), Color(0.04, 0.09, 0.07, 0.18))
    draw_rect(rect, Color(0.055, 0.14, 0.105, 0.96))
    draw_rect(rect, Color("#4B7B65"), false, 1.0)

    var step_number: int = clampi(v20_ftue_stage + 1, 1, 4)
    draw_string(v11_font, rect.position + Vector2(12.0, 16.0), "はじめの街づくり  %d/4" % step_number, HORIZONTAL_ALIGNMENT_LEFT, 180.0, 8, Color("#8FBCA5"))
    draw_string(v11_font, rect.position + Vector2(12.0, 38.0), FtueModel.title(v20_ftue_stage), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 13, Color("#F4FFF8"))
    draw_string(v11_font, rect.position + Vector2(12.0, 57.0), FtueModel.detail(v20_ftue_stage), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 8, Color("#B9DDCB"))

    var progress: float = _v20_stage_progress()
    var bar: Rect2 = Rect2(rect.position.x + 12.0, rect.end.y - 7.0, rect.size.x - 24.0, 3.0)
    draw_rect(bar, Color("#28483A"))
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color("#71D0A2"))

func _v20_stage_progress() -> float:
    match v20_ftue_stage:
        FtueModel.DRAW_ROAD:
            return clampf(float(_count_cells(Cell.ARTERIAL)) / 6.0, 0.0, 1.0)
        FtueModel.WATCH_GROWTH:
            return 0.25 if population <= 0 else 1.0
        FtueModel.BUILD_TO_POLICY:
            return clampf(float(population) / 26.0, 0.0, 1.0)
        FtueModel.CHOOSE_POLICY:
            return 0.75 if v09_policy == V09Policy.NONE else 1.0
        _:
            return 1.0

func _v20_load_ftue_stage() -> int:
    var inferred: int = FtueModel.infer_stage(_count_cells(Cell.ARTERIAL), population, v09_policy, city_level)
    if not FileAccess.file_exists(V20_FTUE_SAVE_PATH):
        return inferred

    var file: FileAccess = FileAccess.open(V20_FTUE_SAVE_PATH, FileAccess.READ)
    if file == null:
        return inferred
    var raw: String = file.get_as_text()
    file.close()

    var parsed: Variant = JSON.parse_string(raw)
    if not parsed is Dictionary:
        return inferred
    var root: Dictionary = parsed as Dictionary
    if int(root.get("schema_version", 0)) != V20_FTUE_SCHEMA:
        return inferred
    var payload_json: String = str(root.get("payload_json", ""))
    if payload_json.is_empty() or payload_json.sha256_text() != str(root.get("checksum", "")):
        return inferred
    var payload_variant: Variant = JSON.parse_string(payload_json)
    if not payload_variant is Dictionary:
        return inferred
    var payload: Dictionary = payload_variant as Dictionary
    return FtueModel.normalize(int(payload.get("stage", inferred)), _count_cells(Cell.ARTERIAL), population, v09_policy, city_level)

func _v20_save_ftue() -> void:
    var payload_json: String = JSON.stringify({"stage": v20_ftue_stage})
    var envelope: Dictionary = {
        "schema_version": V20_FTUE_SCHEMA,
        "payload_json": payload_json,
        "checksum": payload_json.sha256_text()
    }
    var file: FileAccess = FileAccess.open(V20_FTUE_TEMP_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(envelope))
    file.close()

    if FileAccess.file_exists(V20_FTUE_SAVE_PATH):
        DirAccess.remove_absolute(V20_FTUE_SAVE_PATH)
    DirAccess.rename_absolute(V20_FTUE_TEMP_PATH, V20_FTUE_SAVE_PATH)
