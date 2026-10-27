extends GutTest
const CAMP:="user://test_full_campaign.cfg"
const PACK:="user://test_full_pack.cfg"
func before_each() -> void:
	for path in [CAMP,PACK]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
func after_each() -> void:
	for path in [CAMP,PACK]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
func progress() -> CampaignState:
	return CampaignState.new(CAMP,PACK)

func fight(campaign: CampaignState,region: String,stage: int,finale: bool = false) -> BattleState:
	campaign.rest(0)
	var battle:=BattleState.new();battle.setup(campaign,region,stage,finale)
	for i in range(18000):
		if not battle.outcome.is_empty():break
		battle.tick(0.25)
		if battle.waiting>=0:
			var ally: Dictionary=battle.allies[battle.waiting]
			var hurt:=false
			for unit in battle.allies:
				if unit.hp<unit.max_hp*0.45:hurt=true
			if hurt and ally.mp>=8:battle.act("heal")
			elif ally.mp>=6:battle.act("skill")
			else:battle.act("attack")
	return battle

func test_world_canon_non_linear_graph_and_no_settlement_constraints() -> void:
	var campaign:=progress()
	assert_eq(campaign.data.regions.size(),19)
	for id in ["eldergrove","shadowfen","cursed_mire"]:assert_eq(campaign.data.regions[id].settlement,"")
	assert_eq(campaign.data.regions.marsh.settlement,"Wickermoor")
	assert_eq(campaign.data.regions.ashen.boss,"Inferno-Lord Vulgrim")
	assert_eq(campaign.data.regions.ravenwood.chambers,["Root Gate","Burial Hall","Sunken Gallery","Beast Chamber","Reliquary"])
	assert_false(campaign.can_travel("deep"))
	assert_true(campaign.can_travel("frostpeaks"))
	assert_true(campaign.can_travel("silvermere"))
	for id in campaign.data.regions:
		for neighbor in campaign.data.regions[id].neighbors:assert_true(id in campaign.data.regions[neighbor].neighbors,"Reciprocal world routes")

func test_wait_atb_commands_poison_guard_and_defeat() -> void:
	var campaign:=progress();var battle:=BattleState.new();battle.setup(campaign,"ravenwood",0)
	assert_false(battle.act("attack"))
	for i in range(80):battle.tick(0.1)
	assert_eq(battle.waiting,0)
	var foe_bar:float=battle.enemies[0].atb
	battle.tick(20)
	assert_eq(battle.enemies[0].atb,foe_bar,"ATB pauses for commands")
	assert_true(battle.act("guard"))
	assert_true(battle.allies[0].guard)
	battle.waiting=0;battle.allies[0].mp=0
	assert_false(battle.act("skill"))
	battle.allies[0].hp=0;battle.waiting=-1;battle._check_end()
	assert_eq(battle.outcome,"defeat")
	assert_true(campaign.encounters.is_empty(),"Defeat cannot grant progression")

func test_full_campaign_can_reach_three_front_ending_with_no_duplicate_heroes() -> void:
	var campaign:=progress()
	var frontier:Array[String]=["ravenwood"]
	var seen:={"ravenwood":true}
	while not frontier.is_empty():
		var id:String=frontier.pop_front()
		assert_true(campaign.travel(id),"Reach "+id)
		var region:Dictionary=campaign.data.regions[id]
		for stage in range(region.chambers.size()):
			var battle:=fight(campaign,id,stage)
			assert_eq(battle.outcome,"victory",id+" chamber "+str(stage))
			if battle.outcome!="victory":return
		assert_true(id in campaign.cleared)
		assert_true(campaign.recruit(region.hero_pair[0]))
		assert_false(campaign.recruit(region.hero_pair[1]),"One recruit; the other defends")
		for neighbor in region.neighbors:
			if neighbor!="deep" and not seen.has(neighbor):seen[neighbor]=true;frontier.append(neighbor)
	assert_eq(campaign.recruited.size(),18)
	assert_true(campaign.travel("deep"))
	for stage in range(3):
		var battle:=fight(campaign,"deep",stage,true)
		assert_eq(battle.outcome,"victory","Final front "+str(stage))
		if battle.outcome!="victory":return
	assert_eq(campaign.final_stage,3)
	assert_eq(campaign.final_used.size(),9)
	var unique:={}
	for hero in campaign.final_used:unique[hero]=true
	assert_eq(unique.size(),9,"Three distinct groups of three")
	var restored:=progress()
	assert_eq(restored.final_stage,3)
	assert_eq(restored.recruited.size(),18)
	assert_true("deep" in restored.cleared)

