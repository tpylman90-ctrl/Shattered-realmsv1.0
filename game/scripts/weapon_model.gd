class_name WeaponModel
extends Node3D
var metal: StandardMaterial3D
var accent: StandardMaterial3D
var dark: StandardMaterial3D
var wood: StandardMaterial3D
var style: Dictionary
var edge: StandardMaterial3D
var leather: StandardMaterial3D
var triangle_count := 0

func build(item: Dictionary) -> void:
	for child in get_children(): child.free()
	style=item.style
	metal=_material(Color('#'+style.metal),0.78,0.34)
	edge=_material(Color('#'+style.metal).lightened(0.35),0.85,0.22)
	leather=_material(Color("30251f"),0.0,0.9)
	accent=_material(Color('#'+style.accent),0.6,0.3)
	dark=_material(Color("293139"),0.5,0.4)
	wood=_material(Color("594330"),0,0.85)
	if item.get("infused",false):
		accent.emission_enabled=true;accent.emission=Color("#"+style.accent);accent.emission_energy_multiplier=0.8
	if item.get("quality","")=="masterwork":metal.roughness=0.18
	var family: String = item.family
	match family:
		"sword","greatsword","daggers":
			var length := 1.15 if family=="sword" else 1.7 if family=="greatsword" else 0.62
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
				_blade(PackedVector2Array([Vector2(side*0.025,1.35),Vector2(side*0.23,1.57),Vector2(side*0.28,1.84),Vector2(side*0.12,2.04),Vector2(side*0.17,1.80),Vector2(side*0.12,1.59),Vector2(side*0.025,1.49)]),0.065,metal)
			_band(1.4,0.075)
			_gem(Vector3(0,1.8,0),Vector3(0.12,0.21,0.10))
		"spear":
			_haft(2.1)
			_blade(PackedVector2Array([Vector2(0,2.13),Vector2(-0.18,1.68),Vector2(0,1.39),Vector2(0.18,1.68)]),0.055,metal)
			_band(1.45,0.11)
		"bow": _bow(false)
		"crossbow": _bow(true)
		"cannon": _cannon()
	_joint_details(item.family)
	# Region geometry modifies every family, rather than using palette alone.
	for child in get_children():
		child.scale.x*=float(style.width)
		child.position.x*=float(style.width)
	_batch_surfaces()

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
	mesh.radial_segments=16
	var node := _mesh(mesh,material,(a+b)*0.5)
	var direction := (b-a).normalized()
	var side := direction.cross(Vector3.FORWARD).normalized()
	if side.length_squared()<0.1: side=Vector3.RIGHT
	node.basis=Basis(side,direction,side.cross(direction))

func _triangle(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3) -> void:
	if (b-a).cross(c-a).length_squared()<0.0000000001:return
	surface.add_vertex(a);surface.add_vertex(b);surface.add_vertex(c)

func _blade(points: PackedVector2Array, thickness: float, material: Material) -> void:
	# Closed bevelled solid: broad faces inset from a sharp perimeter.
	var center:=Vector2.ZERO
	for point in points:center+=point
	center/=points.size()
	var inset:=PackedVector2Array()
	for point in points:inset.append(point.move_toward(center,minf(0.032,point.distance_to(center)*0.15)))
	var faces:=SurfaceTool.new();faces.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bevels:=SurfaceTool.new();bevels.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices:=Geometry2D.triangulate_polygon(inset)
	for side in [-1,1]:
		for i in range(0,indices.size(),3):
			var ids:=[indices[i],indices[i+1],indices[i+2]]
			if side>0:ids.reverse()
			for index in ids:faces.add_vertex(Vector3(inset[index].x,inset[index].y,side*thickness*0.5))
		for i in range(points.size()):
			var next:=(i+1)%points.size()
			var a:=Vector3(points[i].x,points[i].y,0);var b:=Vector3(points[next].x,points[next].y,0)
			var c:=Vector3(inset[i].x,inset[i].y,side*thickness*0.5);var d:=Vector3(inset[next].x,inset[next].y,side*thickness*0.5)
			if side>0:_triangle(bevels,a,b,c);_triangle(bevels,b,d,c)
			else:_triangle(bevels,a,c,b);_triangle(bevels,b,c,d)
	faces.generate_normals();bevels.generate_normals()
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	_mesh(faces.commit(),material,Vector3.ZERO);_mesh(bevels.commit(),edge,Vector3.ZERO)

func _sword(origin: Vector3,length: float) -> void:
	var curve:float=float(style.curve)*0.55
	var width:=0.105 if length<1.5 else 0.17
	if length<0.8:width=0.075
	var before:=get_child_count()
	_ridged_blade(length,width,curve)
	var span:=0.28 if length>1.0 else 0.17
	_blade(PackedVector2Array([Vector2(-span,0.13),Vector2(-span-0.025,0.23),Vector2(-0.07,0.26),Vector2(0.07,0.26),Vector2(span+0.025,0.23),Vector2(span,0.13),Vector2(0.06,0.18),Vector2(-0.06,0.18)]),0.085,accent)
	_grip(-0.22,0.36,0.052 if length>1.0 else 0.04)
	_gem(Vector3(0,-0.29,0),Vector3(0.065,0.085,0.05))
	_gem(Vector3(0,0.22,0.055),Vector3(0.035,0.045,0.022))
	for i in range(before,get_child_count()):get_child(i).position+=origin

