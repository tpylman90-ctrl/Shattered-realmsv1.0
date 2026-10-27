extends Node3D

var field_id := "gate"
var camera: Camera3D
var player: CharacterBody3D
var backdrop: TextureRect
var heading: Label
var hint: Label
var joystick: Control
var transition_lock := 0.0
var moving_time := 0.0
var body_visual: Node3D
var surface: FieldSurface
var field_data: Dictionary
var waypoints := PackedVector2Array()
var foreground_root: Node2D
var screen_position := Vector2.ZERO
var depth_groups: Array[Node2D] = []
var town_map: Control
var inspect_button: Button
var inspect_dialog: AcceptDialog
var location_names: Dictionary
var requested_exit := ""
var manual_move := true
var hero_visual: Node3D
var sprinting := false
var npc_catalog: Array = []
var npc_root: Node3D
var npc_actors: Array[Node3D] = []
var npc_dialog: PanelContainer
var npc_marker: Label
var pending_npc := ""
var travel_speeds: Dictionary
var character_presentation: Dictionary
var player_shadow: MeshInstance3D

func _ready() -> void:
	travel_speeds = JSON.parse_string(FileAccess.get_file_as_string("res://data/travel_speeds.json"))
	location_names = JSON.parse_string(FileAccess.get_file_as_string("res://data/ravenwood_locations.json")).locations
	npc_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/ravenwood_npcs.json")).npcs
	character_presentation = JSON.parse_string(FileAccess.get_file_as_string("res://data/ravenwood_character_presentation.json"))
	_build_layers()
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_CANVAS
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.7, 0.76, 0.85)
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -25, 0)
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.light_energy = 1.5
	add_child(sun)
	_build_player()
	npc_root = Node3D.new()
	npc_root.name = "Residents"
	add_child(npc_root)
	load_field("gate")

