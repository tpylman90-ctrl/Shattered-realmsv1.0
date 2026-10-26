extends Node3D

const HeroModel = preload("res://scripts/hero_model.gd")
var record: Dictionary
var hero: Node3D
var anchor := Vector2.ZERO

func configure(data: Dictionary, floor_position: Vector3, base_scale: float) -> void:
	record = data
	anchor = Vector2(data.position[0], data.position[1])
	position = floor_position
	scale = Vector3.ONE * base_scale * float(data.get("height", 1.0))
	rotation.y = deg_to_rad(float(data.get("facing", 0)))
	hero = HeroModel.new()
	add_child(hero)
	hero.setup(data.appearance)
	_tint_materials(hero)
	hero.animation_player.seek(float(data.get("idle_phase", 0.0)), true)
	var shadow := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.85, 0.65)
	shadow.mesh = plane
	shadow.position.y = 0.012
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; void fragment(){vec2 p=(UV-vec2(0.5))*2.0; ALBEDO=vec3(0.055,0.04,0.02); ALPHA=max(0.0,1.0-dot(p,p))*0.30;}"
	var material := ShaderMaterial.new()
	material.shader = shader
	shadow.material_override = material
	add_child(shadow)

func _tint_materials(node: Node) -> void:
	if node is MeshInstance3D:
		# Duplicate overrides only; the approved player assets remain shared and intact.
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for index in node.mesh.get_surface_count():
			var source: Material = node.get_active_material(index)
			if not source is StandardMaterial3D:
				continue
			var name_lower := source.resource_name.to_lower()
			var color := Color.WHITE
			if "linen" in name_lower:
				color = Color(record.shirt)
			elif "trousers" in name_lower:
				color = Color(record.trousers)
			else:
				continue
			var material: StandardMaterial3D = source.duplicate()
			material.albedo_color = color
			node.set_surface_override_material(index, material)
	for child in node.get_children():
		_tint_materials(child)

func head_position() -> Vector3:
	return global_position + Vector3.UP * 1.84 * scale.y

func screen_rect(camera: Camera3D) -> Rect2:
	var feet := camera.unproject_position(global_position)
	var head := camera.unproject_position(head_position())
	var width := maxf(22.0, absf(feet.y - head.y) * 0.34)
	return Rect2(Vector2(feet.x - width, head.y - 12), Vector2(width * 2, feet.y - head.y + 28))

func face_player(target: Vector3) -> void:
	var offset := target - global_position
	if Vector2(offset.x, offset.z).length() > 0.01:
		rotation.y = atan2(offset.x, offset.z)