func _ridged_blade(length:float,width:float,curve:float) -> void:
	var faces:=SurfaceTool.new();faces.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bevels:=SurfaceTool.new();bevels.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs:=[-1.0,-0.70,0.0,0.70,1.0];var zs:=[0.0,0.45,1.0,0.45,0.0]
	for side in [-1,1]:
		for i in range(8):
			var t:=float(i)/8;var u:=float(i+1)/8
			var w:=width*_blade_width(t);var v:=width*_blade_width(u) if i<7 else 0.0
			for j in range(4):
				var a:=Vector3(curve*t*t+xs[j]*w,0.25+t*length,side*zs[j]*0.05)
				var b:=Vector3(curve*u*u+xs[j]*v,0.25+u*length,side*zs[j]*0.05*(1.0 if i<7 else 0.0))
				var c:=Vector3(curve*t*t+xs[j+1]*w,0.25+t*length,side*zs[j+1]*0.05)
				var d:=Vector3(curve*u*u+xs[j+1]*v,0.25+u*length,side*zs[j+1]*0.05*(1.0 if i<7 else 0.0))
				var surface:SurfaceTool=bevels if j in [0,3] else faces
				if side>0:_triangle(surface,a,b,c);_triangle(surface,b,d,c)
				else:_triangle(surface,a,c,b);_triangle(surface,b,c,d)
	faces.generate_normals();bevels.generate_normals();_mesh(faces.commit(),metal,Vector3.ZERO);_mesh(bevels.commit(),edge,Vector3.ZERO)

func _blade_width(t:float) -> float:
	match int(style.motif):
		2:return 1.08 if t<0.6 else 0.85-t*0.3
		3:return 0.84+sin(t*PI)*0.3-t*0.35
		4:return 1.12-t*0.4
		5:return 1.1-t*0.55
	return 1.0-t*0.45

func _grip(start:float,length:float,radius:float) -> void:
	_segment(Vector3(0,start,0),Vector3(0,start+length,0),radius,leather)
	for i in range(int(length/0.035)):
		var y:=start+0.012+i*0.035
		_segment(Vector3(0,y,0),Vector3(0,y+0.011,0),radius*1.06,wood)
	_band(start,radius*1.1);_band(start+length,radius*1.1)

func _band(y: float,radius: float) -> void:
	_segment(Vector3(0,y-0.025,0),Vector3(0,y+0.025,0),radius,accent)

func _haft(length: float) -> void:
	_segment(Vector3(0,-0.3,0),Vector3(0,length-0.3,0),0.045,wood)
	for y in [-0.22,0.02,0.3,length*0.45,length-0.4]: _band(y,0.06)
	_grip(-0.22,0.36,0.05)

func _gem(at: Vector3, size: Vector3) -> void:
	var mesh:=SphereMesh.new();mesh.radius=1;mesh.height=2;mesh.radial_segments=8;mesh.rings=3
	var node:=_mesh(mesh,accent,at);node.scale=size

func _bow(crossbow: bool) -> void:
	if crossbow:
		_box(Vector3(0,0.55,0),Vector3(0.16,1.35,0.18),wood)
		_box(Vector3(0,0.12,0.13),Vector3(0.08,0.3,0.06),dark)
		for y in [0.05,0.4,0.8,1.08]: _box(Vector3(0,y,0),Vector3(0.19,0.055,0.22),accent)
		for side in [-1,1]:
			var front:=PackedVector2Array();var back:=PackedVector2Array()
			for i in range(13):
				var t:=float(i)/12
				var x:float=side*t*0.87;var y:=0.9+sin(t*PI)*0.16-float(style.curve)*t
				var width:=0.085*(1-t*0.4)
				front.append(Vector2(x,y+width));back.append(Vector2(x,y-width))
			back.reverse();front.append_array(back);_blade(front,0.075,metal)
			_segment(Vector3(side*0.87,0.9-float(style.curve),0.05),Vector3(0,0.25,0.05),0.005,dark)
		_box(Vector3(0,0.7,0.13),Vector3(0.025,0.8,0.025),metal)
	else:
		var outline:=PackedVector2Array();var back:=PackedVector2Array()
		for i in range(33):
			var y:=-1.0+float(i)/16;var t:=absf(y)
			var x:=0.30*sin(t*PI*0.85)-0.12*pow(t,6)+float(style.curve)*t*0.15
			var width:=0.043*(1-t*0.6)
			outline.append(Vector2(x-width,y));back.append(Vector2(x+width,y))
		back.reverse();outline.append_array(back);_blade(outline,0.065,wood)
		var tip:=0.30*sin(PI*0.85)-0.12+float(style.curve)*0.15
		_segment(Vector3(tip,-1,0),Vector3(tip,1,0),0.005,dark)
		_grip(-0.15,0.3,0.05)

