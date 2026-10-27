class_name WeaponModel
extends Node3D
var metal: StandardMaterial3D
var accent: StandardMaterial3D
var dark: StandardMaterial3D
var wood: StandardMaterial3D
var style: Dictionary

func build(item: Dictionary) -> void:
	for child in get_children(): child.free()
	style=item.style
	metal=_material(Color('#'+style.metal),0.72,0.26)
	accent=_material(Color('#'+style.accent),0.6,0.3)
	dark=_material(Color("293139"),0.5,0.4)
	wood=_material(Color("594330"),0,0.85)
	if item.get("infused",false):
		accent.emission_enabled=true;accent.emission=Color("#"+style.accent);accent.emission_energy_multiplier=0.8
	if item.get("quality","")=="masterwork":metal.roughness=0.18
	var family: String = item.family
	match family:
		"sword","greatsword","daggers":
			var length := 1.25 if family=="sword" else 1.8 if family=="greatsword" else 0.82
			if family=="daggers":
				_sword(Vector3(-0.3,0.0,0.03),length)
				_sword(Vector3(0.3,0.0,-0.03),length)
			else: _sword(Vector3.ZERO,length)
		"axe":
			_haft(1.65)
			_blade(PackedVector2Array([Vector2(-0.08,0.98),Vector2(-0.65,1.2),Vector2(-0.88,0.96),Vector2(-0.7,0.57),Vector2(-0.09,0.74)]),0.09,metal)
			_blade(PackedVector2Array([Vector2(0.08,0.98),Vector2(0.40,1.15),Vector2(0.62,0.88),Vector2(0.42,0.62),Vector2(0.09,0.74)]),0.09,metal)
			_band(0.85,0.15)
		"scythe":
			_haft(2.2)
			_blade(PackedVector2Array([Vector2(-0.07,1.52),Vector2(-0.20,1.85),Vector2(-0.55,1.97),Vector2(-1.0,1.8),Vector2(-1.32,1.27),Vector2(-0.85,1.58),Vector2(-0.50,1.62),Vector2(-0.15,1.35)]),0.055,metal)
			_band(1.5,0.13)
		"staff":
			_haft(2.15)
			for side in [-1,1]:
				_segment(Vector3(side*0.06,1.35,0),Vector3(side*0.32,1.68,0),0.055,accent)
				_segment(Vector3(side*0.32,1.68,0),Vector3(side*0.14,2.0,0),0.04,accent)
			_gem(Vector3(0,1.76,0),Vector3(0.17,0.25,0.17))
		"spear":
			_haft(2.1)
			_blade(PackedVector2Array([Vector2(0,2.13),Vector2(-0.18,1.68),Vector2(0,1.39),Vector2(0.18,1.68)]),0.055,metal)
			_band(1.45,0.11)
		"bow": _bow(false)
		"crossbow": _bow(true)
		"cannon": _cannon()
	_ornament(item.family)
	# Region geometry modifies every family, rather than using palette alone.
	for child in get_children():
		child.scale.x*=float(style.width)
		child.position.x*=float(style.width)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.metallic=metallic
	material.roughness=roughness
	return material

