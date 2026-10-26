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
