extends GutTest

const Recipe = preload("res://scripts/recipe.gd")

func test_missing_material_blocks_crafting() -> void:
	assert_false(Recipe.can_craft({"iron": 3}, {"iron": 3, "wood": 1}))

func test_exact_materials_allow_crafting_without_consuming_them() -> void:
	var materials := {"iron": 3, "wood": 1}
	assert_true(Recipe.can_craft(materials, {"iron": 3, "wood": 1}))
	assert_eq(materials["iron"], 3)

func test_invalid_recipe_blocks_crafting() -> void:
	assert_false(Recipe.can_craft({}, {}))
	assert_false(Recipe.can_craft({"iron": 4}, {"iron": -1}))
