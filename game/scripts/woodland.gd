extends Node3D

const Hero := preload("res://scripts/hero_model.gd")
const Joystick := preload("res://scripts/joystick.gd")
const EXPLORATION_SAVE := "user://ravenwood_exploration.cfg"
var save_enabled := true
var visited_rooms: Array = []
var territory_map: Control
var travel_speeds: Dictionary
var route_graph := AStar3D.new()
var tap_route := PackedVector3Array()
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
var equipment: EquipmentState

func _ready() -> void:
	equipment=EquipmentState.new()
	room_data = _room_registry()
	travel_speeds = JSON.parse_string(FileAccess.get_file_as_string("res://data/travel_speeds.json"))
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
	var forced_entry := str(get_tree().get_meta("woodland_entry",""))
	if get_tree().has_meta("woodland_entry"):
		get_tree().remove_meta("woodland_entry")
	var config := ConfigFile.new()
	if save_enabled and config.load(EXPLORATION_SAVE)==OK:
		var saved_room := str(config.get_value("exploration","room","forest"))
		var saved_position: Variant = config.get_value("exploration","position",Vector3.ZERO)
		var saved_visits: Variant = config.get_value("exploration","visited",[])
		if saved_visits is Array:
			visited_rooms = saved_visits
		if room_data.has(forced_entry):
			load_room(forced_entry,9.0 if forced_entry=="forest" else -float(room_data[forced_entry].length)+4.0)
			return
		if room_data.has(saved_room) and saved_position is Vector3:
			load_room(saved_room,saved_position.z)
			if can_walk(saved_position):
				player.position = Vector3(saved_position.x,walk_height(saved_position.z),saved_position.z)
			_update_camera(true)
			persist_exploration()
			return
	if room_data.has(forced_entry):
		load_room(forced_entry,9.0 if forced_entry=="forest" else -float(room_data[forced_entry].length)+4.0)
		return
	load_room(_initial_room(),9.0)

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

func room_length() -> float:
	return float(room_data[room_id].length)

func path_x(z: float) -> float:
	if room_id == "forest":
		return sin(z*0.19)*2.2
	if room_id == "crossing":
		return sin(z*0.12)
	return sin(z*0.13+float(int(room_data[room_id].seed) % 7))*1.5

func branch_z(x: float) -> float:
	return -4.0+sin(x*0.16)*0.6

func branch_available(side: String) -> bool:
	return room_data[room_id].exits.has(side)

func route_distance(x: float, z: float) -> float:
	var distance := absf(x-path_x(z))
	var center := path_x(-4.0)
	if (branch_available("west") and x<center) or (branch_available("east") and x>center):
		distance = minf(distance,absf(z-branch_z(x)))
	return distance

func ground_height(x: float, z: float) -> float:
	var distance := route_distance(x,z)
	var side := maxf(0.0, distance - 3.0)
	var height := walk_height(z) + side * 0.10 + sin(x * 0.38 + z * 0.19) * sin(z * 0.31) * minf(side * 0.16, 1.4)
	if room_data[room_id].theme == "spring":
		var basin := pow((x+8.0)/5.0,2)+pow((z+5.0)/4.0,2)
		if basin<1.0:
			height=lerpf(-0.95,height,basin)
	if room_id == "crossing":
		if absf(z) < 2.8:
			return -1.5 + absf(z) * 0.24
		var bank_weight := clampf(4.0-distance,0.0,1.0)
		height = lerpf(height,maxf(height,walk_height(z)-0.015),bank_weight)
	return height

func walk_height(z: float) -> float:
	if room_id == "crossing":
		return 0.85 if absf(z) < 4.0 else lerpf(0.85,0.18,clampf((absf(z)-4.0)/3.0,0,1))
	if room_data[room_id].theme in ["ridge","mine","watch"]:
		return 0.18+(room_length()-z)*0.045
	return 0.18

func can_walk(point: Vector3) -> bool:
	var width := 1.0 if room_id=="crossing" and absf(point.z)<4.0 else 2.35
	if absf(point.z)>=room_length() or absf(point.x)>16.3:
		return false
	return route_distance(point.x,point.z)<=width

