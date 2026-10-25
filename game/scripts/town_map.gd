extends Control

var current := "gate"
var points := {
	"gate":Vector2(640,400), "market":Vector2(330,400), "camp":Vector2(970,400),
	"upper":Vector2(640,245), "inn":Vector2(160,545), "forge":Vector2(335,545),
	"shop":Vector2(510,545), "command":Vector2(875,545), "barracks":Vector2(1075,545),
	"hall":Vector2(880,245), "watch":Vector2(400,145), "forest":Vector2(640,100)
}
var registry: Dictionary

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	registry = JSON.parse_string(FileAccess.get_file_as_string("res://data/ravenwood_locations.json"))
	var title := Label.new()
	title.text = "RAVENWOOD"
	title.position = Vector2(60,35)
	title.add_theme_font_size_override("font_size",32)
	add_child(title)
	var caption := Label.new()
	caption.text = "Connected routes • Gold marks your current location"
	caption.position = Vector2(60,78)
	add_child(caption)
	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(1095,35)
	close.size = Vector2(125,55)
	close.pressed.connect(func(): hide())
	add_child(close)
	for id in points:
		var label := Label.new()
		label.text = registry.locations[id]
		label.position = points[id] - Vector2(80,24)
		label.size = Vector2(160,48)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",17)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)

func show_location(id: String) -> void:
	current = id
	show()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,Vector2(1280,720)), Color(0.025,0.045,0.035,0.97))
	if registry.is_empty():
		return
	for pair in registry.connections:
		draw_line(points[pair[0]], points[pair[1]], Color(0.3,0.41,0.31),3,true)
	for id in points:
		var rect := Rect2(points[id]-Vector2(84,29),Vector2(168,58))
		draw_style_box(_node_style(id==current),rect)

func _node_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35,0.25,0.10) if selected else Color(0.08,0.13,0.10)
	style.border_color = Color(0.85,0.69,0.34) if selected else Color(0.3,0.44,0.33)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
