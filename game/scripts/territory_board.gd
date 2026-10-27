extends Control

const SAVE_PATH := "user://ravenwood_campaign.cfg"
const DIRECTIONS := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,1)]
const RADIUS := 33.0
var data: Dictionary
var blocked_cells: Dictionary = {}
var water_cells: Dictionary = {}
var army := Vector2i(1, 3)
var selected := Vector2i(1, 3)
var turn := 1
var movement := 3
var resources := {"wood": 0, "iron": 0}
var collected: Array = []
var visited: Array = ["blackthorn"]
var save_enabled := true
var status: Label
var info: Label
var message: Label
var travel: Button
var explore: Button

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/ravenwood_board.json"))
	for point in data.blocked:
		blocked_cells[Vector2i(point[0], point[1])] = true
	for point in data.water:
		water_cells[Vector2i(point[0], point[1])] = true
	if save_enabled:
		load_campaign()
	selected = army
	_label("RAVENWOOD", Vector2(30, 18), 32)
	_label("TERRITORY BOARD  /  Your expedition", Vector2(32, 57), 17)
	_button("WORLD MAP", Vector2(1060, 22), Vector2(185, 50), func(): get_tree().change_scene_to_file("res://scenes/world_map.tscn"))
	status = _label("", Vector2(34, 101), 20)
	for site in data.sites:
		var p := cell_center(Vector2i(site.cell[0], site.cell[1]))
		var label := _label(site.name, p + Vector2(-91, 25), 15)
		label.size.x = 182
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info = _label("", Vector2(970, 164), 21)
	info.size = Vector2(275, 235)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	travel = _button("MOVE EXPEDITION", Vector2(970, 424), Vector2(275, 56), move_selected)
	explore = _button("ENTER BLACKTHORN", Vector2(970, 492), Vector2(275, 56), enter_town)
	_button("END TURN", Vector2(970, 560), Vector2(275, 56), end_turn)
	message = _label("Select a hex. Gold outlines show reachable ground.", Vector2(32, 656), 18)
	message.size.x = 900
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("◆ Town   ▲ Resource   ◇ Ruins   ⚑ Hostile", Vector2(34, 618), 16)
	refresh()

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(100 + sqrt(3.0) * RADIUS * (cell.x + cell.y * 0.5), 180 + 1.5 * RADIUS * cell.y)

func hex_polygon(cell: Vector2i) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		points.append(cell_center(cell) + Vector2.from_angle(deg_to_rad(60 * i - 30)) * (RADIUS - 1))
	return points

func site_at(cell: Vector2i) -> Dictionary:
	for site in data.sites:
		if Vector2i(site.cell[0], site.cell[1]) == cell:
			return site
	return {}

