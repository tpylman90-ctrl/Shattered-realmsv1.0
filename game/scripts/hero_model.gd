extends Node3D

var animation_player: AnimationPlayer
var model: Node3D
var current_clip := ""

static func selected(config_path: String = "user://hero.cfg") -> String:
	var config := ConfigFile.new()
	if config.load(config_path) == OK:
		var choice: String = str(config.get_value("hero", "appearance", "male"))
		if choice in ["male", "female"]:
			return choice
	return "male"

static func save_choice(choice: String, config_path: String = "user://hero.cfg") -> Error:
	if choice not in ["male", "female"]:
		return ERR_INVALID_PARAMETER
	var config := ConfigFile.new()
	config.set_value("hero", "appearance", choice)
	return config.save(config_path)

func setup(choice: String, show_equipment: bool = true) -> void:
	assert(choice in ["male", "female"])
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	model = load("res://assets/characters/starter_" + choice + ".glb").instantiate()
	add_child(model)
	animation_player = _find_player(model)
	assert(animation_player != null)
	for clip in animation_player.get_animation_list():
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	current_clip = ""
	play_clip("Idle")
	if show_equipment:
		_attach_equipped_weapon()

func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null

func play_clip(clip: String) -> void:
	if clip == current_clip or animation_player == null:
		return
	for candidate in animation_player.get_animation_list():
		if candidate == clip or candidate.ends_with("/" + clip):
			animation_player.speed_scale = 1.0
			animation_player.play(candidate, 0.15)
			current_clip = clip
			return

func update_locomotion(world_speed: float, model_scale: float, running: bool) -> void:
	if world_speed < 0.03:
		play_clip("Idle")
		animation_player.speed_scale = 1.0
		return
	play_clip("Run" if running else "Walk")
	# Stance travel divided by stance duration in the authored in-place cycles.
	var native_speed := 2.182 if running else 0.806
	animation_player.speed_scale = clampf(world_speed / (maxf(model_scale, 0.01) * native_speed), 0.5, 2.3)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found!=null: return found
	return null

func _attach_equipped_weapon() -> void:
	var skeleton := _find_skeleton(model)
	if skeleton==null or skeleton.find_bone("spine_03")<0: return
	var state := EquipmentState.new()
	var attachment := BoneAttachment3D.new()
	attachment.bone_name="spine_03"
	skeleton.add_child(attachment)
	var visual := WeaponModel.new()
	attachment.add_child(visual)
	visual.build(state.catalog.items[state.equipped.weapon])
	visual.position=Vector3(0.12,-0.15,-0.28)
	visual.rotation.z=-0.35
	visual.scale=Vector3.ONE*0.58