func load_room(id: String, spawn_z: float, arrival_side: String = "") -> void:
	assert(room_data.has(id))
	room_id = id
	room_generation += 1
	travel_target = INF
	tap_route.clear()
	transition_lock = 1.1
	if is_instance_valid(scenery):
		remove_child(scenery)
		scenery.queue_free()
	scenery = Node3D.new()
	scenery.name = "RoomScenery"
	add_child(scenery)
	batches.clear()
	rng.seed = int(room_data[id].seed)
	_terrain()
	_vegetation()
	if id == "forest":
		_gate()
	elif id == "crossing":
		_bridge()
	else:
		_landmark()
	_exit_signs()
	_flush_batches()
	_build_route_graph()
	spawn_z=clampf(spawn_z,-room_length()+3.0,room_length()-3.0)
	player.position = Vector3(path_x(spawn_z), walk_height(spawn_z), spawn_z)
	if not arrival_side.is_empty():
		player.position = arrival_position(arrival_side)
	if not id in visited_rooms:
		visited_rooms.append(id)
	player.rotation.y = PI
	heading.text = room_data[id].title
	subtitle.text = room_data[id].subtitle
	_update_camera(true)
	persist_exploration()

func _terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-int(room_length())-32,int(room_length())+15):
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
	for i in range(int((room_length()*2.0+30.0)*2.0)):
		var z := -room_length()-18.0+i*0.5
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
	_branch_roads()
	# Mossy stones edge the route and anchor the banks.
	for i in range(78):
		var z := rng.randf_range(-room_length()-6,room_length()+5)
		var x := path_x(z) + rng.randf_range(3.2,13.0) * (-1 if i % 2 else 1)
		if route_distance(x,z)<3.0 or landmark_zone(x,z):
			continue
		var size := rng.randf_range(0.25,1.1)
		_rock(Vector3(x,ground_height(x,z),z),Vector3(size * 1.6,size,size * 1.2))
	for i in range(70):
		var z := rng.randf_range(-room_length()-6,room_length()+5)
		var x := path_x(z) + rng.randf_range(-2.3,2.3)
		if room_id == "crossing" and absf(z) < 4:
			continue
		_rock(Vector3(x,walk_height(z) + 0.01,z), Vector3(0.08,0.025,0.1) * rng.randf_range(0.7,2.0))

func _vegetation() -> void:
	for i in range(86 if room_length()<18 else 140):
		var z := rng.randf_range(-room_length()-10,room_length()+7)
		var x := path_x(z) + rng.randf_range(6.8 if i % 2 else 11.5,22) * (-1 if i % 2 else 1)
		if room_id == "crossing" and absf(z) < 3.7:
			continue
		if route_distance(x,z)<5.0 or landmark_zone(x,z):
			continue
		_tree(Vector3(x,ground_height(x,z),z),rng.randf_range(6.5,12.0))
	for i in range(26):
		var x := rng.randf_range(-25,25)
		var z := rng.randf_range(-room_length()-31,-room_length()-12)
		_tree(Vector3(x,ground_height(x,z),z),rng.randf_range(10,16))
	for i in range(int(700*room_length()/16.3)):
		var z := rng.randf_range(-room_length()-6,room_length()+6)
		var x := path_x(z) + rng.randf_range(2.6,15.0) * (-1 if i % 2 else 1)
		if room_id == "crossing" and absf(z) < 3.3:
			continue
		if route_distance(x,z)<2.6:
			continue
		var p := Vector3(x,ground_height(x,z) + 0.55,z)
		_card("fern",p,Vector3(rng.randf_range(-0.5,0.5),rng.randf_range(0,TAU),0),rng.randf_range(0.85,1.65))
	for i in range(90):
		var z := rng.randf_range(-room_length()-4,room_length()+4)
		var x := path_x(z) + rng.randf_range(2.7,4.5) * (-1 if i%2 else 1)
		if room_id == "crossing" and absf(z) < 4:
			continue
		if route_distance(x,z)<2.6:
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
		var x := rng.randf_range(-room_length()-4,room_length()+4)
		var z := rng.randf_range(-2.5,2.5)
		if absf(x)<2.5:
			continue
		_rock(Vector3(x,-1.0,z),Vector3(0.7,0.6,0.5)*rng.randf_range(0.5,1.8))

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
	map.pressed.connect(func():
		persist_exploration()
		get_tree().change_scene_to_file("res://scenes/world_map.tscn"))
	canvas.add_child(map)
	var pack := Button.new()
	pack.text="PACK / EQUIPMENT"
	pack.position=Vector2(1000,100)
	pack.size=Vector2(250,52)
	pack.pressed.connect(func():
		persist_exploration()
		get_tree().set_meta("equipment_return_scene",_self_scene())
		get_tree().change_scene_to_file("res://scenes/equipment.tscn"))
	canvas.add_child(pack)
	var local_map := Button.new()
	local_map.text = "RAVENWOOD MAP"
	local_map.position = Vector2(855,24)
	local_map.size = Vector2(210,58)
	canvas.add_child(local_map)
	territory_map = _make_territory_map()
	canvas.add_child(territory_map)
	territory_map.hide()
	local_map.pressed.connect(func():
		travel_target=INF
		tap_route.clear()
		_reset_joystick(false)
		hero.play_clip("Idle")
		territory_map.open(room_id,visited_rooms))
	territory_map.closed.connect(func(): _reset_joystick(true))