func _cannon() -> void:
	_segment(Vector3(0,0.1,0),Vector3(0,0.95,0),0.19,metal)
	_tube(0.95,1.25,0.17,0.12)
	for y in [0.12,0.32,0.88]:_band(y,0.205 if y<0.4 else 0.18)
	_grip(-0.32,0.38,0.075)
	for side in [-1,1]:
		_segment(Vector3(side*0.17,0.24,0),Vector3(side*0.17,0.81,0),0.024,accent)
		for y in [0.28,0.78]:_gem(Vector3(side*0.20,y,0),Vector3(0.028,0.028,0.028))
	_box(Vector3(0,0.99,0.17),Vector3(0.035,0.055,0.04),dark)
	_box(Vector3(0,0.25,0.2),Vector3(0.09,0.06,0.06),dark)
	_segment(Vector3(0,-0.05,-0.12),Vector3(0,0.03,-0.25),0.018,dark)
	_segment(Vector3(0,0.03,-0.25),Vector3(0,0.22,-0.12),0.018,dark)

func _tube(bottom:float,top:float,radius:float,bore:float) -> void:
	var outer:=CylinderMesh.new();outer.top_radius=radius;outer.bottom_radius=radius;outer.height=top-bottom;outer.radial_segments=32;outer.cap_top=false;outer.cap_bottom=false
	_mesh(outer,metal,Vector3(0,(bottom+top)*0.5,0))
	var inner:=CylinderMesh.new();inner.top_radius=bore;inner.bottom_radius=bore;inner.height=top-bottom;inner.radial_segments=32;inner.cap_top=false;inner.cap_bottom=false;inner.flip_faces=true
	_mesh(inner,dark,Vector3(0,(bottom+top)*0.5,0))
	var rim:=TorusMesh.new();rim.inner_radius=bore;rim.outer_radius=radius+0.012;rim.rings=32;rim.ring_segments=8
	var ring:=_mesh(rim,edge,Vector3(0,top,0));ring.scale.y=0.35
	_segment(Vector3(0,bottom-0.01,0),Vector3(0,bottom,0),bore,dark)

func _joint_details(family:String) -> void:
	# Fittings are anchored to structural joints, never a generic floating crest.
	if family in ["axe","scythe"]:
		var y:=0.87 if family=="axe" else 1.5
		_box(Vector3(0,y,0),Vector3(0.16,0.30,0.16),dark)
		for offset in [-0.10,0.10]:
			_band(y+offset,0.10)
			_gem(Vector3(0,y+offset,0.09),Vector3(0.026,0.026,0.022))
		if family=="scythe":_segment(Vector3(0,1.25,0),Vector3(-0.38,1.65,0),0.025,accent)
	if family=="crossbow":
		for side in [-1,1]:_box(Vector3(side*0.055,0.62,0.11),Vector3(0.022,0.8,0.025),dark)
		_segment(Vector3(0,0.28,0.15),Vector3(0,1.22,0.15),0.012,wood)
		_blade(PackedVector2Array([Vector2(0,1.3),Vector2(-0.035,1.17),Vector2(0.035,1.17)]),0.025,edge)
		_segment(Vector3(0,0.12,-0.1),Vector3(0,0.04,-0.24),0.018,dark)
		_segment(Vector3(0,0.04,-0.24),Vector3(0,0.32,-0.18),0.018,dark)

func _batch_surfaces() -> void:
	var groups:Dictionary={}
	for child in get_children():
		var material:Material=child.material_override
		if not groups.has(material):
			var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);groups[material]=surface
		groups[material].append_from(child.mesh,0,child.transform)
		child.free()
	triangle_count=0
	for material in groups:
		var mesh:ArrayMesh=groups[material].commit();var arrays:=mesh.surface_get_arrays(0)
		triangle_count+=(arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null and arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
		_mesh(mesh,material,Vector3.ZERO)

func model_bounds() -> AABB:
	var bounds:=AABB();var first:=true
	for child in get_children():
		var part:AABB=child.transform*child.mesh.get_aabb()
		bounds=part if first else bounds.merge(part);first=false
	return bounds

static func add_studio_reflections(settings:Environment) -> void:
	var sky:=Sky.new();sky.radiance_size=Sky.RADIANCE_SIZE_32
	var source:=ProceduralSkyMaterial.new();source.sky_top_color=Color("8cabc6");source.sky_horizon_color=Color("e6d6b5");source.ground_bottom_color=Color("17212c");source.ground_horizon_color=Color("717f86")
	sky.sky_material=source;settings.sky=sky;settings.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
