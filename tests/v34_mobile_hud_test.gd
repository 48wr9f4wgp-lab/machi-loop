extends SceneTree

const GameClass = preload("res://main_v34_mobile_hud.gd")
const CHARSET_PATH: String = "res://assets/jp_charset.txt"

func _init() -> void:
    var game = GameClass.new()
    game.board_rect = Rect2(8.0, 86.0, 414.0, 740.0)

    var hud: Rect2 = game._v34_hud_rect()
    var context: Rect2 = game._v34_context_rect()
    var reset: Rect2 = game._v33_reset_rect()

    _expect(game.board_rect.encloses(hud), "HUD escaped city viewport")
    _expect(game.board_rect.encloses(context), "context message escaped city viewport")
    _expect(hud.encloses(reset), "RESET must live inside safe HUD overlay")
    _expect(not reset.intersects(context), "RESET overlaps context message")

    var charset: String = FileAccess.get_file_as_string(CHARSET_PATH)
    _expect(not charset.is_empty(), "Japanese subset charset missing")
    for required: String in [
        "AXIVA",
        "RESET?",
        "この道に交通が集中しています",
        "集落が生まれています",
        "街が動きはじめました",
        "街が生まれました"
    ]:
        for ch: String in required:
            _expect(charset.contains(ch), "font subset missing character: " + ch + " from " + required)

    print("V34_MOBILE_HUD_OK")
    game.free()
    quit(0)

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("V34_MOBILE_HUD_FAILED: " + message)
    quit(1)
