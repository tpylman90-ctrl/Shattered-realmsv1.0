extends GutTest

func make_board():
	var board = load("res://scenes/territory_board.tscn").instantiate()
	board.save_enabled = false
	add_child_autofree(board)
	return board

func test_paths_obey_water_mountains_and_hostile_occupation() -> void:
	var board = make_board()
	for site in board.data.sites:
		var cell := Vector2i(site.cell[0],site.cell[1])
		var path: Array[Vector2i] = board.path_to(cell)
		if site.kind == "enemy":
			assert_true(path.is_empty(), "Hostile army needs battle integration")
		elif site.id != "blackthorn":
			assert_false(path.is_empty(), site.name + " can be reached")
		var previous: Vector2i = board.army
		for step in path:
			assert_true(board.is_open(step))
			assert_true(step - previous in board.DIRECTIONS, "Every route step is adjacent")
			previous = step
	assert_true(board.path_to(Vector2i(5,1)).is_empty(), "Water cannot be crossed")

func test_movement_turn_budget_and_resource_cache_cannot_repeat() -> void:
	var board = make_board()
	board.selected = Vector2i(3,2)
	var cost: int = board.path_to(board.selected).size()
	board.move_selected()
	assert_eq(board.army, Vector2i(3,2))
	assert_eq(board.movement, 3 - cost)
	assert_eq(board.resources.wood, 8)
	board.end_turn()
	board.selected = Vector2i(1,3)
	board.move_selected()
	board.end_turn()
	board.selected = Vector2i(3,2)
	board.move_selected()
	assert_eq(board.resources.wood, 8, "Returning does not farm the cache")
	board.movement = 0
	board.selected = Vector2i(4,2)
	board.move_selected()
	assert_eq(board.army, Vector2i(3,2), "No movement without points")
	board.end_turn()
	assert_eq(board.movement, 3)

func test_campaign_round_trip_preserves_expedition_and_inventory() -> void:
	var board = make_board()
	board.selected = Vector2i(3,2)
	board.move_selected()
	board.save_enabled = true
	var path := "user://test_ravenwood_campaign.cfg"
	assert_eq(board.persist(path), OK)
	var restored = make_board()
	restored.load_campaign(path)
	assert_eq(restored.army, board.army)
	assert_eq(restored.movement, board.movement)
	assert_eq(restored.resources, board.resources)
	assert_eq(restored.collected, board.collected)
	DirAccess.remove_absolute(path)

func test_touch_selects_hex_and_town_entry_requires_presence() -> void:
	var board = make_board()
	assert_true(board.explore.visible)
	var event := InputEventScreenTouch.new()
	event.pressed = true
	event.position = board.cell_center(Vector2i(3,2))
	board._gui_input(event)
	assert_eq(board.selected, Vector2i(3,2))
	assert_false(board.explore.visible)
	assert_false(board.travel.disabled)
	board.selected = Vector2i(8,5)
	board.refresh()
	assert_true(board.travel.disabled, "Enemy cannot be bypassed by moving")
