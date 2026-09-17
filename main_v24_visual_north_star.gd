extends "res://main_v23_core_experience.gd"

# MACHI LOOP v0.24 — Visual North Star foundation.
# Art Bible v1.0 implementation step: city-dominant framing, coherent touch
# hitboxes, restrained HUD, warm stylized-realism palette and camera focus.
# Simulation semantics remain authoritative in the inherited Functional Build.

const V24_TOP_H: float = 78.0
const V24_BOTTOM_H: float = 92.0
const V24_MARGIN: float = 8.0

func _ready() -> void:
    super._ready()
    _v24_apply_lighting()
    _v24_apply_camera()
    queue_redraw()

# The old layout reserved large dashboard bands and sized the world to a small
# cell-perfect rectangle. v2 instead lets the 3D city own almost the full
# portrait canvas; ray picking already maps through board_rect into the 3D view.
func _reflow() -> void:
    var size: Vector2 = get_viewport_rect().size
    var board_top: float = V24_TOP_H + V24_MARGIN
    var board_bottom: float = size.y - V24_BOTTOM_H - V24_MARGIN
    var board_w: float = maxf(220.0, size.x - V24_MARGIN * 2.0)
    var board_h: float = maxf(320.0, board_bottom - board_top)
    board_origin = Vector2(V24_MARGIN, board_top)
    board_rect = Rect2(board_origin, Vector2(board_w, board_h))
    cell_size = maxf(12.0, minf(board_w / float(GRID_W), board_h / float(GRID_H)))
    _layout_tools(size)
    if is_instance_valid(v10_viewport):
        _v10_update_viewport_size()
    if is_instance_valid(v10_camera):
        _v24_apply_camera()
    queue_redraw()

# Visible tool geometry and touch geometry are now the same three rectangles.
# The old invisible fourth PAUSE hit target is intentionally removed.
func _layout_tools(size: Vector2) -> void:
    tool_rects.clear()
    var gap: float = 8.0
    var side: float = 12.0
    var button_w: float = (size.x - side * 2.0 - gap * 2.0) / 3.0
    var button_h: float = 54.0
    var y: float = size.y - V24_BOTTOM_H + 16.0
    tool_rects[Tool.ROAD] = Rect2(side, y, button_w, button_h)
    tool_rects[Tool.WIDEN] = Rect2(side + button_w + gap, y, button_w, button_h)
    tool_rects[Tool.BULLDOZE] = Rect2(side + (button_w + gap) * 2.0, y, button_w, button_h)

# Bypass legacy dashboard/service/settings interception. Gameplay touch authority
# in this slice is road / widen / remove plus direct interaction with the city.
func _pointer_down(pos: Vector2) -> void:
    for id: Variant in tool_rects.keys():
        var rect: Rect2 = tool_rects[id] as Rect2
        if rect.has_point(pos):
            current_tool = int(id)
            dragging = false
            drag_path.clear()
            _v10_sync_preview()
            queue_redraw()
            return

    var cell: Vector2i = _screen_to_cell(pos)
    if not _in_bounds(cell) or cell.x >= unlocked_cols:
        return

    if current_tool == Tool.ROAD:
        dragging = true
        drag_path = [cell]
        _v10_sync_preview()
        queue_redraw()
    elif current_tool == Tool.WIDEN:
        _widen(cell)
    elif current_tool == Tool.BULLDOZE:
        _bulldoze(cell)

func _simulation_tick() -> void:
    var before_cols: int = unlocked_cols
    super._simulation_tick()
    if unlocked_cols != before_cols:
        _v24_apply_camera()

# --- Legacy dashboard suppression -----------------------------------------
# These functions remain in the inherited simulation layers for compatibility,
# but the v2 city-as-UI presentation does not draw their permanent cards.

func _draw_header(_size: Vector2) -> void:
    pass

func _draw_toolbar(_size: Vector2) -> void:
    pass

func _draw_v06_first_action_coach() -> void:
    pass

func _draw_v05_traffic_hint() -> void:
    pass

func _v08_draw_goal_card() -> void:
    pass

func _v08_draw_goal_complete() -> void:
    pass

