extends Control

const COLORS := {
	"forest": Color("3e624b"), "snow": Color("91a9b0"),
	"mountain": Color("68716d"), "ash": Color("795148"),
	"marsh": Color("576544"), "plain": Color("7c8151"),
	"coast": Color("548079"), "desert": Color("b19260"), "deep": Color("594551")
}
var catalog: Dictionary
var selected_id := ""
var tiles: Dictionary = {}
var regions: Dictionary = {}
var coast := PackedVector2Array()
var detail: Label
var enter: Button

func _ready() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_map.json"))
	coast = _points(catalog.coastline)
	_label("THE SHATTERED REALMS", Vector2(30, 12), 30)
	_label("WORLD MAP • Tap a territory", Vector2(32, 50), 17)
	var back := Button.new()
	back.text = "MAIN MENU"
	back.position = Vector2(1080, 16)
	back.size = Vector2(168, 50)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	add_child(back)
	for record in catalog.territories:
		regions[record.id] = Geometry2D.intersect_polygons(_points(record.polygon), coast)
		var center := Vector2(record.position[0], record.position[1])
		var label := _label(record.map_name, center - Vector2(100, 26), 18)
		label.size.x = 200
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_constant_override("line_spacing", -2)
		tiles[record.id] = label
		if not record.settlement.is_empty():
			var city := _label("◆ " + record.settlement, center + Vector2(-100, 1 if not "\n" in record.map_name else 21), 15)
			city.size.x = 200
			city.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			city.add_theme_color_override("font_color", Color("ffe2a0"))
		elif record.id == "deep":
			var boss := _label("◇ FINAL BOSS", center + Vector2(-100, 21), 12)
			boss.size.x = 200
			boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var legend := _label("◆ Settlement    ◇ Boss", Vector2(35, 600), 15)
	legend.modulate = Color("c1d3cc")
	detail = _label("", Vector2(32, 635), 20)
	detail.size = Vector2(950, 58)
	enter = Button.new()
	enter.text = "VISIT RAVENWOOD"
	enter.position = Vector2(1000, 638)
	enter.size = Vector2(248, 54)
	enter.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ravenwood.tscn" if FileAccess.file_exists("user://hero.cfg") else "res://scenes/hero_select.tscn"))
	add_child(enter)
	_label("PROVISIONAL GEOGRAPHY • Layout and borders can change", Vector2(750, 601), 14)
	select_territory("ravenwood")

func _points(values: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for value in values:
		points.append(Vector2(value[0], value[1]))
	return points

func territory_at(point: Vector2) -> String:
	for id in regions:
		for polygon in regions[id]:
			if Geometry2D.is_point_in_polygon(point, polygon):
				return id
	return ""

func _gui_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	else:
		return
	var id := territory_at(point)
	if not id.is_empty():
		select_territory(id)
		accept_event()

func select_territory(id: String) -> void:
	for record in catalog.territories:
		if record.id != id:
			continue
		selected_id = id
		var description: String = record.settlement_type + ": " + record.settlement if not record.settlement.is_empty() else "No settlement"
		if not record.boss.is_empty():
			description += "   •   Boss: " + record.boss
		detail.text = record.name + "\n" + description + ("   •   Exploration available" if id == "ravenwood" else "   •   Not built yet")
		enter.visible = id == "ravenwood"
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("112c3b"))
	# Quiet ocean strokes give scale without competing with place names.
	for y in range(100, 620, 38):
		for x in range(20, 1280, 95):
			draw_line(Vector2(x, y), Vector2(x + 22, y - 2), Color(0.35, 0.58, 0.64, 0.11), 1, true)
	if coast.is_empty():
		return
	var closed := coast.duplicate()
	closed.append(coast[0])
	draw_polyline(closed, Color("193d49"), 22, true)
	draw_polyline(closed, Color("36707a"), 10, true)
	for record in catalog.territories:
		for polygon in regions[record.id]:
			var color: Color = COLORS[record.biome]
			draw_colored_polygon(polygon, color.lightened(0.13) if record.id == selected_id else color)
			var edge: PackedVector2Array = polygon.duplicate()
			edge.append(polygon[0])
			draw_polyline(edge, Color("283e39"), 2, true)
			_draw_terrain(polygon, record)
	if regions.has(selected_id):
		for polygon in regions[selected_id]:
			var edge: PackedVector2Array = polygon.duplicate()
			edge.append(polygon[0])
			draw_polyline(edge, Color("f0d792"), 3, true)
	draw_polyline(closed, Color("c1bd8e"), 2, true)
	draw_rect(Rect2(0, 626, 1280, 94), Color("10212b"))
	# Compass in the open northwest sea.
	draw_line(Vector2(45, 109), Vector2(45, 155), Color("c8c2a3"), 1, true)
	draw_line(Vector2(25, 134), Vector2(65, 134), Color("c8c2a3"), 1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(45, 107), Vector2(39, 132), Vector2(51, 132)]), Color("e1d6b0"))

func _draw_terrain(polygon: PackedVector2Array, record: Dictionary) -> void:
	var center := Vector2(record.position[0], record.position[1])
	for y in range(120, 590, 29):
		for x in range(80, 1220, 36):
			var p := Vector2(x + (y % 17), y)
			if not Geometry2D.is_point_in_polygon(p, polygon) or (absf(p.x - center.x) < 105 and absf(p.y - center.y) < 46):
				continue
			var ink := Color(0.08, 0.19, 0.15, 0.22)
			if record.biome in ["mountain", "snow", "ash"]:
				draw_polyline(PackedVector2Array([p + Vector2(-7, 4), p + Vector2(0, -7), p + Vector2(7, 4)]), ink, 2, true)
			elif record.biome == "forest":
				draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 3), p + Vector2(0, -7), p + Vector2(5, 3)]), ink)
			else:
				draw_line(p, p + Vector2(8, -2), ink, 1, true)

func _label(text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff8de"))
	label.add_theme_color_override("font_shadow_color", Color("152722"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label