func _physics_process(delta: float) -> void:
	if territory_map.visible:
		return
	transition_lock = maxf(0,transition_lock-delta)
	var input: Vector2 = joystick.direction
	input += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var direction := Vector3.ZERO
	if input.length()>0.1:
		travel_target=INF
		tap_route.clear()
		var right := camera.global_basis.x
		right.y=0
		var forward := camera.global_basis.z
		forward.y=0
		direction=(right.normalized()*input.x+forward.normalized()*input.y).limit_length(1)
	elif not tap_route.is_empty():
		while not tap_route.is_empty() and Vector2(player.position.x-tap_route[0].x,player.position.z-tap_route[0].z).length()<0.18:
			tap_route.remove_at(0)
		if not tap_route.is_empty():
			direction=(tap_route[0]-player.position)*Vector3(1,0,1)
			direction=direction.normalized()
	elif travel_target != INF:
		var difference := travel_target-player.position.z
		if absf(difference)<0.15:
			travel_target=INF
		else:
			var ahead := player.position.z+signf(difference)*0.6
			direction=(Vector3(path_x(ahead),player.position.y,ahead)-player.position).normalized()
	var speed := travel_speed()
	var moved := move_actor(direction*speed*delta)
	hero.update_locomotion(moved/maxf(delta,0.001),hero.scale.x,running)
	if moved>0.001:
		player.rotation.y=lerp_angle(player.rotation.y,atan2(direction.x,direction.z),minf(1,delta*10))
	_update_camera(false,delta)
	var side := nearby_exit(4.0)
	var cache := current_cache()
	var can_gather := not cache.is_empty() and not room_id in equipment.claimed and absf(player.position.z)<3.0
	prompt.visible = not side.is_empty() or can_gather
	if can_gather and side.is_empty(): prompt.text="COLLECT SUPPLIES"
	if not side.is_empty():
		var destination: String = room_data[room_id].exits[side].to
		prompt.text = _exit_text(destination)
	if transition_lock<=0:
		var edge := nearby_exit(0.9)
		if not edge.is_empty() and room_data.has(room_data[room_id].exits[edge].to):
			enter_exit(edge)

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
	var focus := Vector3(player.position.x,player.position.y+1.0,player.position.z-3.5)
	var target := focus+Vector3(4.5,8.5,14)
	camera.position=target if immediate else camera.position.lerp(target,1-exp(-delta*3))
	camera.look_at(focus)

func _interact() -> void:
	var cache := current_cache()
	if not cache.is_empty() and absf(player.position.z)<3.0 and equipment.claim_cache(room_id,cache):
		subtitle.text="Supplies added to your pack. Visit Equipment & Smithy to forge."
		return
	var side := nearby_exit(4.0)
	if not side.is_empty():
		enter_exit(side)

func _unhandled_input(event: InputEvent) -> void:
	if territory_map.visible:
		if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:
			territory_map.hide()
			_reset_joystick(true)
		return
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
	var destination := -1
	for id in route_graph.get_point_ids():
		var world := route_graph.get_point_position(id)
		if camera.is_position_behind(world):
			continue
		var distance := camera.unproject_position(world).distance_to(point)
		if distance<best:
			best=distance
			destination=id
	if destination>=0:
		var start := route_graph.get_closest_point(player.position)
		tap_route=route_graph.get_point_path(start,destination)
		travel_target=INF

func travel_speed() -> float:
	return float(travel_speeds.wilderness_run if running else travel_speeds.wilderness_walk)*float(travel_speeds.run_multiplier if running else travel_speeds.walk_multiplier)

func exit_position(side: String) -> Vector3:
	if side in ["north","south"]:
		var z := (room_length()-1.3)*(-1 if side=="north" else 1)
		return Vector3(path_x(z),walk_height(z),z)
	var x := -15.0 if side=="west" else 15.0
	return Vector3(x,walk_height(branch_z(x)),branch_z(x))