func test_rewards_and_recruitment_are_idempotent_and_shop_stats_persist() -> void:
	var campaign:=progress();var battle:=fight(campaign,"ravenwood",4)
	assert_eq(battle.outcome,"victory")
	var gold:=campaign.gold
	assert_true(campaign.reward("ravenwood",4,"sword",true).is_empty())
	assert_eq(campaign.gold,gold)
	assert_true(campaign.recruit("ravenwood_0"))
	assert_false(campaign.recruit("ravenwood_1"))
	assert_false(campaign.set_party(["ravenwood_0","ravenwood_0"]))
	campaign.gold=500;assert_true(campaign.buy("padded_coat"))
	var inventory:=EquipmentState.new(PACK);assert_true(inventory.equip("padded_coat"));assert_gt(inventory.stats().defense,6)
	assert_false(campaign.buy("deep_cannon"),"Unvisited regional stock is unavailable")

func test_forge_qualities_infusions_and_fragile_weapons() -> void:
	var inventory:=EquipmentState.new(PACK)
	assert_true(inventory.claim_cache("test",{"iron_ingot":40,"seasoned_wood":30,"leather_strip":20,"entropic_essence":4}))
	assert_true(inventory.forge("ravenwood_sword","masterwork",true))
	var master:=inventory.last_forged
	assert_gt(int(inventory.catalog.items[master].attack),int(inventory.catalog.items.ravenwood_sword.attack))
	assert_eq(inventory.quantities.entropic_essence,3)
	assert_true(inventory.forge("ravenwood_axe","fractured"))
	assert_true(inventory.equip(inventory.last_forged))
	assert_true(inventory.break_fragile())
	assert_eq(inventory.equipped.weapon,"starter_sword")
	assert_eq(inventory.quantities.ravenwood_axe_fractured,0)

func test_army_actions_range_turns_and_territory_rewards() -> void:
	var campaign:=progress();var army:=ArmyState.new();army.setup(campaign,"ravenwood")
	assert_false(army.act(0,Vector2i(5,1)),"Melee cannot strike across the battlefield")
	assert_true(army.act(0,Vector2i(1,1)))
	assert_false(army.act(0,Vector2i(2,1)),"Rocks block the route")
	army.end_turn();assert_eq(army.units[0].ap,2)
	for unit in army.units:
		if unit.side==1:unit.hp=0
	army._check();assert_eq(army.outcome,"victory");assert_true("ravenwood" in campaign.secured)
	var restored:=progress();assert_true("ravenwood" in restored.secured)

func test_regional_rooms_scene_generation_and_dungeon_gates() -> void:
	for id in ["ravenwood","ashen","frostpeaks","marsh","golden","deep"]:
		get_tree().set_meta("campaign_region",id)
		get_tree().set_meta("campaign_room","d0")
		var area=load("res://scenes/campaign_area.tscn").instantiate()
		area.baking=true
		add_child_autofree(area)
		area.set_physics_process(false)
		assert_eq(area.room_id,"d0")
		assert_false(area.can_walk(Vector3(0,0,-6)),"Live encounter blocks bypass")
		var registry:Dictionary=area._room_registry()
		assert_eq(registry.d0.name,area.region_record.chambers[0])
		assert_true(is_instance_valid(area.scenery))
		assert_lt(area.scenery.get_child_count(),45,"Dungeon props remain batched")
		area.free()
		await get_tree().process_frame
	for key in ["campaign_region","campaign_room"]:
		if get_tree().has_meta(key):get_tree().remove_meta(key)

func test_recruited_chest_unlocks_discipline_on_equip() -> void:
	var campaign:=progress()
	campaign.cleared.append("ravenwood")
	assert_true(campaign.recruit("ravenwood_1"))
	var inventory:=EquipmentState.new(PACK,CAMP)
	assert_eq(inventory.quantities.chest_ravenwood_1,1)
	assert_true(inventory.equip("chest_ravenwood_1"))
	var restored:=progress()
	assert_true("guardian" in restored.disciplines)
	assert_true("ravenwood_0" in restored.defenders)

func test_underworked_weapon_has_reduced_durability_instead_of_reduced_damage() -> void:
	var inventory:=EquipmentState.new(PACK,CAMP)
	assert_true(inventory.forge("ravenwood_sword","underworked"))
	var made:=inventory.last_forged
	assert_eq(int(inventory.catalog.items[made].attack),int(inventory.catalog.items.ravenwood_sword.attack))
	assert_true(inventory.equip(made))
	for i in range(11):assert_false(inventory.break_fragile())
	var restored:=EquipmentState.new(PACK,CAMP)
	assert_true(restored.break_fragile(),"Wear survives reload and breaks on attack 12")
	assert_eq(restored.quantities[made],0)