func _v09_draw_policy_chip() -> void:
    pass

func _v09_draw_policy_panel() -> void:
    pass

func _v15_draw_demand_panel() -> void:
    pass

func _v16_draw_traffic_diagnosis() -> void:
    pass

func _v17_draw_deficit_warning() -> void:
    pass

func _v18_draw_service_chip() -> void:
    pass

func _v18_draw_service_panel() -> void:
    pass

# Keep transient action feedback, but as a small toast over the city rather than
# a permanent or dashboard-sized banner.
func _draw_banner(_size: Vector2) -> void:
    if banner_timer <= 0.0:
        return
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font
    var text: String = _v11_banner_text(banner)
    var w: float = minf(board_rect.size.x - 24.0, 300.0)
    var rect: Rect2 = Rect2(board_rect.get_center().x - w * 0.5, board_rect.end.y - 50.0, w, 34.0)
    draw_rect(rect, Color(0.055, 0.13, 0.095, 0.90))
    draw_string(font, rect.position + Vector2(10.0, 22.0), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 9, Color("#F7FFF9"))

# --- City-first shell ------------------------------------------------------

func _v23_draw_city_first_shell() -> void:
    var size: Vector2 = get_viewport_rect().size
    var font: Font = v11_font if v11_font != null else ThemeDB.fallback_font

    var top: Rect2 = Rect2(0.0, 0.0, size.x, V24_TOP_H)
    draw_rect(top, Color("#F3F0E6"))
    draw_line(Vector2(0.0, top.end.y), Vector2(size.x, top.end.y), Color("#CFD5CB"), 1.0)
    draw_string(font, Vector2(16.0, 27.0), "MACHI LOOP", HORIZONTAL_ALIGNMENT_LEFT, 154.0, 17, Color("#173E30"))
    draw_string(font, Vector2(16.0, 51.0), _v23_stage_name(), HORIZONTAL_ALIGNMENT_LEFT, 190.0, 9, Color("#667D70"))
    draw_string(font, Vector2(size.x - 184.0, 29.0), "人口 %d" % population, HORIZONTAL_ALIGNMENT_RIGHT, 80.0, 10, Color("#214638"))
    draw_string(font, Vector2(size.x - 96.0, 29.0), "¥%d" % cash, HORIZONTAL_ALIGNMENT_RIGHT, 82.0, 10, Color("#214638"))

    var message: String = _v23_context_message()
    if not message.is_empty():
        var pill_w: float = minf(board_rect.size.x - 28.0, 330.0)
        var pill: Rect2 = Rect2(board_rect.get_center().x - pill_w * 0.5, board_rect.position.y + 12.0, pill_w, 32.0)
        draw_rect(pill, Color(0.055, 0.16, 0.115, 0.88))
        draw_string(font, pill.position + Vector2(10.0, 21.0), message, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 20.0, 9, Color("#F7FFF9"))

    var bottom: Rect2 = Rect2(0.0, size.y - V24_BOTTOM_H, size.x, V24_BOTTOM_H)
    draw_rect(bottom, Color("#F3F0E6"))
    draw_line(Vector2(0.0, bottom.position.y), Vector2(size.x, bottom.position.y), Color("#CFD5CB"), 1.0)
    _v23_draw_primary_tools(bottom, font)