func arrival_position(side: String) -> Vector3:
	var point := exit_position(side)
	if side in ["north","south"]:
		point.z += 2.7 if side=="north" else -2.7
		point.x=path_x(point.z)
	else:
		point.x += 2.7 if side=="west" else -2.7
		point.z=branch_z(point.x)
	point.y=walk_height(point.z)
	return point

func nearby_exit(radius: float) -> String:
	for side in room_data[room_id].exits:
		var point := exit_position(side)
		if Vector2(point.x-player.position.x,point.z-player.position.z).length()<radius:
			return side
	return ""

func enter_exit(side: String) -> void:
	if not room_data[room_id].exits.has(side):
		return
	var exit: Dictionary = room_data[room_id].exits[side]
	if room_data.has(exit.to):
		load_room(exit.to,0.0,exit.arrival)
	elif exit.to=="town":
		persist_exploration()
		get_tree().change_scene_to_file("res://scenes/ravenwood.tscn" if FileAccess.file_exists("user://hero.cfg") else "res://scenes/hero_select.tscn")
	else:
		persist_exploration()
		var campaign:=CampaignState.new()
		campaign.current="ravenwood"
		campaign.save()
		get_tree().set_meta("campaign_region","ravenwood")
		get_tree().set_meta("campaign_room","d0")
		get_tree().change_scene_to_file("res://scenes/campaign_area.tscn")

func persist_exploration(path: String = EXPLORATION_SAVE) -> Error:
	if not save_enabled:
		return OK
	var config := ConfigFile.new()
	config.set_value("exploration","room",room_id)
	config.set_value("exploration","position",player.position)
	config.set_value("exploration","visited",visited_rooms)
	return config.save(path)

func _reset_joystick(enabled: bool) -> void:
	joystick.direction=Vector2.ZERO
	joystick.knob=Vector2.ZERO
	joystick.finger=-1
	joystick.queue_redraw()
	joystick.set_process_input(enabled)

func _build_route_graph() -> void:
	route_graph.clear()
	var last := -1
	var steps := int((room_length()-1.0)*2.0/0.6)
	for i in range(steps+1):
		var z := lerpf(-room_length()+1.0,room_length()-1.0,float(i)/steps)
		var id := route_graph.get_point_count()
		route_graph.add_point(id,Vector3(path_x(z),walk_height(z),z))
		if last>=0:
			route_graph.connect_points(last,id)
		last=id
	for side in ["west","east"]:
		if not branch_available(side):
			continue
		var start := path_x(-4.0)
		var finish := -15.0 if side=="west" else 15.0
		last=route_graph.get_closest_point(Vector3(start,walk_height(-4),-4))
		for i in range(1,31):
			var x := lerpf(start,finish,float(i)/30)
			var z := branch_z(x)
			var id := route_graph.get_point_count()
			route_graph.add_point(id,Vector3(x,walk_height(z),z))
			route_graph.connect_points(last,id)
			last=id

func _branch_roads() -> void:
	for side in ["west","east"]:
		if not branch_available(side):
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var start := path_x(-4.0)
		var finish := -18.0 if side=="west" else 18.0
		for i in range(48):
			var x1 := lerpf(start,finish,float(i)/48)
			var x2 := lerpf(start,finish,float(i+1)/48)
			var corners := [Vector2(x1,-1),Vector2(x2,-1),Vector2(x1,1),Vector2(x2,-1),Vector2(x2,1),Vector2(x1,1)]
			if side=="west":
				corners.reverse()
			for corner in corners:
				var z: float = branch_z(corner.x)+corner.y*2.35
				surface.set_uv(Vector2(corner.x*0.3,corner.y*0.8))
				surface.add_vertex(Vector3(corner.x,walk_height(z)+0.01,z))
		surface.generate_normals()
		var path := MeshInstance3D.new()
		path.mesh=surface.commit()
		path.material_override=materials.road
		scenery.add_child(path)

func _exit_signs() -> void:
	for side in room_data[room_id].exits:
		var destination: String = room_data[room_id].exits[side].to
		if not room_data.has(destination):
			continue
		var point := exit_position(side)
		point.z += 3.0 if side=="north" else -3.0 if side=="south" else 0.0
		point.x += 4.0 if side in ["north","south"] else 0.0
		if side in ["west","east"]:
			point.z += 3.5
		point.y=walk_height(point.z)
		_segment(point,point+Vector3(0,2.1,0),0.1,"wood")
		_sign(room_data[destination].name.to_upper(),point+Vector3(0,1.7,0))

