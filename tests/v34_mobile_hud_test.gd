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

    # Device-visible Vertical Slice copy is a font-subset contract. Cover the
    # complete city-birth and recovery wording, not only the final banners.
    for required: String in [
        "AXIVA",
        "RESET?",
        "最初の家が建ちました",
        "最初の家から、街が広がります",
        "生活道路が伸びています",
        "生活道路が自動で伸びています",
        "生活道路が伸びる",
        "人の流れに商業が反応しています",
        "商業が反応",
        "街が生まれました",
        "この道に交通が集中しています",
        "新しい道へ交通が流れ始めています",
        "新しい道へ交通が分散中",
        "交通が分散しました",
        "交通が分散し、街が動き始めました",
        "道一本で街の流れが変わった",
        "街の流れが変わった"
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