func _v23_draw_primary_tools(_bottom: Rect2, font: Font) -> void:
    var labels: Dictionary = {
        Tool.ROAD: "幹線道路",
        Tool.WIDEN: "拡幅",
        Tool.BULLDOZE: "撤去"
    }
    for id: Variant in [Tool.ROAD, Tool.WIDEN, Tool.BULLDOZE]:
        if not tool_rects.has(id):
            continue
        var rect: Rect2 = tool_rects[id] as Rect2
        var active: bool = current_tool == int(id)
        var bg: Color = Color("#174B38") if active else Color("#E4E7DE")
        var fg: Color = Color("#FFFFFF") if active else Color("#274A3C")
        draw_rect(rect, bg)
        draw_rect(rect, Color("#8DA397") if not active else Color("#174B38"), false, 1.0)
        draw_string(font, rect.position + Vector2(6.0, 34.0), str(labels[id]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 11, fg)

# --- World framing / art direction ----------------------------------------

func _v10_draw_3d_board() -> void:
    if is_instance_valid(v10_viewport):
        draw_texture_rect(v10_viewport.get_texture(), board_rect, false)
    else:
        draw_rect(board_rect, Color("#A7B585"))
    draw_rect(board_rect, Color(0.12, 0.20, 0.15, 0.18), false, 1.0)

func _v10_setup_renderer() -> void:
    super._v10_setup_renderer()
    _v24_apply_lighting()
    _v24_apply_camera()

func _v10_create_materials() -> void:
    super._v10_create_materials()
    _v24_set_material_color("v22_ground", Color("#A2B383"))
    _v24_set_material_color("v22_ground_soft", Color("#AFBD91"))
    _v24_set_material_color("v22_ground_dark", Color("#8FA16F"))
    _v24_set_material_color("v22_arterial", Color("#2B2F2D"))
    _v24_set_material_color("v22_local", Color("#737971"))
    _v24_set_material_color("v22_curb", Color("#D1CFC2"))
    _v24_set_material_color("v22_lane", Color("#EDCA6B"))
    _v24_set_material_color("v22_stop", Color("#F0EEE3"))
    _v24_set_material_color("v22_tree_light", Color("#79A965"))
    _v24_set_material_color("v22_tree_mid", Color("#528953"))
    _v24_set_material_color("v22_tree_dark", Color("#386E45"))
    _v24_set_material_color("v21_stucco_white", Color("#F4F0E6"))
    _v24_set_material_color("v21_stucco_warm", Color("#EAD9C5"))
    _v24_set_material_color("v21_stucco_sage", Color("#DCE4D4"))
    _v24_set_material_color("v21_roof_terracotta", Color("#C96A50"))
    _v24_set_material_color("v21_roof_green", Color("#678E68"))
    _v24_set_material_color("v21_roof_gold", Color("#BE9855"))
    _v24_set_material_color("v21_trim_dark", Color("#46514C"))
    _v24_set_material_color("v21_water", Color("#68B9C9"))
    _v24_set_material_color("v21_hedge", Color("#477B4A"))
    _v24_set_material_color("v21_plaza", Color("#D9D6CA"))

func _v24_set_material_color(key: String, color: Color) -> void:
    if not v10_materials.has(key):
        return
    var material: StandardMaterial3D = v10_materials[key] as StandardMaterial3D
    if material != null:
        material.albedo_color = color

func _v24_apply_lighting() -> void:
    if not is_instance_valid(v10_world_root):
        return
    for child: Node in v10_world_root.get_children():
        if child is WorldEnvironment:
            var world_environment: WorldEnvironment = child as WorldEnvironment
            if world_environment.environment != null:
                world_environment.environment.background_color = Color("#DCE7D2")
                world_environment.environment.ambient_light_color = Color("#EEE9DA")
                world_environment.environment.ambient_light_energy = 0.66
        elif child is DirectionalLight3D:
            var light: DirectionalLight3D = child as DirectionalLight3D
            if light.shadow_enabled:
                light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
                light.light_color = Color("#FFF0D2")
                light.light_energy = 1.30
            else:
                light.rotation_degrees = Vector3(-66.0, 142.0, 0.0)
                light.light_color = Color("#C7DCD4")
                light.light_energy = 0.22

func _v24_apply_camera() -> void:
    if not is_instance_valid(v10_camera):
        return
    var open_center_x: float = -float(GRID_W) * 0.5 + float(unlocked_cols) * 0.5
    var target: Vector3 = Vector3(open_center_x, 0.0, 0.0)
    var aspect: float = 0.56
    if board_rect.size.y > 1.0:
        aspect = maxf(0.40, board_rect.size.x / board_rect.size.y)
    var height_need: float = float(GRID_H) * 1.06
    var width_need: float = (float(unlocked_cols) / aspect) * 1.06
    v10_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    v10_camera.size = maxf(height_need, width_need)
    v10_camera.position = target + Vector3(14.0, 19.0, 16.0)
    v10_camera.look_at(target, Vector3.UP)
