extends SceneTree
const Probe = preload("res://tests/zero_d_probe.gd")
const Model = preload("res://domain/zero_d_expansion.gd")
var checks: int = 0
var failures: int = 0
var paths: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(430,932)
    var game: Node = Probe.new()
    paths.assign([game.SAVE_PATH, game.V08_SAVE_BACKUP_PATH, game.V20_FTUE_SAVE_PATH])
    for path: String in paths:
        var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
        file.store_string("normal-save-sentinel:" + path)
        file.close()
    var save_before: String = fingerprint()
    root.add_child(game)
    await process_frame
    await process_frame
    game.set_process(false)
    for child: Node in game.get_children():
        if child is Timer:
            child.stop()
    require(game.zero_d_session and game.zero_session and not game.zero_c_session and not game.zero_b_session, "experiment isolation")
    require(game._zero_d_query_requests("?build=test&zero=d"), "D activation query")
    require(not game._zero_d_query_requests("?zero=dog") and not game._zero_d_query_requests("?zero=c"), "query collision")
    require(game.grid.size() == 44 and game.grid[0].size() == 32, "world area not four times larger")
    require(game.unlocked_cols == 32 and game.zero_landmark_count == 6, "full world/destinations unavailable")
    require(fingerprint() == save_before and not game._v07_load_city(), "startup touched normal saves")
    var default_game: Node = load("res://main.gd").new()
    require(default_game.GRID_W == 16 and default_game.GRID_H == 22, "instance size leaked into normal game")
    default_game.free()
    var initial_scale: float = game.v41_camera_size
    require(initial_scale < 40.0, "startup zoom shrank to entire expanded world")
    require(game._screen_to_cell(game._v27_project_cell(Model.HOME,0.0)) == Model.HOME, "initial cell picking")
    var grid_before: int = hash(game.grid)
    tap(game, game.tool_rects[game.D_MOVE].get_center())
    require(game.current_tool == game.D_MOVE, "move tool cannot be selected")
    var area: Rect2 = game._v41_world_area()
    var origin: Vector2 = area.get_center()
    var target_before: Vector3 = game.v41_camera_target
    touch(game,0,origin,true)
    drag(game,0,origin+Vector2(55,30))
    touch(game,0,origin+Vector2(55,30),false)
    require(game.v41_camera_target.distance_to(target_before)>0.1, "one-finger pan did not move")
    require(hash(game.grid)==grid_before and not game.dragging, "one-finger pan built a road")
    # Two fingers cancel a pending road and own pan/pinch until both lift.
    tap(game,game.tool_rects[game.Tool.ROAD].get_center())
    origin=area.get_center()
    touch(game,0,origin-Vector2(40,0),true)
    touch(game,1,origin+Vector2(40,0),true)
    drag(game,1,origin+Vector2(70,25))
    touch(game,1,origin+Vector2(70,25),false)
    drag(game,0,origin+Vector2(10,20))
    touch(game,0,origin+Vector2(10,20),false)
    require(hash(game.grid)==grid_before and game.v41_zoom_update_count>0, "pinch edited city or failed zoom")
    require(not game.dragging and game.v41_touches.is_empty(), "gesture latch remains")
    tap(game,game._zero_d_nav_rect(game.V41_OVERVIEW).get_center())
    require(game.v41_camera_size>initial_scale*1.5, "overview does not show a wider world")
    for p: Vector2i in [Vector2i(0,0),Vector2i(31,0),Vector2i(0,43),Vector2i(31,43)]:
        var screen: Vector2 = game._v27_project_cell(p,0.0)
        require(game._v41_world_area().has_point(screen), "overview hides corner %s" % p)
        require(game._screen_to_cell(screen)==p, "expanded corner picking %s" % p)
    require(game._zero_d_region_visible(4), "outer industrial district hidden in overview")
    tap(game,game._zero_d_region_rect(4).get_center())
    require(game.v41_camera_target.distance_to(game._v10_world_position(Model.ANCHORS[4],0))<0.01, "overview district focus failed")
    require(is_equal_approx(game.v41_camera_size,initial_scale) and hash(game.grid)==grid_before, "focus changed scale or edited")
    tap(game,game._zero_d_nav_rect(game.D_HOME).get_center())
    require(game.v41_camera_target.distance_to(game._v10_world_position(Model.HOME,0))<0.01, "return-to-town failed")
    # Compact iPhone layout: all six overview targets remain distinct/tappable.
    root.size=Vector2i(375,812)
    game._reflow()
    game._v41_show_overview()
    for i: int in range(6):
        require(game._zero_d_region_visible(i), "compact overview hides region %d" % i)
        for j: int in range(i+1,6):
            require(not game._zero_d_region_rect(i).intersects(game._zero_d_region_rect(j)), "overview destination labels overlap %d/%d" % [i,j])
    for action: int in game.tool_rects:
        require(game.tool_rects[action].size.y>=44.0 and game.tool_rects[action].size.x>=44.0, "compact tool target too small")
    root.size=Vector2i(430,932)
    game._reflow()
    game._zero_d_focus(Model.HOME)
    # Real projected touch draws beyond original bounds; no direct cell injection.
    road(game,Vector2i(8,22),Vector2i(18,22))
    road(game,Vector2i(18,12),Vector2i(18,22))
    require(game.zero_d_preferred==1, "reverse-drawn station road picked the wrong growth region")
    for i: int in range(48):
        tick(game)
        if i%12==0:
            await process_frame
    var commerce: int = game.zero_d_state["counts"][1]
    require(commerce>=12, "station direction failed commercial growth")
    var industry_before: int = game.zero_d_state["counts"][2]
    road(game,Vector2i(18,22),Vector2i(18,28))
    for i: int in range(48):
        tick(game)
        if i%12==0:
            await process_frame
    require(int(game.zero_d_state["counts"][2])>industry_before+10, "logistics direction failed industrial growth")
    var total_before: int = game.zero_d_state["buildings"].size()
    road(game,Vector2i(18,28),Vector2i(27,28))
    road(game,Vector2i(27,28),Vector2i(27,38))
    for i: int in range(48):
        tick(game)
        if i%12==0:
            await process_frame
    require(int(game.zero_d_state["counts"][4])>=12, "growth did not reach outer district")
    require(game.zero_d_state["buildings"].size()>total_before, "first destinations ended growth")
    var far_industry: bool = false
    for p: Vector2i in game.zero_d_state["buildings"]:
        if p.x>=16 and p.y>=22 and int(game.grid[p.y][p.x])==game.Cell.INDUSTRIAL:
            far_industry=true
    require(far_industry, "no genuine development outside old footprint")
    # Region land determines building type rather than a cosmetic destination.
    for p: Vector2i in game.zero_d_state["buildings"]:
        if Model.region_at(p)==1:
            require(int(game.grid[p.y][p.x])==game.Cell.COMMERCIAL, "station grew wrong class")
            break
    for count: int in game.zero_d_state["counts"]:
        require(count<=Model.REGION_LIMIT, "region exceeded bounded building budget")
    road(game,Vector2i(1,1),Vector2i(5,1))
    var disconnected_before: Array = game.grid[0].duplicate()
    for i: int in range(12):
        tick(game)
    require(game.grid[0]==disconnected_before and not game.zero_d_state["connected"].has(Vector2i(3,1)), "isolated road grew buildings")
    game._bulldoze(Model.HOME)
    require(game.zero_d_state["connected"].is_empty(), "deleted root retained connectivity")
    road(game,Model.HOME,Model.HOME+Vector2i.RIGHT)
    require(not game.zero_d_state["connected"].is_empty(), "root erasure cannot recover")
    game._v07_save_city()
    game._v20_save_ftue()
    game._v33_delete_persistent_city_state()
    require(fingerprint()==save_before, "D mutated normal city or tutorial")
    print("ZERO_D_COUNTS %s buildings=%d camera=%.2f" % [game.zero_d_state["counts"],game.zero_d_state["buildings"].size(),initial_scale])
    game.queue_free()
    await process_frame
    require(fingerprint()==save_before, "D exit touched saves")
    print("AXIVA_ZERO_D_RESULT checks=%d failures=%d" % [checks,failures])
    if failures==0:
        print("AXIVA_ZERO_D_OK")
    quit(0 if failures==0 else 1)

