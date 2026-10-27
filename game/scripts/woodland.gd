extends Node3D

const Hero := preload("res://scripts/hero_model.gd")
const Joystick := preload("res://scripts/joystick.gd")
var room_id := "forest"
var room_data: Dictionary
var scenery: Node3D
var player: Node3D
var hero: Node3D
var camera: Camera3D
var joystick: Control
var heading: Label
var subtitle: Label
var prompt: Button
var running := false
var travel_target := INF
var transition_lock := 1.0
var batches: Dictionary = {}
var materials: Dictionary = {}
var rng := RandomNumberGenerator.new()
var room_generation := 0
var rock_mesh: ArrayMesh

func _ready() -> void:
	room_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/woodland_rooms.json"))
	_materials()
	_lighting()
	player = Node3D.new()
	add_child(player)
	hero = Hero.new()
	player.add_child(hero)
	hero.setup(Hero.selected())
	hero.scale = Vector3.ONE * 1.15
	camera = Camera3D.new()
	camera.fov = 43
	camera.far = 130
	add_child(camera)
	camera.current = true
	_ui()
	load_room("forest", 9.0)

func _materials() -> void:
	for key in ["ground", "road", "stone", "bark"]:
		var material := StandardMaterial3D.new()
		material.albedo_texture = load("res://assets/woodland/" + key + ".webp")
		material.roughness = 0.93
		material.albedo_color = {"ground":Color(0.5,0.57,0.43),"road":Color(0.65,0.56,0.43),"stone":Color(0.63,0.66,0.6),"bark":Color(0.65,0.55,0.45)}[key]
		material.uv1_scale = Vector3(0.5,0.5,0.5) if key == "bark" else Vector3.ONE
		materials[key] = material
	for pair in [["moss", Color("526a35")],["wood",Color("80704c")],["iron",Color("46483f")],["leaf",Color("8ca965")],["fern",Color("7d9a46")],["flower",Color("c4b5d8")],["light",Color("ffbb59")]]:
		var material := StandardMaterial3D.new()
		material.albedo_color = pair[1]
		material.roughness = 0.8
		if pair[0] in ["leaf", "fern"]:
			material.albedo_texture = load("res://assets/woodland/leaves.png")
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold = 0.4
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if pair[0] == "wood":
			material.albedo_texture = load("res://assets/woodland/bark.webp")
			material.albedo_color = Color(0.9,0.8,0.64)
		if pair[0] == "light":
			material.emission_enabled = true
			material.emission = Color("ffac43")
			material.emission_energy_multiplier = 1.6
		materials[pair[0]] = material

func _lighting() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("507e91")
	sky_material.sky_horizon_color = Color("cbd4ad")
	sky_material.ground_bottom_color = Color("324632")
	sky_material.ground_horizon_color = Color("a2b79a")
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a8c1aa")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("92afa0")
	environment.fog_density = 0.004
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-35,0)
	sun.light_color = Color("ffe3a5")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55
	sun.shadow_bias = 0.08
	add_child(sun)

func path_x(z: float) -> float:
	return sin(z * 0.19) * 2.2 if room_id == "forest" else sin(z * 0.12) * 1.0

func ground_height(x: float, z: float) -> float:
	var distance := absf(x - path_x(z))
	var side := maxf(0.0, distance - 3.0)
	var height := 0.18 + side * 0.10 + sin(x * 0.38 + z * 0.19) * sin(z * 0.31) * minf(side * 0.16, 1.4)
	if room_id == "crossing":
		if absf(z) < 2.8:
			return -1.5 + absf(z) * 0.24
		var bank_weight := clampf(4.0-distance,0.0,1.0)
		height = lerpf(height,maxf(height,walk_height(z)-0.015),bank_weight)
	return height

func walk_height(z: float) -> float:
	if room_id == "crossing":
		return 0.85 if absf(z) < 4.0 else lerpf(0.85,0.18,clampf((absf(z)-4.0)/3.0,0,1))
	return 0.18

func can_walk(point: Vector3) -> bool:
	var width := 1.0 if room_id == "crossing" and absf(point.z) < 4.0 else 2.35
	return absf(point.x - path_x(point.z)) <= width and absf(point.z) < 16.3

