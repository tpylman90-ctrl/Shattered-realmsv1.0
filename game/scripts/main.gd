extends Control

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 24)
	center.add_child(panel)
	var title := Label.new()
	title.text = "SHATTERED REALMS"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A world divided. A future to forge."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(subtitle)
	var status := Label.new()
	status.text = "Foundation build • Ravenwood is our first destination"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(status)
	for section in ["Ravenwood", "Territory campaign", "Entropic Forge"]:
		var button := Button.new()
		button.text = section
		button.custom_minimum_size = Vector2(540, 64)
		if section == "Ravenwood":
			button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ravenwood.tscn"))
		else:
			button.pressed.connect(func(): status.text = section + " — planned for the next milestones")
		panel.add_child(button)
