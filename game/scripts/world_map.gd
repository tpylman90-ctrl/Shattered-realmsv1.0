extends Control

const COLORS := {
	"forest": Color("344c3c"), "snow": Color("506573"),
	"mountain": Color("4d505b"), "ash": Color("63423a"),
	"marsh": Color("454f38"), "plain": Color("5a6040"),
	"coast": Color("365b61"), "desert": Color("806441"), "deep": Color("4b354f")
}
var catalog: Dictionary
var selected_id := ""
var tiles: Dictionary = {}
var detail: Label
var enter: Button

func _ready() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_map.json"))
	var background := ColorRect.new()
	background.color = Color("101e27")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_label("THE SHATTERED REALMS", Vector2(36, 18), 32)
	_label("WORLD MAP  /  Layout study • Tap a territory", Vector2(38, 61), 19)
	var back := Button.new()
	back.text = "MAIN MENU"
	back.position = Vector2(1060, 24)
	back.size = Vector2(182, 52)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	add_child(back)
	for record in catalog.territories:
		var tile := Button.new()
		tile.position = Vector2(36, 113) + Vector2(record.position[0] * 244, record.position[1] * 112)
		tile.size = Vector2(232, 100)
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.add_theme_font_size_override("font_size", 20)
		tile.text = record.name + "\n" + (record.settlement_type + ": " + record.settlement if not record.settlement.is_empty() else "Boss region" if record.id == "deep" else "No settlement")
		tile.add_theme_color_override("font_color", Color("f3eee0"))
		tile.add_theme_stylebox_override("normal", _style(record.biome, false))
		tile.add_theme_stylebox_override("hover", _style(record.biome, true))
		tile.add_theme_stylebox_override("focus", _style(record.biome, true))
		tile.pressed.connect(select_territory.bind(record.id))
		add_child(tile)
		tiles[record.id] = tile
	detail = _label("", Vector2(38, 579), 21)
	detail.size = Vector2(970, 72)
	enter = Button.new()
	enter.text = "VISIT RAVENWOOD"
	enter.position = Vector2(1000, 583)
	enter.size = Vector2(242, 61)
	enter.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ravenwood.tscn" if FileAccess.file_exists("user://hero.cfg") else "res://scenes/hero_select.tscn"))
	add_child(enter)
	_label("PROVISIONAL POSITIONS • Borders, routes and distances are not decided. Other regions are planning markers.", Vector2(38, 678), 17)
	select_territory("ravenwood")

func select_territory(id: String) -> void:
	for record in catalog.territories:
		tiles[record.id].add_theme_stylebox_override("normal", _style(record.biome, record.id == id))
		if record.id != id:
			continue
		selected_id = id
		var description: String = record.settlement_type + ": " + record.settlement if not record.settlement.is_empty() else "No settlement"
		if not record.boss.is_empty():
			description += "   •   Boss: " + record.boss
		detail.text = record.name + "\n" + description + ("   •   Exploration available" if id == "ravenwood" else "   •   Not built yet")
	enter.visible = id == "ravenwood"

func _style(biome: String, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLORS[biome]
	style.border_color = Color("e1c47e") if selected else Color("708080")
	style.set_border_width_all(3 if selected else 1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	return style

func _label(text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("eee9da"))
	add_child(label)
	return label