func load_room(id: String, spawn_z: float) -> void:
	assert(room_data.has(id))
	room_id = id
	room_generation += 1
	travel_target = INF
	transition_lock = 1.1
	if is_instance_valid(scenery):
		remove_child(scenery)
		scenery.queue_free()
	scenery = Node3D.new()
	scenery.name = "RoomScenery"
	add_child(scenery)
	batches.clear()
	rng.seed = 9305 if id == "forest" else 9319
	_terrain()
	_vegetation()
	if id == "forest":
		_gate()
	else:
		_bridge()
	_flush_batches()
	player.position = Vector3(path_x(spawn_z), walk_height(spawn_z), spawn_z)
	player.rotation.y = PI
	heading.text = room_data[id].title
	subtitle.text = room_data[id].subtitle
	_update_camera(true)

func _terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-48,29):
		for x in range(-32,32):
			for offset in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var p: Vector2 = Vector2(x,z) + offset
				surface.set_uv(p * 0.22)
				surface.add_vertex(Vector3(p.x,ground_height(p.x,p.y),p.y))
	surface.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.mesh = surface.commit()
	terrain.material_override = materials.ground
	scenery.add_child(terrain)
	var road := SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(136):
		var z := -40.0 + i * 0.5
		if room_id == "crossing" and absf(z) < 4:
			continue
		for corner in [Vector2(-1,0),Vector2(1,0),Vector2(-1,1),Vector2(1,0),Vector2(1,1),Vector2(-1,1)]:
			var depth: float = z + corner.y * 0.5
			var width := 2.4 + sin(depth * 1.7) * 0.10
			var x: float = path_x(depth) + corner.x * width
			road.set_uv(Vector2(corner.x * 0.8,depth * 0.3))
			road.add_vertex(Vector3(x,walk_height(depth) + 0.005,depth))
	road.generate_normals()
	var path := MeshInstance3D.new()
	path.mesh = road.commit()
	path.material_override = materials.road
	scenery.add_child(path)
	# Mossy stones edge the route and anchor the banks.
	for i in range(78):
		var z := rng.randf_range(-23,23)
		var x := path_x(z) + rng.randf_range(3.2,13.0) * (-1 if i % 2 else 1)
		var size := rng.randf_range(0.25,1.1)
		_rock(Vector3(x,ground_height(x,z),z),Vector3(size * 1.6,size,size * 1.2))
	for i in range(70):
		var z := rng.randf_range(-23,23)
		var x := path_x(z) + rng.randf_range(-2.3,2.3)
		if room_id == "crossing" and absf(z) < 4:
			continue
		_rock(Vector3(x,walk_height(z) + 0.01,z), Vector3(0.08,0.025,0.1) * rng.randf_range(0.7,2.0))

func _vegetation() -> void:
	for i in range(86):
		var z := rng.randf_range(-25,22)
		var x := path_x(z) + rng.randf_range(6.8 if i % 2 else 11.5,22) * (-1 if i % 2 else 1)
		if room_id == "crossing" and absf(z) < 3.7:
			continue
		_tree(Vector3(x,ground_height(x,z),z),rng.randf_range(6.5,12.0))
	for i in range(26):
		var x := rng.randf_range(-25,25)
		var z := rng.randf_range(-45,-28)
		_tree(Vector3(x,ground_height(x,z),z),rng.randf_range(10,16))
	for i in range(700):
		var z := rng.randf_range(-24,24)
		var x := path_x(z) + rng.randf_range(2.6,15.0) * (-1 if i % 2 else 1)
		if room_id == "crossing" and absf(z) < 3.3:
			continue
		var p := Vector3(x,ground_height(x,z) + 0.55,z)
		_card("fern",p,Vector3(rng.randf_range(-0.5,0.5),rng.randf_range(0,TAU),0),rng.randf_range(0.85,1.65))
	for i in range(90):
		var z := rng.randf_range(-22,22)
		var x := path_x(z) + rng.randf_range(2.7,4.5) * (-1 if i%2 else 1)
		if room_id == "crossing" and absf(z) < 4:
			continue
		var p := Vector3(x,ground_height(x,z),z)
		_segment(p,p + Vector3(0,0.38,0),0.015,"moss")
		_ball(p + Vector3(0,0.4,0),Vector3(0.07,0.05,0.07),"flower")

func _tree(p: Vector3, height: float) -> void:
	var lean := Vector3(rng.randf_range(-0.8,0.8),height,rng.randf_range(-0.6,0.6))
	_segment(p,p + lean,height * 0.035,"bark")
	for i in range(5):
		var angle := i * TAU/5 + rng.randf()
		var root := Vector3(cos(angle),0,sin(angle))
		_segment(p + Vector3(0,0.9,0),p + root * 1.2,0.14,"bark")
	for i in range(7):
		var angle := i * 2.399
		var base := p + lean * rng.randf_range(0.45,0.82)
		var tip := base + Vector3(cos(angle)*height*0.23,height*0.13,sin(angle)*height*0.23)
		_segment(base,tip,0.11,"bark")
		for j in range(9):
			var leaf := tip + Vector3(rng.randf_range(-1.5,1.5),rng.randf_range(-0.3,1.6),rng.randf_range(-1.5,1.5))
			_card("leaf",leaf,Vector3(rng.randf_range(-1.2,1.2),rng.randf_range(0,TAU),rng.randf_range(-0.5,0.5)),rng.randf_range(1.8,3.3))