func _landmark() -> void:
	var theme: String = room_data[room_id].theme
	match theme:
		"crossroads":
			_segment(Vector3(-4.0,0.18,1),Vector3(-4.0,3.3,1),0.18,"wood")
			_sign("NORTH RIDGE  ←",Vector3(-4,2.6,1))
			_sign("TIMBER CAMP  →",Vector3(-4,2.0,1))
			for i in range(9):
				var angle := i*TAU/9
				_rock(Vector3(5+cos(angle)*1.2,0.18,3+sin(angle)*1.2),Vector3(0.35,0.22,0.3))
			_segment(Vector3(4.3,0.3,2.8),Vector3(5.6,0.4,3.2),0.12,"bark")
			_cart(Vector3(-5.0,ground_height(-5,8),8))
		"timber":
			for stack in range(3):
				for level in range(3):
					for log in range(4-level):
						var p := Vector3(-5.2+log*0.48+level*0.22,ground_height(-5.2+log*0.48+level*0.22,8-stack*7)+0.3+level*0.42,8-stack*7)
						_segment(p+Vector3(0,0,-2),p+Vector3(0,0,2),0.25,"bark")
			_cart(Vector3(5,ground_height(5,6),6))
			for i in range(9):
				var p := Vector3(4.4+(i%3)*1.4,ground_height(4.4+(i%3)*1.4,-9-i*0.7),-9-i*0.7)
				_segment(p,p+Vector3(0,0.4,0),0.45,"bark")
			_box(Vector3(-4,1.1,-3),Vector3(1.2,0.15,3),"wood")
			for z in [-4.0,-2.0]:
				_segment(Vector3(-4,0.2,z),Vector3(-4,1.0,z),0.13,"wood")
		"spring":
			_water_patch(Vector3(-8,-0.4,-5),Vector2(10,8),false)
			for i in range(8):
				_rock(Vector3(-11+(i%3)*1.4,0.15+(i/3)*0.7,-9),Vector3(1.6,1.5,1.0))
			_water_patch(Vector3(-9.8,1.0,-8),Vector2(1.2,3.2),true)
			for i in range(30):
				var angle := i*TAU/30
				var p := Vector3(-8+cos(angle)*5.5,0,-5+sin(angle)*4.4)
				p.y=ground_height(p.x,p.z)+0.5
				_card("fern",p,Vector3(0,angle,0),1.6)
		"ridge":
			for i in range(12):
				var z := -18.0+i*3
				_rock(Vector3(-7,ground_height(-7,z),z),Vector3(2.1,2.5+sin(i)*0.7,2.4))
			for i in range(7):
				var z := -12.0+i*2.0
				var x := path_x(z)+3.2
				_segment(Vector3(x,walk_height(z),z),Vector3(x,walk_height(z)+1.1,z),0.09,"wood")
				if i<6:
					_segment(Vector3(x,walk_height(z)+0.85,z),Vector3(path_x(z+2)+3.2,walk_height(z+2)+0.85,z+2),0.065,"wood")
		"mine":
			for i in range(6):
				_rock(Vector3(-7+(i%2)*2,ground_height(-7,-7)+(i/2)*1.5,-8),Vector3(2.5,2.8,1.4))
			var hole := StandardMaterial3D.new()
			hole.albedo_color=Color(0.012,0.018,0.014)
			materials["mine_dark"]=hole
			var base := Vector3(-5,ground_height(-5,-6),-6)
			_box(base+Vector3(0,1.25,0),Vector3(2.5,2.5,0.2),"mine_dark")
			for side in [-1,1]:
				_segment(base+Vector3(side*1.35,0,0.3),base+Vector3(side*1.35,2.8,0.3),0.19,"bark")
				_lantern(base+Vector3(side*1.6,1.7,0.5))
			_segment(base+Vector3(-1.55,2.8,0.3),base+Vector3(1.55,2.8,0.3),0.22,"wood")
			for i in range(4):
				_segment(base+Vector3(-1+i*0.65,0,0.2),base+Vector3(-1+i*0.65,2.5,0.2),0.035,"iron")
			_cart(Vector3(5,ground_height(5,4),4))
		"watch":
			var base := Vector3(-6,ground_height(-6,-7),-7)
			for layer in range(9):
				for i in range(10):
					if layer>5 and i in [1,2,5,6]:
						continue
					var angle := i*TAU/10+(layer%2)*0.12
					_box(base+Vector3(cos(angle)*2,layer*0.55+0.3,sin(angle)*2),Vector3(1.3,0.5,0.65),"stone",-angle)
			for i in range(8):
				_rock(base+Vector3(2.5+sin(i)*1.2,0,cos(i)*3),Vector3(0.7,0.6,0.9))
			_segment(base+Vector3(0,4,0),base+Vector3(0,7.2,0),0.09,"wood")
			_box(base+Vector3(0.6,6.7,0),Vector3(1.2,0.65,0.06),"moss")
		"grove":
			_tree(Vector3(-7,ground_height(-7,2),2),18)
			for i in range(8):
				var angle := i*TAU/8
				var p := Vector3(-7+cos(angle)*3.1,ground_height(-7,2),2+sin(angle)*3.1)
				_rock(p,Vector3(0.6,1.0+(i%3)*0.3,0.55))
		"ruins":
			var z := -room_length()+8.0
			var center := path_x(z)
			for side in [-1,1]:
				for level in range(6):
					_box(Vector3(center+side*2.9,0.45+level*0.58,z),Vector3(0.95,0.55,1.1),"stone",side*0.03*level)
			for i in range(9):
				var angle := PI*float(i)/8
				_box(Vector3(center+cos(angle)*2.8,3.3+sin(angle)*1.6,z),Vector3(1.18,0.74,1.1),"stone",0)
			for i in range(12):
				_box(Vector3(-6+(i%3)*0.8,0.4+(i/3)*0.55,z+4),Vector3(0.75,0.5,1),"stone",sin(i)*0.12)
			for i in range(15):
				_rock(Vector3(4+rng.randf()*3,0.1,z+rng.randf()*6),Vector3(0.5,0.4,0.7))

