extends GutTest

func test_roster_selection_and_settlement_rules() -> void:
	var scene = load("res://scenes/world_map.tscn").instantiate()
	add_child_autofree(scene)
	assert_eq(scene.tiles.size(), 19)
	var settlements := {}
	for record in scene.catalog.territories:
		assert_false(settlements.has(record.id), "Unique territory ID")
		settlements[record.id] = record.settlement
		scene.select_territory(record.id)
		assert_eq(scene.selected_id, record.id)
		assert_eq(scene.enter.visible, record.id == "ravenwood", "Only implemented exploration can open")
	assert_eq(settlements.eldergrove, "")
	assert_eq(settlements.shadowfen, "")
	assert_eq(settlements.cursed_mire, "")
	assert_eq(settlements.marsh, "Wickermoor")
	assert_eq(settlements.silvermere, "Silverkeep")
	assert_eq(settlements.westreach, "Westhaven")
	assert_eq(settlements.ravenwood, "Blackthorn")

func test_continent_regions_cover_land_and_match_touch_targets() -> void:
	var scene = load("res://scenes/world_map.tscn").instantiate()
	add_child_autofree(scene)
	assert_eq(scene.territory_at(Vector2(20, 200)), "", "Ocean does not select a region")
	for record in scene.catalog.territories:
		var point := Vector2(record.position[0], record.position[1])
		assert_true(Geometry2D.is_point_in_polygon(point, scene.coast), record.id + " belongs to the continent")
		assert_eq(scene.territory_at(point), record.id, "Label and touch region agree")
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		scene._gui_input(event)
		assert_eq(scene.selected_id, record.id, "Tap selects the territory polygon")
	for y in range(120, 590, 17):
		for x in range(80, 1230, 19):
			var point := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(point, scene.coast):
				assert_ne(scene.territory_at(point), "", "No holes in continental territory coverage")
