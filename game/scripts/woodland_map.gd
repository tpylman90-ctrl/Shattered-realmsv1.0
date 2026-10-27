extends Control
signal closed
var current := "forest"
var visited: Array = []
var registry: Dictionary
var points := {"forest":Vector2(225,555),"crossing":Vector2(225,435),"waymeet":Vector2(550,435),"timber":Vector2(875,435),"spring":Vector2(1055,260),"oldgrowth":Vector2(790,155),"ruins":Vector2(475,155),"watch":Vector2(185,155),"mine":Vector2(185,280),"ridge":Vector2(500,280)}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	registry = JSON.parse_string(FileAccess.get_file_as_string("res://data/woodland_rooms.json"))
	var title := Label.new()
	title.text = "RAVENWOOD · TERRITORY ROUTES"
	title.position = Vector2(40,30)
	title.add_theme_font_size_override("font_size",30)
	add_child(title)
	var caption := Label.new()
	caption.text = "Gold: current area   •   Green: visited   •   Routes connect on foot"
	caption.position = Vector2(40,75)
	add_child(caption)
	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(1100,30)
	close.size = Vector2(140,55)
	close.pressed.connect(func(): hide(); closed.emit())
	add_child(close)
	for id in points:
		var label := Label.new()
		label.text = registry[id].name
		label.position = points[id]-Vector2(110,25)
		label.size = Vector2(220,50)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",17)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	var footer := Label.new()
	footer.text = "Blackthorn ↔ Oldwood Road     •     Hollow Oak dungeon via Thornwatch Outer Ruins"
	footer.position = Vector2(40,660)
	add_child(footer)

func open(id: String, explored: Array) -> void:
	current = id
	visited = explored.duplicate()
	show()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.025,0.065,0.055,0.98))
	var drawn := {}
	for id in registry:
		for exit in registry[id].exits.values():
			var destination: String = exit.to
			if not points.has(destination):
				continue
			var key := str([id,destination].min())+str([id,destination].max())
			if drawn.has(key):
				continue
			drawn[key] = true
			draw_line(points[id],points[destination],Color("52664c"),3,true)
	for id in points:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("725d32") if id==current else Color("314d3b") if id in visited else Color("1b2e29")
		style.border_color = Color("eed49a") if id==current else Color("789276")
		style.set_border_width_all(2)
		style.set_corner_radius_all(9)
		draw_style_box(style,Rect2(points[id]-Vector2(116,30),Vector2(232,60)))
