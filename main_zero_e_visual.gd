extends "res://main_zero_e_road_choice.gd"

# Keep the ZERO E palette on the existing, device-tested renderer. The first
# visual trial's runtime ground texture, extra per-parcel meshes and closer
# camera coincided with a black-only frame on iPhone; restore the inherited
# geometry and framing until that rendering path can be checked on device.
func _v10_create_materials() -> void:
    super._v10_create_materials()
    if not zero_e_session:
        return
    _v24_set_material_color("v22_ground", Color("#A9B78C"))
    _v24_set_material_color("v22_ground_soft", Color("#B2BF94"))
    _v24_set_material_color("v22_ground_dark", Color("#98AB7B"))
    _v24_set_material_color("v22_arterial", Color("#3B4140"))
    _v24_set_material_color("v22_local", Color("#666D68"))
    _v24_set_material_color("v22_curb", Color("#D8D1BD"))
    _v24_set_material_color("v22_lane", Color("#EDCF7D"))
    _v24_set_material_color("v21_stucco_white", Color("#F7ECD8"))
    _v24_set_material_color("v21_stucco_warm", Color("#E8D3B7"))
    _v24_set_material_color("v21_stucco_sage", Color("#DAE3CF"))
    _v24_set_material_color("v21_roof_terracotta", Color("#AD6850"))
    _v24_set_material_color("v21_roof_green", Color("#596E58"))
    _v24_set_material_color("v21_roof_gold", Color("#A77C53"))
