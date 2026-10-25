extends GutTest

func make_scene():
	var scene = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(scene)
	return scene

func test_all_locations_have_packaged_art_and_valid_floor() -> void:
	var scene = make_scene()
	for id in ["gate", "market", "camp"]:
		scene.load_field(id)
		assert_true(ResourceLoader.exists(scene.field_data.backdrop))
		assert_gt(scene.surface.triangles.size(), 0)
		assert_eq(scene.surface.triangles.size() % 3, 0)
		assert_eq(scene.field_data.navigation_outline.size(), scene.field_data.navigation_heights.size())
		assert_true(scene.surface.contains(scene.screen_position))
		assert_eq(scene._exit_for_screen(scene.screen_position), "")
		assert_almost_eq(scene.player.scale.x, 0.55, 0.0001, "Character sizing is deferred")

func test_connections_and_safe_return_spawns() -> void:
	var scene = make_scene()
	for destination in ["market", "camp"]:
		scene._place_screen(Vector2(180, 390) if destination == "market" else Vector2(1075, 590))
		scene.transition_lock = 0
		scene._physics_process(0.01)
		assert_eq(scene.field_id, destination)
		assert_eq(scene._exit_for_screen(scene.screen_position), "")
		scene._place_screen(Vector2(1170, 390) if destination == "market" else Vector2(150, 295))
		scene.transition_lock = 0
		scene._physics_process(0.01)
		assert_eq(scene.field_id, "gate")
		assert_eq(scene._exit_for_screen(scene.screen_position), "")

func test_paths_and_projection_around_scenery() -> void:
	var scene = make_scene()
	var destinations := {
		"gate": [Vector2(180, 390), Vector2(1075, 590), Vector2(745, 360)],
		"market": [Vector2(1170, 390), Vector2(310, 325), Vector2(690, 590)],
		"camp": [Vector2(150, 295), Vector2(750, 440), Vector2(1080, 455)]
	}
	for id in destinations:
		scene.load_field(id)
		for destination in destinations[id]:
			var path: PackedVector2Array = scene.surface.route(scene.screen_position, destination)
			assert_gt(path.size(), 0, id + " route exists")
			var previous: Vector2 = scene.screen_position
			for waypoint in path:
				assert_true(scene.surface.visible_segment(previous, waypoint))
				assert_lt(scene.camera.unproject_position(scene.surface.world_at(waypoint)).distance_to(waypoint), 1.0)
				previous = waypoint
			assert_lt(previous.distance_to(destination), 1.0, id + " destination is on the floor")

func test_buildings_well_and_tent_are_not_walkable() -> void:
	var scene = make_scene()
	scene.load_field("gate")
	assert_false(scene.surface.contains(Vector2(400, 200)))
	scene.load_field("market")
	assert_false(scene.surface.contains(Vector2(460, 430)), "Well footprint is blocked")
	assert_false(scene.surface.contains(Vector2(800, 250)), "Smithy roof is blocked")
	scene.load_field("camp")
	assert_false(scene.surface.contains(Vector2(750, 300)), "Command tent roof is blocked")

func test_raised_gate_and_inn_steps() -> void:
	var scene = make_scene()
	assert_gt(scene.surface.world_at(Vector2(745, 360)).y, 0.5)
	assert_almost_eq(scene.surface.world_at(Vector2(800, 650)).y, 0.0, 0.01)
	scene.load_field("market")
	assert_gt(scene.surface.world_at(Vector2(310, 325)).y, 0.2)

func test_tap_walk_reaches_all_four_connections() -> void:
	var scene = make_scene()
	for trip in [["gate", "market", Vector2(180, 390)], ["market", "gate", Vector2(1170, 390)], ["gate", "camp", Vector2(1075, 590)], ["camp", "gate", Vector2(150, 295)]]:
		scene.load_field(trip[0])
		scene._set_target(trip[2])
		for step in 2400:
			scene._physics_process(1.0 / 60.0)
			if scene.field_id != trip[0]:
				break
		assert_eq(scene.field_id, trip[1], "Tap walking completes " + trip[0] + " → " + trip[1])

func test_market_tap_walk_approaches_inn_without_crossing_well() -> void:
	var scene = make_scene()
	scene.load_field("market")
	scene.transition_lock = 100
	scene._set_target(Vector2(310, 325))
	for step in 2400:
		scene._physics_process(1.0 / 60.0)
		assert_true(scene.surface.contains(scene.screen_position))
		if scene.waypoints.is_empty():
			break
	assert_lt(scene.screen_position.distance_to(Vector2(310, 325)), 4.0)

func test_reported_post_approach_enters_camp_and_return_does_not_bounce() -> void:
	var scene = make_scene()
	scene._place_screen(Vector2(1025, 580))
	scene.transition_lock = 0
	for step in 90:
		scene._walk(Vector2.RIGHT, 1.0 / 60.0)
		if scene.field_id == "camp":
			break
	assert_eq(scene.field_id, "camp", "Clear approach before the post must trigger camp")
	scene.load_field("gate", "camp")
	assert_eq(scene._exit_for_screen(scene.screen_position), "")
	scene.transition_lock = 0
	scene._walk(Vector2.ZERO, 1.0 / 60.0)
	assert_eq(scene.field_id, "gate", "Return arrival must not bounce into camp")