func _build_layers() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)
	backdrop = TextureRect.new()
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(backdrop)
	var front_layer := CanvasLayer.new()
	front_layer.layer = 2
	add_child(front_layer)
	foreground_root = Node2D.new()
	front_layer.add_child(foreground_root)
	var ui := CanvasLayer.new()
	ui.layer = 3
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(26, 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.035, 0.85)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	ui.add_child(panel)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 24)
	panel.add_child(heading)
	hint = Label.new()
	hint.position = Vector2(260, 660)
	hint.add_theme_font_size_override("font_size", 18)
	ui.add_child(hint)
	joystick = preload("res://scripts/joystick.gd").new()
	joystick.position = Vector2(45, 490)
	joystick.size = Vector2(180, 180)
	ui.add_child(joystick)
	var map := Button.new()
	map.text = "MAP"
	map.position = Vector2(1120, 24)
	map.size = Vector2(130, 60)
	ui.add_child(map)
	town_map = preload("res://scripts/town_map.gd").new()
	ui.add_child(town_map)
	town_map.hide()
	map.pressed.connect(func():
		_close_dialogues()
		waypoints.clear()
		joystick.direction = Vector2.ZERO
		hero_visual.play_clip("Idle")
		town_map.show_location(field_id))
	inspect_dialog = AcceptDialog.new()
	inspect_dialog.title = "Ravenwood"
	inspect_dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(inspect_dialog)
	inspect_button = Button.new()
	inspect_button.text = "A • Inspect"
	inspect_button.position = Vector2(1010,555)
	inspect_button.size = Vector2(120,60)
	inspect_button.pressed.connect(_inspect_nearest)
	ui.add_child(inspect_button)
	npc_marker = Label.new()
	npc_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	npc_marker.add_theme_font_size_override("font_size", 18)
	npc_marker.add_theme_color_override("font_color", Color(1.0, 0.86, 0.53))
	npc_marker.add_theme_color_override("font_outline_color", Color(0.025, 0.04, 0.03))
	npc_marker.add_theme_constant_override("outline_size", 6)
	ui.add_child(npc_marker)
	npc_dialog = preload("res://scripts/npc_dialogue.gd").new()
	ui.add_child(npc_dialog)
	npc_dialog.closed.connect(func():
		pending_npc = ""
		waypoints.clear()
		joystick.direction = Vector2.ZERO
		joystick.set_process_input(true))
	var run_button := Button.new()
	run_button.text = "Run: Off"
	run_button.toggle_mode = true
	run_button.position = Vector2(1020, 480)
	run_button.size = Vector2(230, 60)
	run_button.toggled.connect(func(active: bool):
		sprinting = active
		run_button.text = "Run: On" if active else "Run: Off")
	ui.add_child(run_button)
	var cancel := Button.new()
	cancel.text = "B • Close"
	cancel.position = Vector2(1140,555)
	cancel.size = Vector2(110,60)
	cancel.pressed.connect(func():
		town_map.hide()
		_close_dialogues()
		waypoints.clear())
	ui.add_child(cancel)
	var back := Button.new()
	back.text = "MENU"
	back.position = Vector2(1120, 635)
	back.size = Vector2(130, 60)
	ui.add_child(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	town_map.move_to_front()

func _mesh(mesh: Mesh, color: Color, location: Vector3, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	instance.material_override = material
	instance.position = location
	parent.add_child(instance)
	return instance

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Adventurer"
	add_child(player)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	player.add_child(shape)
	body_visual = Node3D.new()
	player.add_child(body_visual)
	hero_visual = preload("res://scripts/hero_model.gd").new()
	body_visual.add_child(hero_visual)
	hero_visual.setup(preload("res://scripts/hero_model.gd").selected())
	var shadow := PlaneMesh.new()
	shadow.size = Vector2(0.95, 0.7)
	var shadow_mesh := _mesh(shadow, Color.WHITE, Vector3(0, 0.012, 0), player)
	player_shadow = shadow_mesh
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; void fragment(){vec2 p=(UV-vec2(0.5))*2.0; ALBEDO=vec3(0.055,0.04,0.02); ALPHA=max(0.0,1.0-dot(p,p))*0.38;}"
	var shadow_material := ShaderMaterial.new()
	shadow_material.shader = shader
	shadow_mesh.material_override = shadow_material

func load_field(id: String, entry: String = "arrival") -> void:
	_close_dialogues()
	field_id = id
	field_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/ravenwood_" + id + ".json"))
	backdrop.texture = load(field_data.backdrop)
	player.scale = Vector3.ONE * float(field_data.character_scale)
	for child in foreground_root.get_children():
		child.free()
	depth_groups.clear()
	var position_data: Array = field_data.camera_position
	var target: Array = field_data.camera_target
	camera.position = Vector3(position_data[0], position_data[1], position_data[2])
	camera.look_at(Vector3(target[0], target[1], target[2]))
	camera.fov = field_data.fov
	surface = FieldSurface.new()
	surface.configure(camera, field_data.navigation_outline, field_data.navigation_heights)
	if has_node("WalkMesh"):
		get_node("WalkMesh").free()
	var floor_body := StaticBody3D.new()
	floor_body.name = "WalkMesh"
	var shape := CollisionShape3D.new()
	var mesh_shape := ConcavePolygonShape3D.new()
	mesh_shape.set_faces(surface.collision_faces())
	shape.shape = mesh_shape
	floor_body.add_child(shape)
	add_child(floor_body)
	_add_polygons(field_data.foreground_polygons, foreground_root)
	for occluder in field_data.depth_occluders:
		var group := Node2D.new()
		foreground_root.add_child(group)
		_add_polygons(occluder.polygons, group)
		group.set_meta("ground_line", Vector2(occluder.ground_line[0], occluder.ground_line[1]))
		depth_groups.append(group)
	var spawn: Array = field_data.spawns.get(entry, field_data.spawns.arrival)
	_place_screen(Vector2(spawn[0], spawn[1]))
	waypoints.clear()
	requested_exit = ""
	manual_move = true
	player.velocity = Vector3.ZERO
	transition_lock = 0.8
	heading.text = "RAVENWOOD  /  " + field_data.title
	hint.text = field_data.route_hint
	_load_npcs()
	_update_interaction()

func _load_npcs() -> void:
	for child in npc_root.get_children():
		child.free()
	npc_actors.clear()
	pending_npc = ""
	for data in npc_catalog:
		if data.location != field_id:
			continue
		var actor = preload("res://scripts/town_npc.gd").new()
		npc_root.add_child(actor)
		var anchor := Vector2(data.position[0], data.position[1])
		var floor_position := surface.world_at(anchor)
		actor.configure(data, floor_position, player.scale.x * _visual_factor_at(floor_position))
		npc_actors.append(actor)

func _close_dialogues() -> void:
	if is_instance_valid(inspect_dialog):
		inspect_dialog.hide()
	if is_instance_valid(npc_dialog):
		npc_dialog.close_dialogue()
	pending_npc = ""

func _add_polygons(masks: Array, parent: Node2D) -> void:
	for mask in masks:
		var polygon := Polygon2D.new()
		var points := PackedVector2Array()
		var uv := PackedVector2Array()
		for point in mask:
			var screen := Vector2(point[0], point[1])
			points.append(screen)
			uv.append(screen / Vector2(1280, 720) * backdrop.texture.get_size())
		polygon.polygon = points
		polygon.uv = uv
		polygon.texture = backdrop.texture
		parent.add_child(polygon)

func _place_screen(screen: Vector2) -> void:
	screen_position = surface.constrain(screen)
	player.position = surface.world_at(screen_position)
	var visual_factor := _visual_factor_at(player.position)
	body_visual.scale = Vector3.ONE * visual_factor
	player_shadow.scale = Vector3(visual_factor, 1.0, visual_factor)
	for group in depth_groups:
		var ground_line: Vector2 = group.get_meta("ground_line")
		group.visible = screen_position.y < screen_position.x * ground_line.x + ground_line.y

func _visual_factor_at(floor_position: Vector3) -> float:
	# Painted perspective and the fitted floor do not have identical depth.
	# Keep the same readable presentation for a player or NPC at this position,
	# while leaving the movement body, floor, and walking speed in gameplay units.
	var feet := camera.unproject_position(floor_position)
	var base_height := float(character_presentation.model_height_m) * float(field_data.character_scale)
	var head := camera.unproject_position(floor_position + Vector3.UP * base_height)
	var projected_height := maxf(absf(feet.y - head.y), 1.0)
	var baseline := float(character_presentation.baseline_multiplier)
	var depth_ratio := maxf(1.0, float(character_presentation.reference_height_px) / projected_height)
	return minf(baseline * pow(depth_ratio, float(character_presentation.depth_exponent)), float(character_presentation.maximum_multiplier))

func _exit_for_screen(screen: Vector2) -> String:
	for id in field_data.exits:
		var polygon := PackedVector2Array()
		for point in field_data.exits[id]:
			polygon.append(Vector2(point[0], point[1]))
		if Geometry2D.is_point_in_polygon(screen, polygon):
			return id
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_close_dialogues()
			return
		if event.physical_keycode == KEY_E and not town_map.visible and not npc_dialog.visible and not inspect_dialog.visible:
			_inspect_nearest()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_target(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_set_target(event.position)

func _set_target(screen: Vector2) -> void:
	if town_map.visible or inspect_dialog.visible or npc_dialog.visible:
		return
	pending_npc = ""
	for npc in npc_actors:
		if npc.screen_rect(camera).has_point(screen):
			pending_npc = npc.record.id
			requested_exit = ""
			manual_move = false
			var anchor: Vector2 = npc.anchor
			var offset := screen_position - anchor
			var approach := anchor + offset.normalized() * 65.0
			waypoints = surface.route(screen_position, approach)
			if _npc_in_reach(npc):
				_talk_to(npc)
			return
	manual_move = false
	requested_exit = _exit_for_screen(surface.constrain(screen))
	waypoints = surface.route(screen_position, screen)

func _physics_process(delta: float) -> void:
	if town_map.visible or inspect_dialog.visible or npc_dialog.visible:
		return
	transition_lock = maxf(0, transition_lock - delta)
	var input := Vector2.ZERO
	input.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	input.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	if joystick.direction.length() > 0.1:
		input = joystick.direction
	_walk(input.limit_length(), delta)

func _walk(input: Vector2, delta: float) -> void:
	if npc_dialog.visible:
		return
	if input.length() > 0.1:
		pending_npc = ""
		manual_move = true
		requested_exit = ""
		waypoints.clear()
	elif not waypoints.is_empty():
		var offset := waypoints[0] - screen_position
		if offset.length() < 3:
			waypoints.remove_at(0)
		else:
			input = offset.normalized()
	var movement_speed := float(travel_speeds.town_run if sprinting else travel_speeds.town_walk) * float(travel_speeds.run_multiplier if sprinting else travel_speeds.walk_multiplier) * player.scale.x
	var pixel_speed := camera.unproject_position(player.position + Vector3.RIGHT * movement_speed).distance_to(camera.unproject_position(player.position))
	var distance := pixel_speed * delta
	if not waypoints.is_empty():
		distance = minf(distance, screen_position.distance_to(waypoints[0]))
	var old_position := player.position
	_place_screen(screen_position + input * distance)
	var movement := player.position - old_position
	if movement.length() > 0.001:
		body_visual.rotation.y = lerp_angle(body_visual.rotation.y, atan2(movement.x, movement.z), delta * 12)
		hero_visual.update_locomotion(Vector2(movement.x, movement.z).length() / maxf(delta, 0.001), player.scale.x * body_visual.scale.x, sprinting)
		moving_time += delta * 10
		body_visual.position.y = 0
	else:
		hero_visual.play_clip("Idle")
		body_visual.position.y = 0
	hint.text = field_data.route_hint
	for area in field_data.closed_areas:
		var polygon := PackedVector2Array()
		for point in area.polygon:
			polygon.append(Vector2(point[0], point[1]))
		if Geometry2D.is_point_in_polygon(screen_position, polygon):
			hint.text = area.hint
	var nearest := ""
	var nearest_distance := 70.0
	for id in field_data.exits:
		var center := Vector2.ZERO
		for point in field_data.exits[id]:
			center += Vector2(point[0],point[1])
		center /= field_data.exits[id].size()
		if center.distance_to(screen_position) < nearest_distance:
			nearest_distance = center.distance_to(screen_position)
			nearest = id
	if not nearest.is_empty():
		hint.text = "Enter " + location_names[nearest]
	_update_interaction()
	if not pending_npc.is_empty():
		for npc in npc_actors:
			if npc.record.id == pending_npc and _npc_in_reach(npc):
				_talk_to(npc)
				return
	if transition_lock > 0:
		return
	var destination := _exit_for_screen(screen_position)
	if not destination.is_empty() and (manual_move or requested_exit == destination):
		load_field(destination, field_id)

func _nearest_inspection() -> Dictionary:
	var nearest: Dictionary = {}
	var distance := 125.0
	for point in field_data.get("inspections", []):
		var location := Vector2(point.position[0],point.position[1])
		if location.distance_to(screen_position) < distance:
			distance = location.distance_to(screen_position)
			nearest = point
	return nearest

func _inspect_nearest() -> void:
	if npc_dialog.visible or inspect_dialog.visible or town_map.visible:
		return
	var npc := _nearest_npc()
	if npc != null:
		_talk_to(npc)
		return
	var point := _nearest_inspection()
	if point.is_empty():
		return
	if point.get("scene", "") == "woodland":
		get_tree().set_meta("woodland_entry","forest")
		get_tree().change_scene_to_file("res://scenes/woodland.tscn")
		return
	waypoints.clear()
	joystick.direction = Vector2.ZERO
	hero_visual.play_clip("Idle")
	inspect_dialog.title = point.title
	inspect_dialog.dialog_text = point.text
	inspect_dialog.popup_centered(Vector2i(620,210))

func _npc_in_reach(npc: Node3D) -> bool:
	var anchor: Vector2 = npc.anchor
	return screen_position.distance_to(anchor) < 125.0 and surface.visible_segment(screen_position, anchor)

func _nearest_npc() -> Node3D:
	var nearest: Node3D = null
	var distance := 125.0
	for npc in npc_actors:
		var anchor: Vector2 = npc.anchor
		var candidate := screen_position.distance_to(anchor)
		if candidate < distance and _npc_in_reach(npc):
			distance = candidate
			nearest = npc
	return nearest

func _update_interaction() -> void:
	var npc := _nearest_npc()
	inspect_button.text = "A • Talk" if npc != null else "A • Inspect"
	inspect_button.disabled = npc == null and _nearest_inspection().is_empty()
	npc_marker.visible = npc != null
	if npc != null:
		npc_marker.text = npc.record.name + " · " + npc.record.role
		var label_size := npc_marker.get_minimum_size()
		var head: Vector2 = camera.unproject_position(npc.head_position())
		npc_marker.position = Vector2(clampf(head.x - label_size.x * 0.5, 10.0, 1270.0 - label_size.x), maxf(90.0, head.y - 28.0))
		hint.text = "Talk to " + npc.record.name + " · A / E"

func _talk_to(npc: Node3D) -> void:
	waypoints.clear()
	requested_exit = ""
	pending_npc = ""
	joystick.direction = Vector2.ZERO
	joystick.finger = -1
	joystick.knob = Vector2.ZERO
	joystick.queue_redraw()
	joystick.set_process_input(false)
	player.velocity = Vector3.ZERO
	hero_visual.play_clip("Idle")
	npc.face_player(player.position)
	npc_dialog.open_npc(npc.record)
