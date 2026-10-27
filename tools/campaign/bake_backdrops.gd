extends SceneTree
func _initialize() -> void:
	call_deferred("bake")
func bake() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
	for id in data.regions:
		set_meta("campaign_region",id);set_meta("campaign_room","forest");set_meta("bake_city",true)
		var scene=load("res://scenes/campaign_area.tscn").instantiate()
		scene.baking=true
		root.add_child(scene)
		scene.set_physics_process(false)
		scene.player.hide()
		for child in scene.get_children():
			if child is CanvasLayer:child.hide()
		if not str(data.regions[id].settlement).is_empty() and id!="ravenwood":
			scene.camera.position=Vector3(18,13,24);scene.camera.look_at(Vector3(0,1,-3))
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_webp("res://assets/cities/"+id+".webp",false,0.88)
		set_meta("bake_city",false)
		scene.load_room("d0",7)
		scene.camera.position=Vector3(0,5.5,11);scene.camera.fov=48;scene.camera.look_at(Vector3(0,0.7,0))
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_webp("res://assets/battles/"+id+".webp",false,0.86)
		print("Baked "+id)
		scene.free()
		await process_frame
	quit()