func _rock(p: Vector3, size: Vector3) -> void:
	if rock_mesh == null:
		var sphere := SphereMesh.new()
		sphere.radial_segments = 18
		sphere.rings = 10
		sphere.radius = 1
		sphere.height = 2
		var arrays := sphere.get_mesh_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in range(vertices.size()):
			var v := vertices[i]
			var deformation := 0.87 + 0.14*sin(v.x*8.3+v.z*4.7) + 0.08*cos(v.y*11.0-v.x*5.1)
			vertices[i] = v * deformation
		arrays[Mesh.ARRAY_VERTEX] = vertices
		rock_mesh = ArrayMesh.new()
		rock_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	_queue("rock",rock_mesh,"stone",Transform3D(Basis.from_euler(Vector3(rng.randf()*0.5,rng.randf()*TAU,0)).scaled(size),p + Vector3(0,size.y*0.15,0)))

func _ball(p: Vector3, size: Vector3, material: String) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 5
	mesh.radius = 1
	mesh.height = 2
	_queue("ball_"+material,mesh,material,Transform3D(Basis.IDENTITY.scaled(size),p))

func _segment(a: Vector3, b: Vector3, radius: float, material: String) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.65
	mesh.bottom_radius = 1
	mesh.height = 1
	mesh.radial_segments = 9
	var direction := (b-a).normalized()
	var side := direction.cross(Vector3.FORWARD).normalized()
	if side.length_squared() < 0.1:
		side = Vector3.RIGHT
	var basis := Basis(side*radius,direction*a.distance_to(b),side.cross(direction)*radius)
	_queue("segment_"+material,mesh,material,Transform3D(basis,(a+b)*0.5))

