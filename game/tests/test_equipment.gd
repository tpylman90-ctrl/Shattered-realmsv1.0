extends GutTest
const State := preload("res://scripts/equipment_state.gd")
const Model := preload("res://scripts/weapon_model.gd")
const TEST_SAVE := "user://test_equipment.cfg"
func before_each() -> void:
	if FileAccess.file_exists(TEST_SAVE): DirAccess.remove_absolute(TEST_SAVE)
func after_each() -> void:
	if FileAccess.file_exists(TEST_SAVE): DirAccess.remove_absolute(TEST_SAVE)

func test_complete_territory_family_matrix_and_real_weapon_geometry() -> void:
	var state=State.new(TEST_SAVE)
	assert_eq(state.catalog.territories.size(),19)
	assert_eq(state.catalog.families.size(),10)
	var model=Model.new()
	add_child_autofree(model)
	for territory in state.catalog.territories:
		for family in state.catalog.families:
			var id: String = territory+"_"+family
			assert_true(state.catalog.items.has(id))
			model.build(state.catalog.items[id])
			assert_gte(model.get_child_count(),4,id+" has distinct material surfaces")
			assert_lte(model.get_child_count(),7,id+" batches repeated parts")
			assert_gt(model.triangle_count,200)
			assert_lt(model.triangle_count,16000,id+" stays within the weapon triangle budget")
			for child in model.get_children():
				assert_true(child is MeshInstance3D)
				assert_not_null(child.mesh)

func test_crafting_consumes_exact_materials_and_never_grants_locked_designs() -> void:
	var state=State.new(TEST_SAVE)
	var id := "ravenwood_sword"
	var before: Dictionary = state.quantities.duplicate()
	assert_true(state.forge(id))
	for material in state.catalog.items[id].materials:
		assert_eq(state.quantities[material],before[material]-int(state.catalog.items[id].materials[material]))
	assert_eq(state.quantities[id],1)
	assert_false(state.forge("deep_cannon"))
	state.quantities.iron_ingot=0
	assert_false(state.forge(id))
	assert_eq(state.quantities[id],1)

func test_equip_stats_save_round_trip_and_unique_resource_caches() -> void:
	var state=State.new(TEST_SAVE)
	assert_true(state.claim_cache("mine",{"iron_ingot":18}))
	assert_false(state.claim_cache("mine",{"iron_ingot":18}))
	assert_true(state.equip("starter_staff"))
	assert_gt(state.stats().magic,10)
	assert_false(state.equip("deep_sword"))
	var restored=State.new(TEST_SAVE)
	assert_eq(restored.equipped.weapon,"starter_staff")
	assert_eq(restored.quantities.iron_ingot,23)
	assert_true("mine" in restored.claimed)

func test_consumables_have_real_effects_and_do_not_waste_at_full_health() -> void:
	var state=State.new(TEST_SAVE)
	assert_false(state.use_item("potion"))
	assert_eq(state.quantities.potion,3)
	state.hp=20
	assert_true(state.use_item("potion"))
	assert_eq(state.hp,70)
	assert_eq(state.quantities.potion,2)
	state.mp=10
	assert_true(state.use_item("ether"))
	assert_eq(state.mp,30)
	state.poisoned=true
	assert_true(state.use_item("antidote"))
	assert_false(state.poisoned)

func test_battle_weapon_mount_tracks_the_native_hand_on_both_starters() -> void:
	var state=State.new(TEST_SAVE)
	for appearance in ["male","female"]:
		var hero=load("res://scripts/hero_model.gd").new();add_child_autofree(hero);hero.setup(appearance,false)
		var weapon:WeaponModel=hero.hold_battle_weapon(state.catalog.items.starter_sword)
		assert_not_null(weapon)
		assert_true(weapon.get_parent() is BoneAttachment3D)
		assert_eq(weapon.get_parent().bone_name,"hand_r")
		var bounds:=weapon.model_bounds()
		assert_gt(bounds.size.y,1.0)
		assert_lt(bounds.size.y,2.0)
