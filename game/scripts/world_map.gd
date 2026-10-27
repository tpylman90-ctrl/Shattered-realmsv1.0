extends Control

const COLORS := {
	"forest": Color("3e624b"), "snow": Color("91a9b0"),
	"mountain": Color("68716d"), "ash": Color("795148"),
	"marsh": Color("576544"), "plain": Color("7c8151"),
	"coast": Color("548079"), "desert": Color("b19260"), "deep": Color("594551")
}
var campaign:=CampaignState.new()
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
	enter.text = "EXPLORE RAVENWOOD"
	enter.position = Vector2(1000, 638)
	enter.size = Vector2(248, 54)
	enter.pressed.connect(_travel)
	add_child(enter)
	_label("Explore neighboring realms • Recruit 9 companions for the Deep", Vector2(750, 601), 14)
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
		detail.text = record.name + "\n" + description + ("   •   Anchor restored" if id in campaign.cleared else "   •   Explored" if id in campaign.visited else "   •   Neighboring route" if campaign.can_travel(id) else "   •   Reach a neighboring realm first")
		enter.visible = true
		enter.disabled = not campaign.can_travel(id)
		enter.text = "NEED 9 COMPANIONS" if id=="deep" and campaign.recruited.size()<9 else "EXPLORE "+record.name.to_upper()
		enter.add_theme_font_size_override("font_size",16)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("102b38"))
	# Quiet ocean strokes give scale without competing with place names.
	for y in range(100, 620, 38):
		for x in range(20, 1280, 95):
			draw_line(Vector2(x, y), Vector2(x + 22, y - 2), Color(0.35, 0.58, 0.64, 0.11), 1, true)
	_draw_frame()
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
	_draw_rivers()
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
	# Deterministic fine stippling adds relief without an image texture.
	for y in range(105, 595, 11):
		for x in range(65, 1230, 13):
			var p := Vector2(x + sin(float(y + x)) * 5, y)
			if Geometry2D.is_point_in_polygon(p, polygon):
				draw_circle(p, 1.0, Color(0.95, 0.89, 0.62, 0.07))
	for y in range(120, 590, 26):
		for x in range(80, 1220, 29):
			var p := Vector2(x + (y % 17), y + sin(float(x)) * 4)
			if not Geometry2D.is_point_in_polygon(p, polygon) or (absf(p.x - center.x) < 101 and absf(p.y - center.y) < 44):
				continue
			if record.biome in ["mountain", "snow", "ash"]:
				var height := 13.0 + fmod(float(x * y), 10.0)
				var left := p + Vector2(-11, 7)
				var peak := p + Vector2(0, -height)
				var right := p + Vector2(11, 7)
				var base := Color("4b5045") if record.biome != "ash" else Color("5e302c")
				draw_colored_polygon(PackedVector2Array([left, peak, right]), base)
				draw_colored_polygon(PackedVector2Array([peak, p + Vector2(0,7), right]), base.lightened(0.20))
				if record.biome == "snow":
					draw_colored_polygon(PackedVector2Array([peak,peak + Vector2(-4,9),peak + Vector2(2,6),peak + Vector2(5,11)]),Color("e1e5cd"))
				elif record.biome == "ash":
					draw_line(peak + Vector2(0,4),p + Vector2(3,6),Color("c58048"),1,true)
			elif record.biome == "forest":
				draw_line(p,p + Vector2(0,7),Color("443f2c"),2)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-8,4),p + Vector2(0,-13),p + Vector2(8,4)]),Color("234536"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(0,-13),p + Vector2(0,4),p + Vector2(8,4)]),Color("315640"))
			elif record.biome == "desert":
				draw_arc(p + Vector2(0,10),12,3.5,5.8,12,Color(0.35,0.25,0.13,0.25),1,true)
			elif record.biome == "marsh":
				draw_line(p,p + Vector2(10,0),Color("70805a"),2,true)
				draw_line(p + Vector2(3,0),p + Vector2(3,-6),Color("364c37"),1,true)
			else:
				draw_arc(p + Vector2(0,8),10,3.7,5.5,8,Color(0.11,0.26,0.20,0.20),1,true)

func _draw_rivers() -> void:
	for values in [ [[490,225],[465,260],[450,300],[452,355],[440,395],[430,450],[422,500],[425,541]], [[953,290],[935,320],[924,355],[930,395],[945,440],[953,485],[958,540],[970,584]] ]:
		var line := _points(values)
		draw_polyline(line,Color("33595a"),6,true)
		draw_polyline(line,Color("83b1a5"),2,true)

func _draw_frame() -> void:
	var gold := Color("a58d59")
	draw_line(Vector2(26,79),Vector2(1253,79),gold,1,true)
	draw_line(Vector2(26,621),Vector2(1253,621),gold,1,true)
	for corner in [Vector2(13,87),Vector2(1267,87),Vector2(13,618),Vector2(1267,618)]:
		var dx := 1.0 if corner.x < 640 else -1.0
		var dy := 1.0 if corner.y < 350 else -1.0
		draw_line(corner,corner + Vector2(22 * dx,0),gold,2,true)
		draw_line(corner,corner + Vector2(0,22 * dy),gold,2,true)
	# Eight-point compass rose, set in the northwest ocean margin.
	var center := Vector2(45,134)
	draw_arc(center,23,0,TAU,48,gold,1,true)
	for i in range(8):
		var direction := Vector2.from_angle(i * PI / 4)
		var side := direction.orthogonal() * 4
		var tip := center + direction * (29 if i % 2 == 0 else 18)
		draw_colored_polygon(PackedVector2Array([center - side,tip,center]),Color("c6b57d"))
		draw_colored_polygon(PackedVector2Array([center + side,tip,center]),Color("7a7958"))

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

func _travel() -> void:
	if not campaign.travel(selected_id):return
	get_tree().set_meta("campaign_region",selected_id)
	if get_tree().has_meta("campaign_room"):get_tree().remove_meta("campaign_room")
	get_tree().change_scene_to_file("res://scenes/woodland.tscn" if selected_id=="ravenwood" else "res://scenes/campaign_area.tscn")
