extends GutTest

func test_camera_and_walkmesh_contract() -> void:
	for field in ["gate", "market", "camp"]:
		var root: String = "res://assets/generated/ravenwood/" + field
		assert_true(ResourceLoader.exists(root + ".png"))
		assert_true(ResourceLoader.exists(root + "_foreground.png"))
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root + ".json"))
		assert_gt(float(data.fov), 10.0)
		assert_eq(data.walkmesh.size(), 4)
		assert_eq(data.triangles.size(), 6)

func test_exit_connections_and_safe_return_spawns() -> void:
	var scene = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(scene)
	assert_eq(scene.field_id, "gate")
	scene.player.position = Vector3(-5.9, 0, 0)
	scene.transition_lock = 0
	scene._physics_process(0.01)
	assert_eq(scene.field_id, "market")
	assert_lt(scene.player.position.x, 5.7)
	scene.player.position = Vector3(5.9, 0, 0)
	scene.transition_lock = 0
	scene._physics_process(0.01)
	assert_eq(scene.field_id, "gate")
	assert_gt(scene.player.position.x, -5.7)
	scene.player.position = Vector3(5.9, 0, 0)
	scene.transition_lock = 0
	scene._physics_process(0.01)
	assert_eq(scene.field_id, "camp")
	scene.player.position = Vector3(-5.9, 0, 0)
	scene.transition_lock = 0
	scene._physics_process(0.01)
	assert_eq(scene.field_id, "gate")
