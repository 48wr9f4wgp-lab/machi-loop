extends "res://main_v11_ja.gd"

# MACHI LOOP v0.12 — Web/iPhone 3D camera reliability fix.
# The v0.10 camera called look_at() before entering the SceneTree. On Web this can leave
# the camera at its default orientation, rendering only the SubViewport background.

func _v10_setup_renderer() -> void:
    v10_viewport = SubViewport.new()
    v10_viewport.name = "City3DViewport"
    v10_viewport.own_world_3d = true
    v10_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    v10_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    v10_viewport.transparent_bg = false
    add_child(v10_viewport)

    v10_world_root = Node3D.new()
    v10_world_root.name = "City3DWorld"
    v10_viewport.add_child(v10_world_root)

    var world_environment: WorldEnvironment = WorldEnvironment.new()
    var environment: Environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#DDE8D8")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#DDE9DF")
    environment.ambient_light_energy = 0.72
    world_environment.environment = environment
    v10_world_root.add_child(world_environment)

    var sun: DirectionalLight3D = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
    sun.light_color = Color("#FFF1D6")
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    v10_world_root.add_child(sun)

    var fill: DirectionalLight3D = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-68.0, 138.0, 0.0)
    fill.light_color = Color("#B8D6C9")
    fill.light_energy = 0.28
    fill.shadow_enabled = false
    v10_world_root.add_child(fill)

    # Important: Camera3D must be inside the SceneTree before look_at() is evaluated.
    v10_camera = Camera3D.new()
    v10_camera.name = "CityCamera"
    v10_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    v10_camera.size = 29.0
    v10_camera.near = 0.1
    v10_camera.far = 120.0
    v10_world_root.add_child(v10_camera)
    v10_camera.position = Vector3(16.0, 22.0, 18.0)
    v10_camera.look_at(Vector3.ZERO, Vector3.UP)
    v10_camera.current = true

    v10_static_root = Node3D.new()
    v10_static_root.name = "StaticCity"
    v10_world_root.add_child(v10_static_root)

    v10_preview_root = Node3D.new()
    v10_preview_root.name = "RoadPreview"
    v10_world_root.add_child(v10_preview_root)

    v10_vehicle_root = Node3D.new()
    v10_vehicle_root.name = "Vehicles"
    v10_world_root.add_child(v10_vehicle_root)

    _v10_create_materials()
    _v10_update_viewport_size()
