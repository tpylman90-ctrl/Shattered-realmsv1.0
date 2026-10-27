class_name MonsterModel
extends Node3D
var parts: Array[Node3D] = []
var material: StandardMaterial3D
var trim: StandardMaterial3D
var base_scale:=Vector3.ONE
func build(kind: String, color: Color, boss: bool = false) -> void:
	material=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.8
	trim=StandardMaterial3D.new()
	trim.albedo_color=color.lightened(0.25)
	trim.roughness=0.55
	match kind:
		"wolf":
			_ball(Vector3(0,0.8,0),Vector3(0.9,0.45,0.45))
			_ball(Vector3(-0.75,1.02,0),Vector3(0.42,0.4,0.35))
			_ball(Vector3(-1.02,0.94,0),Vector3(0.32,0.17,0.2))
			for x in [-0.55,0.55]:
				for z in [-0.28,0.28]: _limb(Vector3(x,0.8,z),Vector3(x+0.1,0.1,z),0.11)
			for z in [-0.24,0.24]: _horn(Vector3(-0.7,1.3,z),0.4)
			_limb(Vector3(0.7,0.9,0),Vector3(1.3,1.0,0),0.10)
		"spider":
			_ball(Vector3(0.4,0.8,0),Vector3(0.7,0.5,0.55))
			_ball(Vector3(-0.35,0.65,0),Vector3(0.4,0.3,0.35))
			for i in range(4):
				for side in [-1,1]:
					var joint:=Vector3(-0.6+i*0.4,0.9,side*0.9)
					_limb(Vector3(0,0.65,0),joint,0.06)
					_limb(joint,Vector3(-0.8+i*0.5,0.05,side*1.4),0.045)
		"serpent":
			for i in range(12):
				var angle:=i*0.6
				_ball(Vector3(cos(angle)*0.7,0.2+i*0.08,sin(angle)*0.5),Vector3(0.3,0.27,0.3))
			_ball(Vector3(-0.6,1.5,0),Vector3(0.38,0.25,0.35))
			for side in [-1,1]: _horn(Vector3(-0.6,1.65,side*0.25),0.4)
		"wraith":
			_ball(Vector3(0,1.1,0),Vector3(0.45,0.85,0.32))
			_ball(Vector3(0,1.95,0),Vector3(0.3,0.35,0.3))
			for side in [-1,1]:
				_limb(Vector3(0,1.6,0),Vector3(side*0.8,0.9,0),0.09)
				_horn(Vector3(side*0.2,2.15,0),0.5)
		"drake":
			_ball(Vector3(0,0.85,0),Vector3(0.8,0.5,0.48))
			_ball(Vector3(-0.8,1.15,0),Vector3(0.45,0.3,0.32))
			for side in [-1,1]:
				_limb(Vector3(0,1,0),Vector3(0.2,1.75,side*1.2),0.08)
				var wing:=PrismMesh.new();wing.size=Vector3(1.4,0.08,1.3)
				var node:=MeshInstance3D.new();node.mesh=wing;node.material_override=trim;node.position=Vector3(0.2,1.35,side*0.8);add_child(node)
				_limb(Vector3(0.3,0.8,side*0.3),Vector3(0.6,0.1,side*0.4),0.15)
			_limb(Vector3(0.6,0.8,0),Vector3(1.6,0.55,0),0.12)
			for i in range(4): _horn(Vector3(-0.2+i*0.3,1.25,0),0.25)
		_:
			_ball(Vector3(0,1.2,0),Vector3(0.7,0.85,0.45))
			_ball(Vector3(0,2.05,0),Vector3(0.4,0.4,0.35))
			for side in [-1,1]:
				_limb(Vector3(side*0.5,1.6,0),Vector3(side*0.95,0.65,0),0.22)
				_limb(Vector3(side*0.3,0.8,0),Vector3(side*0.4,0.1,0),0.25)
	var eye:=StandardMaterial3D.new();eye.albedo_color=Color("ffc66f");eye.emission_enabled=true;eye.emission=Color("f5b25c")
	var eye_y:=1.15 if kind=="wolf" else 1.26 if kind=="drake" else 0.78 if kind=="spider" else 1.58 if kind=="serpent" else 2.1
	var eye_x:=-1.0 if kind in ["wolf","drake"] else -0.65 if kind=="spider" else -0.85 if kind=="serpent" else -0.3
	for side in [-1,1]:
		var mesh:=SphereMesh.new();mesh.radius=0.055;mesh.height=0.11;mesh.radial_segments=10;mesh.rings=5
		var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=eye;node.position=Vector3(eye_x,eye_y,side*0.2);add_child(node)
	if boss: scale=Vector3.ONE*1.45
	base_scale=scale

func _ball(at: Vector3,size: Vector3) -> void:
	var mesh:=SphereMesh.new();mesh.radial_segments=14;mesh.rings=8;mesh.radius=1;mesh.height=2
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=material;node.position=at;node.scale=size
	add_child(node)

func _limb(a: Vector3,b: Vector3,radius: float) -> void:
	var mesh:=CylinderMesh.new();mesh.top_radius=radius*0.7;mesh.bottom_radius=radius;mesh.height=a.distance_to(b);mesh.radial_segments=10
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=trim;node.position=(a+b)*0.5
	var up:=(b-a).normalized();var side:=up.cross(Vector3.FORWARD).normalized()
	if side.length_squared()<0.1: side=Vector3.RIGHT
	node.basis=Basis(side,up,side.cross(up));add_child(node)

func _horn(at: Vector3,height: float) -> void:
	var mesh:=CylinderMesh.new();mesh.top_radius=0;mesh.bottom_radius=0.12;mesh.height=height;mesh.radial_segments=10
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=trim;node.position=at+Vector3.UP*height*0.5;add_child(node)

func _process(_delta: float) -> void:
	scale=base_scale*(1.0+sin(Time.get_ticks_msec()*0.002)*0.012)
