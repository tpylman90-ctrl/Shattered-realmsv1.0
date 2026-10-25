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

func setup(choice: String) -> void:
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
			animation_player.play(candidate, 0.15)
			current_clip = clip
			return
