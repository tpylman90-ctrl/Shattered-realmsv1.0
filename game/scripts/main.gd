extends Control
func _ready() -> void:
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(center)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",22);center.add_child(column)
	var title:=Label.new();title.text="SHATTERED REALMS";title.add_theme_font_size_override("font_size",48);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(title)
	var progress:=CampaignState.new()
	var status:=Label.new();status.text="A world divided. A future to forge.\nLevel %d · %d companions · %d restored anchors" % [progress.level,progress.recruited.size(),progress.cleared.size()];status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(status)
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",18);column.add_child(grid)
	for section in ["Continue Campaign","New Campaign","World Map","Equipment & Forge","Journal / Party / Saves","Choose Hero","Blackthorn Town","Ravenwood Wilds"]:
		var button:=Button.new();button.text=section;button.custom_minimum_size=Vector2(330,64);grid.add_child(button)
		button.pressed.connect(_open_section.bind(section))

func _open_section(section: String) -> void:
	match section:
		"Continue Campaign","World Map":
			get_tree().change_scene_to_file("res://scenes/world_map.tscn")
		"New Campaign":
			get_tree().set_meta("game_menu_tab","new")
			get_tree().change_scene_to_file("res://scenes/game_menu.tscn")
		"Journal / Party / Saves":
			get_tree().set_meta("game_menu_tab","journal")
			get_tree().change_scene_to_file("res://scenes/game_menu.tscn")
		"Choose Hero":
			get_tree().change_scene_to_file("res://scenes/hero_select.tscn")
		"Blackthorn Town":
			get_tree().change_scene_to_file("res://scenes/ravenwood.tscn" if FileAccess.file_exists("user://hero.cfg") else "res://scenes/hero_select.tscn")
		"Ravenwood Wilds":
			get_tree().change_scene_to_file("res://scenes/woodland.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/equipment.tscn")
