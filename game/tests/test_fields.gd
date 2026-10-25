extends GutTest

func test_generated_legacy_field_contract() -> void:
	for field in ["market", "camp"]:
		var root: String = "res://assets/generated/ravenwood/" + field
		assert_true(ResourceLoader.exists(root + ".png"))
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root + ".json"))
		assert_eq(data.walkmesh.size(), 4)
		assert_eq(data.triangles.size(), 6)

func test_approved_gate_navigation_and_safe_return_spawns() -> void:
	var scene = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(scene)
	assert_eq(scene.field_id, "gate")
	assert_true(scene.gate_surface.contains(scene.gate_screen))
	assert_eq(scene._gate_exit_for_screen(scene.gate_screen), "")
	for destination in ["market", "camp"]:
		var exit_point := Vector2(180, 390) if destination == "market" else Vector2(1205, 490)
		scene._place_gate_screen(exit_point)
		scene.transition_lock = 0
		scene._physics_process(0.01)
		assert_eq(scene.field_id, destination)
		scene.player.position = Vector3(9.4 if destination == "market" else -9.4, 0, 1)
		scene.transition_lock = 0
		scene._physics_process(0.01)
		assert_eq(scene.field_id, "gate")
		assert_eq(scene._gate_exit_for_screen(scene.gate_screen), "")

func test_tap_route_stays_on_traced_floor() -> void:
	var scene = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(scene)
	var surface = scene.gate_surface
	for destination in [Vector2(180, 390), Vector2(1205, 490), Vector2(745, 360)]:
		var path: PackedVector2Array = surface.route(scene.gate_screen, destination)
		assert_gt(path.size(), 0)
		var previous: Vector2 = scene.gate_screen
		for waypoint in path:
			assert_true(surface.visible_segment(previous, waypoint))
			assert_lt(scene.camera.unproject_position(surface.world_at(waypoint)).distance_to(waypoint), 1.0)
			previous = waypoint
		assert_lt(previous.distance_to(destination), 1.0)
	assert_false(surface.contains(Vector2(400, 200)), "Cannot walk through the gatehouse")

func test_camera_projection_matches_floor_and_stairs_rise() -> void:
	var scene = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(scene)
	for point in [Vector2(800, 650), Vector2(180, 390), Vector2(1205, 490), Vector2(745, 360)]:
		var world: Vector3 = scene.gate_surface.world_at(point)
		assert_lt(scene.camera.unproject_position(world).distance_to(point), 0.6)
	assert_gt(scene.gate_surface.world_at(Vector2(745, 360)).y, 0.5)
	assert_almost_eq(scene.gate_surface.world_at(Vector2(800, 650)).y, 0.0, 0.01)

func test_tap_walk_reaches_each_side_exit() -> void:
	for destination in ["market", "camp"]:
		var scene = load("res://scenes/ravenwood.tscn").instantiate()
		add_child_autofree(scene)
		scene._set_target(Vector2(180, 390) if destination == "market" else Vector2(1205, 490))
		for step in 1800:
			scene._physics_process(1.0 / 60.0)
			if scene.field_id != "gate":
				break
		assert_eq(scene.field_id, destination, "Tap path must actually reach its exit")