func tick(game: Node) -> void:
    game._simulation_tick()
    game._process(0.85)

func road(game: Node,a: Vector2i,b: Vector2i) -> void:
    game._zero_d_focus(Vector2i((a+b)/2))
    game.current_tool=game.Tool.ROAD
    var from: Vector2 = game._v27_project_cell(a,0)
    var to: Vector2 = game._v27_project_cell(b,0)
    require(game._v41_world_area().has_point(from) and game._v41_world_area().has_point(to), "road endpoints outside edit viewport")
    touch(game,0,from,true)
    drag(game,0,to)
    touch(game,0,to,false)
    require(int(game.grid[b.y][b.x])==game.Cell.ARTERIAL, "touch road failed at %s" % b)

func tap(game: Node,p: Vector2) -> void:
    touch(game,0,p,true)
    touch(game,0,p,false)

func touch(game: Node,index: int,p: Vector2,pressed: bool) -> void:
    var e: InputEventScreenTouch=InputEventScreenTouch.new()
    e.index=index
    e.position=p
    e.pressed=pressed
    game._unhandled_input(e)

func drag(game: Node,index: int,p: Vector2) -> void:
    var e: InputEventScreenDrag=InputEventScreenDrag.new()
    e.index=index
    e.position=p
    game._unhandled_input(e)

func fingerprint() -> String:
    var result: String=""
    for path: String in paths:
        result+=FileAccess.get_file_as_string(path)
    return result

func require(ok: bool,message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("AXIVA_ZERO_D_FAILED: "+message)
