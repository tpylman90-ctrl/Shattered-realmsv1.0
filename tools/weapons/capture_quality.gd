extends SceneTree
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	root.size=Vector2i(1280,900);root.content_scale_size=Vector2i(1280,900)
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment_catalog.json"))
	var stage:=Control.new();root.add_child(stage)
	var backdrop:=ColorRect.new();backdrop.size=Vector2(1280,900);backdrop.color=Color("17262d");stage.add_child(backdrop)
	var source:=OS.get_environment("WEAPON_BASELINE_SCRIPT")
	var script=load(source) if not source.is_empty() else load("res://scripts/weapon_model.gd")
	var families:Array=catalog.families.keys()
	for i in range(families.size()):
		var panel:=SubViewportContainer.new();panel.position=Vector2((i%5)*256,(i/5)*450+40);stage.add_child(panel)
		var viewport:=SubViewport.new();viewport.size=Vector2i(256,405);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;panel.add_child(viewport)
		var environment:=WorldEnvironment.new();var settings:=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("293a43");settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("bfd2e0");settings.ambient_light_energy=0.8;WeaponModel.add_studio_reflections(settings);environment.environment=settings;viewport.add_child(environment)
		var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-30,0);key.light_energy=1.7;viewport.add_child(key)
		var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(20,140,0);fill.light_color=Color("99c4de");fill.light_energy=1.0;viewport.add_child(fill)
		var model=script.new();viewport.add_child(model);model.build(catalog.items["ravenwood_"+families[i]]);model.rotation.y=-0.35
		var bounds:=AABB();var first:=true
		for child in model.get_children():
			var part:AABB=model.transform*child.transform*child.mesh.get_aabb();bounds=part if first else bounds.merge(part);first=false
		var center:=bounds.get_center();var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=maxf(bounds.size.y,bounds.size.x*405/256.0)*1.18;camera.position=center+Vector3(0,0.9 if families[i]=="cannon" else 0.15,5);viewport.add_child(camera);camera.look_at(center);camera.current=true
		var label:=Label.new();label.text=catalog.families[families[i]];label.position=Vector2((i%5)*256+12,(i/5)*450+5);label.add_theme_font_size_override("font_size",23);stage.add_child(label)
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("WEAPON_CAPTURE_PATH"))
	stage.free()
	if root.has_node("GameAudio"):root.get_node("GameAudio").free()
	await process_frame;quit()