func _water_patch(p: Vector3, size: Vector2, falling: bool) -> void:
	var instance := MeshInstance3D.new()
	if falling:
		var mesh := QuadMesh.new()
		mesh.size=size
		instance.mesh=mesh
	else:
		var mesh := PlaneMesh.new()
		mesh.size=size
		instance.mesh=mesh
	instance.position=p
	var shader := Shader.new()
	shader.code="shader_type spatial; render_mode cull_disabled; uniform bool falling=false; void fragment(){float flow=sin(UV.x*65.0+sin(UV.y*30.0-TIME*3.0)*2.0)*0.5+0.5; ALBEDO=mix(vec3(0.035,0.12,0.12),vec3(0.2,0.37,0.3),flow*0.4+0.3); if(falling){ALBEDO=mix(vec3(0.28,0.44,0.4),vec3(0.66,0.78,0.68),flow);} ROUGHNESS=0.3;}"
	var material := ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("falling",falling)
	instance.material_override=material
	scenery.add_child(instance)

func landmark_zone(x: float,z: float) -> bool:
	match str(room_data[room_id].theme):
		"spring": return absf(x+8)<6.5 and absf(z+5)<6.5
		"mine": return (absf(x+6)<5 and absf(z+7)<6) or (absf(x-5)<2.5 and absf(z-4)<3.5)
		"watch": return Vector2(x+6,z+7).length()<5
		"grove": return Vector2(x+7,z-2).length()<5
		"timber": return (absf(x+5)<3 and absf(z)<15) or (absf(x-5)<3 and absf(z-6)<4)
		"crossroads": return Vector2(x+5,z-8).length()<3
	return false

func current_cache() -> Dictionary:
	match room_id:
		"forest": return {"leather_strip":4,"potion":2}
		"timber": return {"seasoned_wood":12,"leather_strip":4}
		"mine": return {"iron_ingot":18}
		"oldgrowth": return {"entropic_essence":3}
	return {}

func _room_registry() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/woodland_rooms.json"))

func _initial_room() -> String:
	return "forest"

func _make_territory_map() -> Control:
	return preload("res://scripts/woodland_map.gd").new()

func _self_scene() -> String:
	return "res://scenes/woodland.tscn"

func _exit_text(destination: String) -> String:
	if destination=="town": return "ENTER BLACKTHORN"
	if destination=="boundary": return "ENTER HOLLOW OAK"
	if destination=="world": return "WORLD MAP"
	return str(room_data.get(destination,{}).get("name",destination)).to_upper()+" →"
