extends SceneTree

const SOURCE := "res://assets/app/machi-loop-icon.svg"
const OUTPUTS := {
    192: "res://build/web/machi-loop-icon-v2-192.png",
    512: "res://build/web/machi-loop-icon-v2-512.png",
}

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var file := FileAccess.open(SOURCE, FileAccess.READ)
    if file == null:
        push_error("ICON_GENERATION_FAILED: cannot open source SVG")
        quit(1)
        return
    var svg_text := file.get_as_text()
    file.close()

    for size in OUTPUTS.keys():
        var image := Image.new()
        var err := image.load_svg_from_string(svg_text, float(size) / 1024.0)
        if err != OK:
            push_error("ICON_GENERATION_FAILED: SVG rasterize error %s for %s" % [err, size])
            quit(1)
            return
        image.resize(size, size, Image.INTERPOLATE_LANCZOS)
        err = image.save_png(OUTPUTS[size])
        if err != OK:
            push_error("ICON_GENERATION_FAILED: PNG save error %s for %s" % [err, size])
            quit(1)
            return

    print("WEB_ICONS_OK")
    quit(0)
