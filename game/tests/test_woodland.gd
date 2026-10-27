extends GutTest

func make_scene():
	var scene = load("res://scenes/woodland.tscn").instantiate()
	add_child_autofree(scene)
	scene.set_physics_process(false)
	return scene

func test_each_room_has_real_geometry_batched_scenery_and_visible_hero() -> void:
	var scene = make_scene()
	for id in scene.room_data:
		scene.load_room(id,6.0)
		assert_true(scene.scenery.get_child_count() > 8, "Terrain, props and vegetation are real meshes")
		assert_lt(scene.scenery.get_child_count(), 28, "Scenery is batched rather than thousands of scene nodes")
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
