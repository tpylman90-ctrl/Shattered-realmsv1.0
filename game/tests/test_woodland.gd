extends GutTest

func make_scene():
	var scene = load("res://scenes/woodland.tscn").instantiate()
	scene.save_enabled = false
	add_child_autofree(scene)
	scene.set_physics_process(false)
	return scene

func test_each_room_has_real_geometry_batched_scenery_and_visible_hero() -> void:
	var scene = make_scene()
	for id in scene.room_data:
		scene.load_room(id,6.0)
		assert_true(scene.scenery.get_child_count() > 8, "Terrain, props and vegetation are real meshes")
		assert_lt(scene.scenery.get_child_count(), 40, "Scenery is batched rather than thousands of scene nodes")
		assert_not_null(scene.hero.animation_player)
		assert_true(scene.camera.current)
		var pixel: Vector2 = scene.camera.unproject_position(scene.player.position + Vector3.UP)
		assert_true(Rect2(230,110,740,500).has_point(pixel), "Hero stays in the clear gameplay frame")
		assert_false(scene.can_walk(Vector3(18,0,0)), "Scenery banks are outside the walk corridor")

	await get_tree().process_frame

func test_bridge_walkway_keeps_feet_on_deck_and_out_of_stream() -> void:
	var scene = make_scene()
	scene.load_room("crossing",8.0)
	for i in range(161):
		var z := 8.0-i*0.1
		scene.player.position = Vector3(scene.path_x(z),scene.walk_height(z),z)
		assert_true(scene.can_walk(scene.player.position))
		if absf(z)<2.8:
			assert_gt(scene.player.position.y,scene.ground_height(scene.player.position.x,z)+0.25)
		if absf(z)<4:
			assert_false(scene.can_walk(Vector3(scene.path_x(z)+1.4,0,z)), "Rails contain the walkway")
	var before: Vector3 = scene.player.position
	scene.move_actor(Vector3(100,0,0))
	assert_almost_eq(scene.player.position.x,before.x,0.001, "Cannot walk through the banks")

	await get_tree().process_frame

func test_two_way_room_transitions_have_safe_spawns_and_cleanup() -> void:
	var scene = make_scene()
	var old_root: Node3D = scene.scenery
	scene.player.position = Vector3(scene.path_x(-15.1),0.18,-15.1)
	scene.transition_lock = 0
	scene._physics_process(0.016)
	assert_eq(scene.room_id,"crossing")
	assert_gt(scene.player.position.z,11.0)
	assert_gt(scene.transition_lock,0.0)
	assert_false(old_root.is_inside_tree(), "Old room is detached before the next is active")
	scene.player.position = Vector3(scene.path_x(15.1),0.18,15.1)
	scene.transition_lock = 0
	scene._physics_process(0.016)
	assert_eq(scene.room_id,"forest")
	assert_lt(scene.player.position.z,-11.0)
	assert_eq(scene.get_children().filter(func(node): return node.name == "RoomScenery").size(),1)

	await get_tree().process_frame

func test_manual_motion_cancels_tap_travel_and_uses_floor_height() -> void:
	var scene = make_scene()
	scene.travel_target = -10
	scene.joystick.direction = Vector2(0,-1)
	var before: Vector3 = scene.player.position
	scene._physics_process(0.1)
	assert_eq(scene.travel_target,INF)
	assert_gt(scene.player.position.distance_to(before),0.05)
	assert_almost_eq(scene.player.position.y,scene.walk_height(scene.player.position.z),0.001)
	var forest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/ravenwood_forest.json"))
	assert_eq(forest.inspections[0].scene,"woodland", "Town's north road enters the 3D rooms")

func test_all_ten_rooms_have_reciprocal_connections_and_safe_arrivals() -> void:
	var scene = make_scene()
	assert_eq(scene.room_data.size(),10)
	var seen := {"forest":true}
	var frontier: Array[String] = ["forest"]
	while not frontier.is_empty():
		var source: String = frontier.pop_front()
		for side in scene.room_data[source].exits:
			var exit: Dictionary = scene.room_data[source].exits[side]
			if not scene.room_data.has(exit.to):
				continue
			assert_eq(scene.room_data[exit.to].exits[exit.arrival].to,source,"Every trail has a reciprocal return")
			if not seen.has(exit.to):
				seen[exit.to]=true
				frontier.append(exit.to)
			scene.load_room(source,0)
			scene.enter_exit(side)
			assert_eq(scene.room_id,exit.to)
			assert_true(scene.can_walk(scene.player.position),"Safe return-spawn floor")
			assert_eq(scene.nearby_exit(1.0),"","Arrival is clear of the doorway")
			await get_tree().process_frame
	assert_eq(seen.size(),10,"Entire territory is reachable from Blackthorn")

func test_route_graph_keeps_side_trail_paths_on_walkable_ground() -> void:
	var scene = make_scene()
	for room in ["waymeet","oldgrowth","ruins"]:
		scene.load_room(room,6)
		var start: int = scene.route_graph.get_closest_point(scene.player.position)
		for side in ["east","west"]:
			if not scene.branch_available(side):
				continue
			var finish: int = scene.route_graph.get_closest_point(scene.exit_position(side))
			var route: PackedVector3Array = scene.route_graph.get_point_path(start,finish)
			assert_gt(route.size(),10)
			for point in route:
				assert_true(scene.can_walk(point),"Side trails do not cut through banks")
		await get_tree().process_frame

func test_territory_map_pauses_movement_and_checkpoint_records_visits() -> void:
	var scene = make_scene()
	scene.load_room("timber",6)
	scene.territory_map.open(scene.room_id,scene.visited_rooms)
	var before: Vector3 = scene.player.position
	scene.joystick.direction=Vector2(0,-1)
	scene._physics_process(1.0)
	assert_eq(scene.player.position,before,"Map pauses traversal")
	scene.territory_map.hide()
	scene.save_enabled=true
	var file := "user://test_exploration_checkpoint.cfg"
	assert_eq(scene.persist_exploration(file),OK)
	var config := ConfigFile.new()
	assert_eq(config.load(file),OK)
	assert_eq(config.get_value("exploration","room"),"timber")
	assert_eq(config.get_value("exploration","position"),before)
	assert_true("timber" in config.get_value("exploration","visited"))
	DirAccess.remove_absolute(file)
	await get_tree().process_frame

func test_walk_and_run_are_faster_in_wilds_and_towns() -> void:
	var scene = make_scene()
	assert_gt(scene.travel_speed(),1.9,"Wilderness walk was 1.45 m/s")
	scene.running=true
	assert_gt(scene.travel_speed(),4.2,"Wilderness run was 3.25 m/s")
	var town = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(town)
	town.set_physics_process(false)
	town.transition_lock=100
	for run in [false,true]:
		town.sprinting=run
		town._place_screen(Vector2(800,650))
		var old_speed: float = (2.864 if run else 1.129)*town.player.scale.x
		var old_pixels: float = town.camera.unproject_position(town.player.position+Vector3.RIGHT*old_speed).distance_to(town.camera.unproject_position(town.player.position))*0.1
		var before: Vector2 = town.screen_position
		town._walk(Vector2.LEFT,0.1)
		assert_gt(town.screen_position.distance_to(before),old_pixels*1.2,"Town walk/run both increase")