func _mesh(mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=material
	node.position=at
	add_child(node)
	return node

func _box(at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size=size
	_mesh(mesh,material,at)

func _segment(a: Vector3,b: Vector3,radius: float,material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius=radius*0.9
	mesh.bottom_radius=radius
	mesh.height=a.distance_to(b)
	mesh.radial_segments=12
	var node := _mesh(mesh,material,(a+b)*0.5)
	var direction := (b-a).normalized()
	var side := direction.cross(Vector3.FORWARD).normalized()
	if side.length_squared()<0.1: side=Vector3.RIGHT
	node.basis=Basis(side,direction,side.cross(direction))

func _blade(points: PackedVector2Array, thickness: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(points)
	for side in [-1,1]:
		for i in range(0,indices.size(),3):
			var triangle := [indices[i],indices[i+1],indices[i+2]]
			if side==1: triangle.reverse()
			for index in triangle:
				var p := points[index]
				surface.add_vertex(Vector3(p.x,p.y,side*thickness*0.5))
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i+1)%points.size()]
		for p in [Vector3(a.x,a.y,-thickness*0.5),Vector3(b.x,b.y,-thickness*0.5),Vector3(a.x,a.y,thickness*0.5),Vector3(b.x,b.y,-thickness*0.5),Vector3(b.x,b.y,thickness*0.5),Vector3(a.x,a.y,thickness*0.5)]: surface.add_vertex(p)
	surface.generate_normals()
	_mesh(surface.commit(),material,Vector3.ZERO)

func _sword(origin: Vector3,length: float) -> void:
	var curve: float = style.curve
	var width := 0.13 if length<1.5 else 0.19
	var outline := PackedVector2Array()
	for i in range(7):
		var t := float(i)/7
		var tooth := 0.025 if int(style.motif) in [3,4,5] and i%2 else 0.0
		outline.append(Vector2(-width-tooth+curve*t*t,0.25+t*length))
	outline.append(Vector2(curve,length+0.4))
	for i in range(6,-1,-1):
		var t := float(i)/7
		outline.append(Vector2(width+curve*t*t,0.25+t*length))
	var before := get_child_count()
	_blade(outline,0.065,metal)
	for side in [-1,1]:
		_segment(Vector3(side*0.05,0.25,0),Vector3(side*(0.35+curve),0.25+float(style.motif)*0.025,0),0.045,accent)
	_segment(Vector3(0,-0.24,0),Vector3(0,0.2,0),0.065,wood)
	for i in range(7): _band(-0.21+i*0.055,0.072)
	_gem(Vector3(0,-0.3,0),Vector3(0.09,0.1,0.07))
	_box(Vector3(curve*0.12,length*0.4,0.038),Vector3(0.028,length*0.55,0.01),accent)
	for i in range(before,get_child_count()): get_child(i).position+=origin

func _band(y: float,radius: float) -> void:
	_segment(Vector3(0,y-0.025,0),Vector3(0,y+0.025,0),radius,accent)

func _haft(length: float) -> void:
	_segment(Vector3(0,-0.3,0),Vector3(0,length-0.3,0),0.045,wood)
	for y in [-0.22,0.02,0.3,length*0.45,length-0.4]: _band(y,0.06)
	for i in range(9): _band(-0.18+i*0.045,0.052)

func _gem(at: Vector3, size: Vector3) -> void:
	var mesh := PrismMesh.new()
	mesh.size=size*2
	_mesh(mesh,accent,at)

func _bow(crossbow: bool) -> void:
	if crossbow:
		_box(Vector3(0,0.55,0),Vector3(0.16,1.35,0.18),wood)
		_box(Vector3(0,0.12,0.13),Vector3(0.08,0.3,0.06),dark)
		for y in [0.05,0.4,0.8,1.08]: _box(Vector3(0,y,0),Vector3(0.19,0.055,0.22),accent)
		for side in [-1,1]:
			var last := Vector3(0,0.9,0)
			for i in range(1,8):
				var t := float(i)/7
				var next := Vector3(side*t*0.88,0.9+sin(t*PI)*0.18-float(style.curve)*t,0)
				_segment(last,next,0.05-t*0.025,metal)
				last=next
			_segment(last,Vector3(0,0.25,0.05),0.008,dark)
		_box(Vector3(0,0.7,0.13),Vector3(0.025,0.8,0.025),metal)
	else:
		for side in [-1,1]:
			var last := Vector3.ZERO
			for i in range(1,12):
				var t := float(i)/11
				var next := Vector3(sin(t*PI)*0.3+float(style.curve)*t,t*side,0)
				_segment(last,next,0.055-t*0.032,wood if i<8 else metal)
				last=next
			_segment(last,Vector3(-0.2,0,0),0.007,dark)
		for i in range(7): _band(-0.15+i*0.05,0.065)

func _cannon() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius=0.16
	mesh.bottom_radius=0.23
	mesh.height=1.3
	mesh.radial_segments=24
	_mesh(mesh,metal,Vector3(0,0.6,0))
	for y in [0.04,0.3,0.9,1.22]: _band(y,0.245 if y<0.4 else 0.19)
	_segment(Vector3(0,-0.45,0),Vector3(0,0.1,0),0.10,wood)
	var mouth := CylinderMesh.new()
	mouth.top_radius=0.13
	mouth.bottom_radius=0.13
	mouth.height=0.012
	mouth.radial_segments=24
	_mesh(mouth,dark,Vector3(0,1.256,0))
	for side in [-1,1]:
		_box(Vector3(side*0.22,0.45,0),Vector3(0.06,0.45,0.12),accent)
		for y in [0.25,0.5,0.75]: _gem(Vector3(side*0.24,y,0.08),Vector3(0.035,0.035,0.035))
	_box(Vector3(0,0.0,0.22),Vector3(0.08,0.23,0.04),dark)

func _ornament(family: String) -> void:
	if int(style.motif)==0: return
	var at := 0.5 if family in ["bow","crossbow","cannon"] else 0.9
	var count := int(style.motif)+1
	for i in range(count):
		var offset := (float(i)-float(count-1)*0.5)*0.12
		var curl := float(style.curve)
		_segment(Vector3(offset*0.6,at,0),Vector3(offset,at+0.12+absf(offset)*curl,0),0.022,accent)
		if int(style.motif) in [3,4,5]:
			_gem(Vector3(offset,at+0.15,0),Vector3(0.025,0.06,0.03))
