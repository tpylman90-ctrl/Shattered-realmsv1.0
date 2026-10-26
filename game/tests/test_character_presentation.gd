extends GutTest

func make_scene():
	var scene = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(scene)
	scene.set_physics_process(false)
	return scene

func height_on_screen(scene, point: Vector3, multiplier: float) -> float:
	return absf(scene.camera.unproject_position(point).y - scene.camera.unproject_position(point + Vector3.UP * 1.75 * 0.7 * multiplier).y)

func test_player_and_residents_share_presentation_at_the_same_depth() -> void:
	var scene = make_scene()
	for location in scene.location_names:
		scene.load_field(location)
		var npc: Node3D = scene.npc_actors[0]
		scene._place_screen(npc.anchor)
		assert_almost_eq(scene.player.scale.x, 0.7, 0.0001, "Movement units remain unchanged")
		assert_gt(scene.body_visual.scale.x, 1.2, "Larger baseline for " + location)
		assert_almost_eq(scene.player.scale.x * scene.body_visual.scale.x, npc.scale.x / float(npc.record.height), 0.001,
			location + " player and resident use the same scale calibration")
		assert_lt(scene.player.position.distance_to(npc.position), 0.001, "Scaling retains floor contact")

func test_camp_distance_keeps_characters_readable() -> void:
	var scene = make_scene()
	scene.load_field("camp")
	var far: Vector3 = scene.surface.world_at(Vector2(235, 385))
	var near: Vector3 = scene.surface.world_at(Vector2(740, 650))
	var far_old := height_on_screen(scene, far, 1.0)
	var near_old := height_on_screen(scene, near, 1.0)
	var far_new := height_on_screen(scene, far, scene._visual_factor_at(far))
	var near_new := height_on_screen(scene, near, scene._visual_factor_at(near))
	assert_gt(far_new, 70.0, "Camp entry no longer makes the player a tiny figure")
	assert_gt(far_new / near_new, far_old / near_old, "Perspective shrinks more gently")
	assert_gt(near_new, near_old, "Near characters also receive the larger baseline")

func test_visual_sizing_does_not_change_walk_or_run_distance() -> void:
	var scene = make_scene()
	scene.transition_lock = 100
	var presentation: Dictionary = scene.character_presentation.duplicate()
	for running in [false, true]:
		scene.sprinting = running
		scene.character_presentation.baseline_multiplier = 1.0
		scene.character_presentation.depth_exponent = 0.0
		scene._place_screen(Vector2(800, 650))
		scene._walk(Vector2.LEFT, 0.2)
		var before: Vector2 = scene.screen_position
		scene.character_presentation = presentation.duplicate()
		scene._place_screen(Vector2(800, 650))
		scene._walk(Vector2.LEFT, 0.2)
		assert_lt(scene.screen_position.distance_to(before), 0.001, "Visual size preserves existing travel speed")