func _box(p: Vector3, size: Vector3, material: String, rotation_y: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	_queue("box_"+material,mesh,material,Transform3D(Basis(Vector3.UP,rotation_y).scaled(size),p))

func _card(material: String, p: Vector3, rotation: Vector3, size: float) -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	_queue("card_"+material,mesh,material,Transform3D(Basis.from_euler(rotation).scaled(Vector3.ONE * size),p))

func _queue(key: String, mesh: Mesh, material: String, transform: Transform3D) -> void:
	if not batches.has(key):
		batches[key] = {"mesh":mesh,"material":material,"transforms":[]}
	batches[key].transforms.append(transform)

func _flush_batches() -> void:
	for key in batches:
		var batch: Dictionary = batches[key]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = batch.mesh
		multi.instance_count = batch.transforms.size()
		for i in range(batch.transforms.size()):
			multi.set_instance_transform(i,batch.transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.name = key
		instance.multimesh = multi
		instance.material_override = materials[batch.material]
		if key == "card_fern":
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		scenery.add_child(instance)

func _gate() -> void:
	var z := 14.6
	for side in [-1,1]:
		for i in range(16):
			var x: float = side * (3.2+i*0.43)
			_segment(Vector3(x,0,z),Vector3(x,3.3 + sin(i*1.7)*0.2,z),0.25,"bark")
		_box(Vector3(side*6.3,1.1,z-0.2),Vector3(7,0.15,0.16),"wood")
		_box(Vector3(side*6.3,2.5,z-0.2),Vector3(7,0.15,0.16),"wood")
		_segment(Vector3(side*3,0,z),Vector3(side*3,4.8,z),0.38,"bark")
		_lantern(Vector3(side*2.6,2.6,z-0.4))
	_box(Vector3(0,4.3,z),Vector3(6.6,0.5,0.55),"wood")
	_sign("BLACKTHORN",Vector3(0,3.7,z-0.35))
	_cart(Vector3(-4.3,ground_height(-4.3,3.0),3.0))
	# A ruined waystone gives the route a distinct focal point.
	for i in range(4):
		_box(Vector3(-4.1,0.4+i*0.55,-5.3),Vector3(0.9,0.5,0.8),"stone",i*0.07)
	_box(Vector3(-4.1,2.8,-5.3),Vector3(1.3,0.35,1.1),"stone")
	_sign("BRIAR CROSSING  ↑",Vector3(3.1,1.9,-11.8))
	_segment(Vector3(3.1,0,-11.8),Vector3(3.1,2.4,-11.8),0.12,"wood")

func _cart(p: Vector3) -> void:
	_box(p+Vector3(0,0.65,0),Vector3(1.5,0.16,2.1),"wood",0.15)
	for side in [-1,1]:
		for y in [0.85,1.1,1.35]:
			_box(p+Vector3(side*0.75,y,0),Vector3(0.1,0.18,2.1),"wood",0.15)
		_segment(p+Vector3(side*0.55,0.5,0.8),p+Vector3(side*0.55,0.4,3.0),0.065,"wood")
		var wheel := TorusMesh.new()
		wheel.inner_radius = 0.35
		wheel.outer_radius = 0.46
		wheel.rings = 12
		wheel.ring_segments = 6
		_queue("wheel",wheel,"wood",Transform3D(Basis(Vector3.FORWARD,PI*0.5),p+Vector3(side*0.9,0.5,0.15)))
		for angle in range(0,180,45):
			var offset := Vector3(0,cos(deg_to_rad(angle))*0.4,sin(deg_to_rad(angle))*0.4)
			_segment(p+Vector3(side*0.9,0.5,0.15)-offset,p+Vector3(side*0.9,0.5,0.15)+offset,0.025,"wood")

func _bridge() -> void:
	# Stream and timber bridge live only in this independently loaded room.
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(49,5.8)
	plane.subdivide_width = 30
	plane.subdivide_depth = 12
	water.mesh = plane
	water.position.y = -0.6
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode cull_disabled; void vertex(){VERTEX.y += sin(VERTEX.x*1.4+TIME*1.5)*0.035;} void fragment(){float wave=sin(UV.x*170.0+UV.y*28.0-TIME*2.0)*sin(UV.x*75.0-UV.y*39.0+TIME); ALBEDO=mix(vec3(0.035,0.12,0.12),vec3(0.12,0.26,0.22),wave*0.25+0.5); NORMAL=normalize(vec3(sin(UV.x*250.0+TIME)*0.08,1.0,cos(UV.y*20.0+TIME)*0.08)); ROUGHNESS=0.34; METALLIC=0.05;}"
	var water_material := ShaderMaterial.new()
	water_material.shader = shader
	water.material_override = water_material
	scenery.add_child(water)
	for i in range(28):
		var z := -4.2 + i*0.31
		_box(Vector3(path_x(z),0.74,z),Vector3(2.9,0.22,0.29),"wood",sin(i*3.1)*0.012)
		if i%3 == 0:
			for side in [-1,1]:
				_box(Vector3(side*1.48,0.85,z),Vector3(0.16,0.12,0.1),"iron")
	for side in [-1,1]:
		_segment(Vector3(side*1.6,0.45,-4.5),Vector3(side*1.6,0.45,4.5),0.17,"bark")
		_segment(Vector3(side*1.6,1.75,-4.5),Vector3(side*1.6,1.75,4.5),0.075,"wood")
		for z in [-4.0,0.0,4.0]:
			_segment(Vector3(side*1.6,-0.5,z),Vector3(side*1.6,2.05,z),0.13,"bark")
			if absf(z)>1:
				_lantern(Vector3(side*1.6,2.1,z))
	for i in range(34):
		var x := rng.randf_range(-22,22)
		var z := rng.randf_range(-2.5,2.5)
		if absf(x)<2.5:
			continue
		_rock(Vector3(x,-1.0,z),Vector3(0.7,0.6,0.5)*rng.randf_range(0.5,1.8))
	_sign("THORNWATCH TRAIL",Vector3(3.2,2.0,-12.5))
	_segment(Vector3(3.2,0,-12.5),Vector3(3.2,2.4,-12.5),0.12,"wood")

func _lantern(p: Vector3) -> void:
	_box(p,Vector3(0.22,0.36,0.22),"light")
	for side in [-1,1]:
		_box(p+Vector3(side*0.14,0,0),Vector3(0.035,0.45,0.3),"iron")
	_box(p+Vector3(0,0.24,0),Vector3(0.4,0.08,0.4),"iron")

func _sign(text: String, p: Vector3) -> void:
	_box(p,Vector3(2.7,0.55,0.12),"wood")
	var label := Label3D.new()
	label.text = text
	label.font_size = 36
	label.pixel_size = 0.008
	label.position = p + Vector3(0,0,0.075)
	label.modulate = Color("efdfb5")
	label.outline_size = 3
	scenery.add_child(label)

func _ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(24,20)
	panel.size = Vector2(720,83)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.06,0.045,0.8)
	style.content_margin_left = 18
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	style.border_color = Color("aa9a60")
	style.border_width_left = 3
	panel.add_theme_stylebox_override("panel",style)
	canvas.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size",25)
	column.add_child(heading)
	subtitle = Label.new()
	subtitle.add_theme_font_size_override("font_size",17)
	column.add_child(subtitle)
	joystick = Joystick.new()
	joystick.position = Vector2(35,500)
	joystick.size = Vector2(180,180)
	canvas.add_child(joystick)
	var run := Button.new()
	run.text = "RUN"
	run.toggle_mode = true
	run.position = Vector2(1115,530)
	run.size = Vector2(135,62)
	run.toggled.connect(func(active: bool): running=active)
	canvas.add_child(run)
	prompt = Button.new()
	prompt.position = Vector2(980,610)
	prompt.size = Vector2(270,64)
	prompt.pressed.connect(_interact)
	canvas.add_child(prompt)
	var map := Button.new()
	map.text = "WORLD MAP"
	map.position = Vector2(1080,24)
	map.size = Vector2(170,58)
	map.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/world_map.tscn"))
	canvas.add_child(map)

func _physics_process(delta: float) -> void:
	transition_lock = maxf(0,transition_lock-delta)
	var input: Vector2 = joystick.direction
	input += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var direction := Vector3.ZERO
	if input.length()>0.1:
		travel_target=INF
		var right := camera.global_basis.x
		right.y=0
		var forward := camera.global_basis.z
		forward.y=0
		direction=(right.normalized()*input.x+forward.normalized()*input.y).limit_length(1)
	elif travel_target != INF:
		var difference := travel_target-player.position.z
		if absf(difference)<0.15:
			travel_target=INF
		else:
			var ahead := player.position.z+signf(difference)*0.6
			direction=(Vector3(path_x(ahead),player.position.y,ahead)-player.position).normalized()
	var speed := 3.25 if running else 1.45
	var moved := move_actor(direction*speed*delta)
	hero.update_locomotion(moved/maxf(delta,0.001),hero.scale.x,running)
	if moved>0.001:
		player.rotation.y=lerp_angle(player.rotation.y,atan2(direction.x,direction.z),minf(1,delta*10))
	_update_camera(false,delta)
	prompt.visible = player.position.z>11.5 or player.position.z < -11.5
	prompt.text = "ENTER BLACKTHORN" if player.position.z>11.5 and room_id=="forest" else "BACK TO OLDWOOD ROAD" if player.position.z>11.5 else "BRIAR CROSSING →" if room_id=="forest" else "THORNWATCH · SOON"
	if transition_lock<=0:
		if player.position.z < -15 and room_id=="forest":
			load_room("crossing",13)
		elif player.position.z>15 and room_id=="crossing":
			load_room("forest",-13)

func move_actor(displacement: Vector3) -> float:
	var before := player.position
	var candidate := before+displacement
	if can_walk(candidate):
		player.position=candidate
	else:
		var z_only := before+Vector3(0,0,displacement.z)
		if can_walk(z_only):
			player.position=z_only
		var x_only := player.position+Vector3(displacement.x,0,0)
		if can_walk(x_only):
			player.position=x_only
	player.position.y=walk_height(player.position.z)
	return Vector2(player.position.x-before.x,player.position.z-before.z).length()

func _update_camera(immediate: bool, delta: float = 0.0) -> void:
	var focus := Vector3(player.position.x*0.3,1.0,player.position.z-3.5)
	var target := focus+Vector3(4.5,8.5,14)
	camera.position=target if immediate else camera.position.lerp(target,1-exp(-delta*3))
	camera.look_at(focus)

func _interact() -> void:
	if player.position.z>11.5:
		if room_id=="forest":
			get_tree().change_scene_to_file("res://scenes/ravenwood.tscn" if FileAccess.file_exists("user://hero.cfg") else "res://scenes/hero_select.tscn")
		else:
			load_room("forest",-13)
	elif player.position.z < -11.5:
		if room_id=="forest":
			load_room("crossing",13)
		else:
			subtitle.text="Thornwatch is beyond this trail. Its dungeon is not built yet."

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_E:
		_interact()
	var point := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		point=event.position
	elif event is InputEventScreenTouch and event.pressed:
		point=event.position
	else:
		return
	var best := 100.0
	var destination := INF
	for i in range(121):
		var z := -15.0+i*0.25
		var world := Vector3(path_x(z),walk_height(z),z)
		var distance := camera.unproject_position(world).distance_to(point)
		if distance<best:
			best=distance
			destination=z
	travel_target=destination