func is_open(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= int(data.columns) or cell.y >= int(data.rows):
		return false
	if blocked_cells.has(cell) or water_cells.has(cell):
		return false
	return site_at(cell).get("kind", "") != "enemy"

func path_to(goal: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not is_open(goal):
		return result
	var frontier: Array[Vector2i] = [army]
	var previous := {army: army}
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		if cell == goal:
			break
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if is_open(next) and not previous.has(next):
				previous[next] = cell
				frontier.append(next)
	if not previous.has(goal):
		return result
	var cursor := goal
	while cursor != army:
		result.push_front(cursor)
		cursor = previous[cursor]
	return result

func move_selected() -> void:
	var path := path_to(selected)
	if path.is_empty() or path.size() > movement:
		return
	army = selected
	movement -= path.size()
	var site := site_at(army)
	message.text = "Expedition moved %d hexes." % path.size()
	if not site.is_empty():
		if not site.id in visited:
			visited.append(site.id)
		if site.kind in ["wood", "iron"] and not site.id in collected:
			var amount := 8 if site.kind == "wood" else 5
			resources[site.kind] += amount
			collected.append(site.id)
			message.text = "Recovered %d %s. This cache is now collected." % [amount, site.kind]
		elif site.kind in ["dungeon", "outpost"]:
			message.text = site.description
	persist()
	refresh()

func end_turn() -> void:
	turn += 1
	movement = int(data.movement_per_turn)
	message.text = "New turn. Expedition movement restored. Enemy turns arrive with the battle system."
	persist()
	refresh()

func enter_town() -> void:
	if site_at(army).get("id", "") != "blackthorn":
		return
	persist()
	get_tree().change_scene_to_file("res://scenes/ravenwood.tscn" if FileAccess.file_exists("user://hero.cfg") else "res://scenes/hero_select.tscn")

func refresh() -> void:
	status.text = "Turn %d     Movement %d / %d     Wood %d     Iron %d" % [turn, movement, data.movement_per_turn, resources.wood, resources.iron]
	var site := site_at(selected)
	var path := path_to(selected)
	var description := "Open woodland\n\nSelect a destination within your remaining movement."
	if not site.is_empty():
		description = site.name + "\n\n" + site.description
		if site.id in collected:
			description += "\n\nCache collected."
	if selected != army and not path.is_empty():
		description += "\n\nRoute: %d hexes" % path.size()
	info.text = description
	travel.disabled = path.is_empty() or path.size() > movement
	explore.visible = selected == army and site.get("id", "") == "blackthorn"
	queue_redraw()

func persist(path: String = SAVE_PATH) -> Error:
	if not save_enabled:
		return OK
	var config := ConfigFile.new()
	config.set_value("campaign", "state", {"army": army, "turn": turn, "movement": movement, "resources": resources, "collected": collected, "visited": visited})
	var error := config.save(path)
	if error != OK and is_instance_valid(message):
		message.text = "Unable to save expedition progress."
	return error

func load_campaign(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	var state: Variant = config.get_value("campaign", "state", {})
	if not state is Dictionary or not state.get("army") is Vector2i or not is_open(state.army):
		return
	army = state.army
	turn = maxi(1, int(state.get("turn", 1)))
	movement = clampi(int(state.get("movement", 3)), 0, int(data.movement_per_turn))
	var stock: Variant = state.get("resources", {})
	if stock is Dictionary:
		resources = {"wood": maxi(0, int(stock.get("wood", 0))), "iron": maxi(0, int(stock.get("iron", 0)))}
	if state.get("collected", []) is Array:
		collected = state.get("collected", [])
	if state.get("visited", []) is Array:
		visited = state.get("visited", [])

func _gui_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	else:
		return
	for y in range(int(data.rows)):
		for x in range(int(data.columns)):
			var cell := Vector2i(x, y)
			if Geometry2D.is_point_in_polygon(point, hex_polygon(cell)):
				selected = cell
				refresh()
				accept_event()
				return

func movement_distances() -> Dictionary:
	var distances := {army: 0}
	var frontier: Array[Vector2i] = [army]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		if distances[cell] >= movement:
			continue
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if is_open(next) and not distances.has(next):
				distances[next] = distances[cell] + 1
				frontier.append(next)
	return distances

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("142c2a"))
	draw_rect(Rect2(950, 145, 310, 485), Color("0e211f"))
	if data.is_empty():
		return
	var distances := movement_distances()
	for y in range(int(data.rows)):
		for x in range(int(data.columns)):
			var cell := Vector2i(x, y)
			var p := cell_center(cell)
			var polygon := hex_polygon(cell)
			var color := Color("42604a") if (x + y) % 3 else Color("496950")
			if blocked_cells.has(cell):
				color = Color("6a7267")
			elif water_cells.has(cell):
				color = Color("366477")
			draw_colored_polygon(polygon, color)
			var edge := polygon.duplicate()
			edge.append(polygon[0])
			var reachable := distances.has(cell) and cell != army
			draw_polyline(edge, Color("a4a87b") if reachable else Color("2d453b"), 1, true)
			if blocked_cells.has(cell):
				draw_colored_polygon(PackedVector2Array([p + Vector2(-13,11),p + Vector2(0,-15),p + Vector2(13,11)]),Color("454e43"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(0,-15),p + Vector2(0,11),p + Vector2(13,11)]),Color("858a75"))
			elif water_cells.has(cell):
				for offset in [-7, 3]:
					draw_line(p + Vector2(-13,offset),p + Vector2(13,offset - 3),Color("6a9395"),2,true)
			if site_at(cell).is_empty() and is_open(cell):
				for i in range(3):
					var tree := p + Vector2((i - 1) * 12, (i % 2) * 10 - 3)
					draw_colored_polygon(PackedVector2Array([tree + Vector2(-5,5), tree + Vector2(0,-8), tree + Vector2(5,5)]), Color("294b3a"))
			if selected == cell:
				draw_polyline(edge, Color("f4db99"), 3, true)
	var preview := path_to(selected)
	var last := cell_center(army)
	if preview.size() <= movement:
		for cell in preview:
			var next := cell_center(cell)
			draw_line(last, next, Color("e4cf8d"), 3, true)
			last = next
	for site in data.sites:
		var p := cell_center(Vector2i(site.cell[0], site.cell[1]))
		var color := Color("d08c7a") if site.kind == "enemy" else Color("ebd69a")
		draw_circle(p, 16, Color("1a302b"))
		if site.kind == "town":
			draw_rect(Rect2(p - Vector2(10,7),Vector2(20,18)),color)
			for offset in [-10, 6]:
				draw_rect(Rect2(p + Vector2(offset,-13),Vector2(5,24)),color)
		elif site.kind == "enemy":
			draw_line(p + Vector2(-5,12),p + Vector2(-5,-13),color,3)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-5,-13),p + Vector2(11,-8),p + Vector2(-5,-2)]),color)
		elif site.kind in ["wood", "iron"]:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0,-12),p + Vector2(11,9),p + Vector2(-11,9)]),color)
		else:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0,-11),p + Vector2(10,0),p + Vector2(0,11),p + Vector2(-10,0)]),color)
	var at := cell_center(army) + Vector2(-18,-18)
	draw_circle(at, 13, Color("173e55"))
	draw_arc(at,13,0,TAU,24,Color("f1d48b"),2,true)
	draw_line(at + Vector2(0,8),at + Vector2(0,-8),Color("fff0b8"),3)
	draw_colored_polygon(PackedVector2Array([at + Vector2(0,-9),at + Vector2(10,-5),at]),Color("fff0b8"))

func _label(text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("efe7cb"))
	label.add_theme_color_override("font_shadow_color", Color("122b25"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label

func _button(text: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.pressed.connect(callback)
	add_child(button)
	return button
