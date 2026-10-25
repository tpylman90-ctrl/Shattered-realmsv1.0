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

func _ready() -> void:
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
	var map_panel := PanelContainer.new()
	map_panel.position = Vector2(790, 105)
	map_panel.size = Vector2(460, 175)
	map_panel.visible = false
	ui.add_child(map_panel)
	var map_label := Label.new()
	map_label.text = "  RAVENWOOD\n\n  MARKET  ←  GATE  →  ARMY CAMP\n\n  North: Upper town road closed"
	map_label.add_theme_font_size_override("font_size", 19)
	map_panel.add_child(map_label)
	map.pressed.connect(func(): map_panel.visible = not map_panel.visible)
	var back := Button.new()
	back.text = "MENU"
	back.position = Vector2(1120, 635)
	back.size = Vector2(130, 60)
	ui.add_child(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

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
	var torso := CapsuleMesh.new()
	torso.radius = 0.26
	torso.height = 0.8
	_mesh(torso, Color(0.14, 0.24, 0.22), Vector3(0, 1, 0), body_visual)
	var head := SphereMesh.new()
	head.radius = 0.19
	head.height = 0.38
	_mesh(head, Color(0.65, 0.43, 0.28), Vector3(0, 1.56, 0), body_visual)
	for x in [-0.14, 0.14]:
		var leg := BoxMesh.new()
		leg.size = Vector3(0.19, 0.65, 0.22)
		_mesh(leg, Color(0.12, 0.10, 0.08), Vector3(x, 0.36, 0), body_visual)
		var arm := CapsuleMesh.new()
		arm.radius = 0.09
		arm.height = 0.65
		_mesh(arm, Color(0.22, 0.16, 0.10), Vector3(x * 2.4, 1, 0), body_visual)
	var blade := BoxMesh.new()
	blade.size = Vector3(0.08, 0.85, 0.04)
	_mesh(blade, Color(0.55, 0.6, 0.59), Vector3(0.38, 0.55, 0.15), body_visual)
	var shadow := PlaneMesh.new()
	shadow.size = Vector2(0.95, 0.7)
	var shadow_mesh := _mesh(shadow, Color.WHITE, Vector3(0, 0.012, 0), player)
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; void fragment(){vec2 p=(UV-vec2(0.5))*2.0; ALBEDO=vec3(0.055,0.04,0.02); ALPHA=max(0.0,1.0-dot(p,p))*0.38;}"
	var shadow_material := ShaderMaterial.new()
	shadow_material.shader = shader
	shadow_mesh.material_override = shadow_material

func load_field(id: String, entry: String = "arrival") -> void:
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
	player.velocity = Vector3.ZERO
	transition_lock = 0.8
	heading.text = "RAVENWOOD  /  " + field_data.title
	hint.text = field_data.route_hint

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
	for group in depth_groups:
		var ground_line: Vector2 = group.get_meta("ground_line")
		group.visible = screen_position.y < screen_position.x * ground_line.x + ground_line.y

func _exit_for_screen(screen: Vector2) -> String:
	for id in field_data.exits:
		var polygon := PackedVector2Array()
		for point in field_data.exits[id]:
			polygon.append(Vector2(point[0], point[1]))
		if Geometry2D.is_point_in_polygon(screen, polygon):
			return id
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_target(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_set_target(event.position)

func _set_target(screen: Vector2) -> void:
	waypoints = surface.route(screen_position, screen)

func _physics_process(delta: float) -> void:
	transition_lock = maxf(0, transition_lock - delta)
	var input := Vector2.ZERO
	input.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	input.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	if joystick.direction.length() > 0.1:
		input = joystick.direction
	_walk(input.limit_length(), delta)

func _walk(input: Vector2, delta: float) -> void:
	if input.length() > 0.1:
		waypoints.clear()
	elif not waypoints.is_empty():
		var offset := waypoints[0] - screen_position
		if offset.length() < 3:
			waypoints.remove_at(0)
		else:
			input = offset.normalized()
	var pixel_speed := camera.unproject_position(player.position + Vector3.RIGHT * 3.0).distance_to(camera.unproject_position(player.position))
	var distance := pixel_speed * delta
	if not waypoints.is_empty():
		distance = minf(distance, screen_position.distance_to(waypoints[0]))
	var old_position := player.position
	_place_screen(screen_position + input * distance)
	var movement := player.position - old_position
	if movement.length() > 0.001:
		body_visual.rotation.y = lerp_angle(body_visual.rotation.y, atan2(movement.x, movement.z), delta * 12)
		moving_time += delta * 10
		body_visual.position.y = sin(moving_time) * 0.018
	else:
		body_visual.position.y = 0
	hint.text = field_data.route_hint
	for area in field_data.closed_areas:
		var polygon := PackedVector2Array()
		for point in area.polygon:
			polygon.append(Vector2(point[0], point[1]))
		if Geometry2D.is_point_in_polygon(screen_position, polygon):
			hint.text = area.hint
	if transition_lock > 0:
		return
	var destination := _exit_for_screen(screen_position)
	if not destination.is_empty():
		load_field(destination, field_id)
