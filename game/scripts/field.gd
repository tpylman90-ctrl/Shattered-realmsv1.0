extends Node3D

const ROOT := "res://assets/generated/ravenwood/"
var field_id := "gate"
var camera: Camera3D
var player: CharacterBody3D
var backdrop: TextureRect
var foreground: TextureRect
var heading: Label
var hint: Label
var joystick: Control
var transition_lock := 0.0
var destination := Vector3.ZERO
var walking_to_target := false
var moving_time := 0.0
var body_visual: Node3D

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
	load_field("gate", Vector3(0, 0, 2.5))

func _build_layers() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)
	backdrop = TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(backdrop)
	var front_layer := CanvasLayer.new()
	front_layer.layer = 2
	add_child(front_layer)
	foreground = TextureRect.new()
	foreground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_layer.add_child(foreground)
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
	var shadow := CylinderMesh.new()
	shadow.top_radius = 0.32
	shadow.bottom_radius = 0.32
	shadow.height = 0.004
	_mesh(shadow, Color(0.10, 0.095, 0.07), Vector3(0, 0.008, 0), player)

func load_field(id: String, spawn: Vector3) -> void:
	field_id = id
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + id + ".json"))
	backdrop.texture = load(ROOT + id + ".png")
	foreground.texture = load(ROOT + id + "_foreground.png")
	var pos: Array = data.camera_position
	var target: Array = data.camera_target
	camera.position = Vector3(pos[0], pos[1], pos[2])
	camera.look_at(Vector3(target[0], target[1], target[2]))
	camera.fov = data.fov
	if has_node("WalkMesh"):
		get_node("WalkMesh").free()
	var floor_body := StaticBody3D.new()
	floor_body.name = "WalkMesh"
	var collision := CollisionShape3D.new()
	var mesh_shape := ConcavePolygonShape3D.new()
	var faces := PackedVector3Array()
	for index in data.triangles:
		var point: Array = data.walkmesh[index]
		faces.append(Vector3(point[0], point[1], point[2]))
	mesh_shape.set_faces(faces)
	collision.shape = mesh_shape
	floor_body.add_child(collision)
	add_child(floor_body)
	player.position = spawn
	player.velocity = Vector3.ZERO
	walking_to_target = false
	transition_lock = 0.7
	heading.text = "RAVENWOOD  /  " + {"gate": "Gate courtyard", "market": "Market square", "camp": "Army camp"}[id]
	hint.text = {"gate": "Market ← west passage     •     east passage → Army camp", "market": "Market square     •     east passage → Gate", "camp": "Muster yard     •     west passage → Gate"}[id]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_target(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_set_target(event.position)

func _set_target(screen: Vector2) -> void:
	var plane := Plane(Vector3.UP, 0)
	var hit = plane.intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	if hit != null:
		destination = Vector3(clampf(hit.x, -9.45, 9.45), 0, clampf(hit.z, 0.05, 3.1))
		walking_to_target = true

func _physics_process(delta: float) -> void:
	transition_lock = maxf(0, transition_lock - delta)
	var input := Vector2.ZERO
	input.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	input.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	if joystick.direction.length() > 0.1:
		input = joystick.direction
	if input.length() > 0.1:
		walking_to_target = false
	elif walking_to_target:
		var offset := destination - player.position
		if Vector2(offset.x, offset.z).length() < 0.12:
			walking_to_target = false
		else:
			input = Vector2(offset.x, offset.z).normalized()
	input = input.limit_length()
	player.velocity = Vector3(input.x * 3, -1, input.y * 3)
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -9.5, 9.5)
	player.position.z = clampf(player.position.z, 0.05, 3.1)
	player.position.y = maxf(0, player.position.y)
	if input.length() > 0.1:
		body_visual.rotation.y = lerp_angle(body_visual.rotation.y, atan2(input.x, input.y), delta * 12)
		moving_time += delta * 10
		body_visual.position.y = sin(moving_time) * 0.025
	else:
		body_visual.position.y = 0
	if transition_lock > 0 or absf(player.position.z) > 1.6:
		return
	if field_id == "gate":
		if player.position.x < -9.2:
			load_field("market", Vector3(8.3, 0, 1))
		elif player.position.x > 9.2:
			load_field("camp", Vector3(-8.3, 0, 1))
	elif field_id == "market" and player.position.x > 9.2:
		load_field("gate", Vector3(-8.3, 0, 1))
	elif field_id == "camp" and player.position.x < -9.2:
		load_field("gate", Vector3(8.3, 0, 1))
