extends Node3D

const HeroModel = preload("res://scripts/hero_model.gd")
var hero: Node3D
var appearance := "male"
var clip := "Idle"
var status: Label
var dragging := false

func _ready() -> void:
	appearance = HeroModel.selected()
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055,0.075,0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8,0.85,0.9)
	env.ambient_light_energy = 0.55
	world.environment = env
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35,-30,0)
	key.light_color = Color(1,0.9,0.78)
	key.light_energy = 1.5
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20,140,0)
	fill.light_energy = 0.45
	add_child(fill)
	var camera := Camera3D.new()
	camera.position = Vector3(2.5,1.8,4.8)
	add_child(camera)
	camera.look_at(Vector3(0,0.9,0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.4
	camera.current = true
	hero = HeroModel.new()
	add_child(hero)
	hero.setup(appearance)
	var ground := MeshInstance3D.new()
	var plane := CylinderMesh.new()
	plane.top_radius = 0.65
	plane.bottom_radius = 0.69
	plane.height = 0.06
	ground.mesh = plane
	ground.position.y = -0.035
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13,0.16,0.14)
	ground.material_override = mat
	add_child(ground)
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Label.new()
	title.text = "CHOOSE YOUR HERO"
	title.position = Vector2(50,30)
	title.add_theme_font_size_override("font_size",32)
	ui.add_child(title)
	var explanation := Label.new()
	explanation.text = "A neutral beginning. Your path comes later.\nAppearance does not restrict your class.\n\nDrag the model to turn it."
	explanation.position = Vector2(50,90)
	explanation.add_theme_font_size_override("font_size",20)
	ui.add_child(explanation)
	status = Label.new()
	status.position = Vector2(50,240)
	status.add_theme_font_size_override("font_size",24)
	ui.add_child(status)
	var row := HBoxContainer.new()
	row.position = Vector2(50,300)
	row.add_theme_constant_override("separation",15)
	ui.add_child(row)
	for choice in ["male", "female"]:
		var button := Button.new()
		button.text = choice.capitalize()
		button.custom_minimum_size = Vector2(150,65)
		row.add_child(button)
		button.pressed.connect(func(): choose(choice))
	var actions := VBoxContainer.new()
	actions.position = Vector2(1030,180)
	actions.add_theme_constant_override("separation",15)
	ui.add_child(actions)
	for name in ["Idle","Walk","Run"]:
		var button := Button.new()
		button.text = name
		button.custom_minimum_size = Vector2(180,60)
		actions.add_child(button)
		button.pressed.connect(func(): clip = name; hero.play_clip(name); _update_status())
	var use := Button.new()
	use.text = "Begin in Ravenwood"
	use.position = Vector2(850,610)
	use.size = Vector2(360,65)
	ui.add_child(use)
	use.pressed.connect(func():
		if HeroModel.save_choice(appearance) == OK:
			get_tree().change_scene_to_file("res://scenes/ravenwood.tscn")
		else:
			status.text = "Could not save hero choice. Please try again.")
	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(50,610)
	back.size = Vector2(180,65)
	ui.add_child(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_update_status()

func choose(choice: String) -> void:
	appearance = choice
	hero.setup(choice)
	hero.play_clip(clip)
	_update_status()

func _update_status() -> void:
	status.text = appearance.capitalize() + " adventurer • " + clip

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		hero.rotation.y += event.relative.x * 0.01
	elif event is InputEventScreenDrag:
		hero.rotation.y += event.relative.x * 0.01
