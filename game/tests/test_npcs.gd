extends GutTest

func make_scene():
	var scene = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(scene)
	scene.set_physics_process(false)
	return scene

func test_residents_have_unique_ids_reachable_placements_and_topics() -> void:
	var scene = make_scene()
	var ids := {}
	assert_eq(scene.npc_catalog.size(), 12)
	for location in scene.location_names:
		scene.load_field(location)
		assert_eq(scene.npc_actors.size(), 1, location + " has a resident")
		var npc: Node3D = scene.npc_actors[0]
		var anchor: Vector2 = npc.anchor
		assert_false(ids.has(npc.record.id))
		ids[npc.record.id] = true
		assert_true(scene.surface.contains(anchor), location + " resident stands on the fitted floor")
		assert_eq(scene._exit_for_screen(anchor), "", location + " resident is outside doorway triggers")
		assert_gt(scene.surface.route(scene.screen_position, anchor).size(), 0)
		assert_true(npc.record.appearance in ["male", "female"])
		assert_true(_has_shirt_tint(npc, Color(npc.record.shirt)), location + " has its own clothing palette")
		assert_eq(npc.record.topics.size(), 2)
		for topic in npc.record.topics:
			assert_false(str(topic.label).is_empty())
			assert_gt(str(topic.text).length(), 35)

func test_talk_topics_pause_input_and_close_clears_the_approach() -> void:
	var scene = make_scene()
	scene.load_field("forge")
	var npc: Node3D = scene.npc_actors[0]
	scene._place_screen(npc.anchor + Vector2(0, 60))
	scene._update_interaction()
	assert_eq(scene.inspect_button.text, "A • Talk")
	scene._inspect_nearest()
	assert_true(scene.npc_dialog.visible)
	assert_false(scene.joystick.is_processing_input(), "Dialogue releases touch input")
	assert_eq(scene.npc_dialog.record.id, "bram")
	assert_eq(scene.npc_dialog.body.text, npc.record.greeting)
	scene.npc_dialog.select_topic(1)
	assert_eq(scene.npc_dialog.body.text, npc.record.topics[1].text)
	var before: Vector2 = scene.screen_position
	scene._set_target(Vector2(645, 610))
	scene._physics_process(1.0)
	scene._walk(Vector2.DOWN, 1.0)
	assert_eq(scene.screen_position, before, "Dialogue blocks touch, joystick and direct walking")
	scene.npc_dialog.close_dialogue()
	assert_false(scene.npc_dialog.visible)
	assert_true(scene.joystick.is_processing_input(), "Goodbye restores the joystick")
	assert_eq(scene.pending_npc, "")
	assert_true(scene.waypoints.is_empty())

func test_tap_resident_routes_to_talk_and_scene_change_cleans_up() -> void:
	var scene = make_scene()
	scene.load_field("inn")
	var npc: Node3D = scene.npc_actors[0]
	scene.transition_lock = 100
	scene._set_target(scene.camera.unproject_position(npc.head_position()).lerp(npc.anchor, 0.5))
	assert_eq(scene.pending_npc, "mara")
	assert_false(scene.npc_dialog.visible, "A distant tap approaches before talking")
	for step in 1800:
		scene._physics_process(1.0 / 60.0)
		if scene.npc_dialog.visible:
			break
	assert_true(scene.npc_dialog.visible)
	assert_eq(scene.npc_dialog.record.id, "mara")
	scene.load_field("camp")
	assert_false(scene.npc_dialog.visible)
	assert_eq(scene.npc_actors.size(), 1)
	assert_eq(scene.npc_root.get_child_count(), 1)
	assert_eq(scene.npc_actors[0].record.id, "orrin")
	assert_eq(scene.pending_npc, "")

func test_remote_resident_does_not_replace_object_inspection() -> void:
	var scene = make_scene()
	scene.load_field("inn")
	scene._place_screen(Vector2(570, 320))
	assert_null(scene._nearest_npc())
	scene._inspect_nearest()
	assert_true(scene.inspect_dialog.visible)
	assert_false(scene.npc_dialog.visible)

func test_npc_tints_do_not_mutate_shared_player_materials() -> void:
	var scene = make_scene()
	var male = load("res://assets/characters/starter_male.glb").instantiate()
	add_child_autofree(male)
	var materials := _materials(male)
	var colors: Array = []
	for material in materials:
		colors.append(material.albedo_color)
	for location in ["market", "forge", "command"]:
		scene.load_field(location)
	for index in materials.size():
		assert_eq(materials[index].albedo_color, colors[index], "NPC palettes leave the player materials untouched")

func _materials(node: Node) -> Array:
	var result: Array = []
	if node is MeshInstance3D:
		for index in node.mesh.get_surface_count():
			var material = node.get_active_material(index)
			if material is StandardMaterial3D:
				result.append(material)
	for child in node.get_children():
		result.append_array(_materials(child))
	return result

func _has_shirt_tint(node: Node, color: Color) -> bool:
	if node is MeshInstance3D:
		for index in node.mesh.get_surface_count():
			var material = node.get_surface_override_material(index)
			if material is StandardMaterial3D and material.albedo_color == color:
				return true
	for child in node.get_children():
		if _has_shirt_tint(child, color):
			return true
	return false
