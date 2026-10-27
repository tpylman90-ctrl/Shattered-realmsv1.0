extends GutTest
const CAMP:="user://test_quests_campaign.cfg"
const PACK:="user://test_quests_pack.cfg"
func before_each() -> void:
	for path in [CAMP,PACK]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
func after_each() -> void:
	for path in [CAMP,PACK]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
func progress() -> CampaignState:
	return CampaignState.new(CAMP,PACK)

func test_every_region_has_a_complete_arc_and_references_valid_content() -> void:
	var campaign:=progress()
	var inventory:=EquipmentState.new(PACK,CAMP)
	assert_eq(campaign.quests.quests.size(),111)
	for region in campaign.data.regions:
		assert_eq(campaign.quest_count(region).y,3 if region=="deep" else 6)
		for quest in campaign.quests.quests.values():
			assert_true(campaign.data.regions.has(quest.region))
			for prerequisite in quest.requires:assert_true(campaign.quests.quests.has(prerequisite))
			for item in quest.reward.items:assert_true(inventory.catalog.items.has(item))
			if quest.goal.kind=="delivery":assert_true(inventory.catalog.items.has(quest.goal.item))

func test_survey_delivery_choices_and_claims_survive_reload_without_duplicate_rewards() -> void:
	var campaign:=progress()
	assert_false(campaign.discover("frostpeaks:first"),"Unvisited sites cannot be credited")
	assert_false(campaign.claim_quest("ravenwood:anchor","roads"))
	assert_eq(campaign.quest_status("ravenwood:signs"),"active")
	assert_true(campaign.discover("ravenwood:first"));assert_false(campaign.discover("ravenwood:first"))
	assert_true(campaign.discover("ravenwood:second"))
	assert_true(campaign.claim_quest("ravenwood:signs"))
	var gold:=campaign.gold
	assert_false(campaign.claim_quest("ravenwood:signs"));assert_eq(campaign.gold,gold)
	var inventory:=EquipmentState.new(PACK,CAMP)
	var timber:=int(inventory.quantities.seasoned_wood)
	assert_true(campaign.claim_quest("ravenwood:supplies"))
	inventory=EquipmentState.new(PACK,CAMP)
	assert_eq(int(inventory.quantities.seasoned_wood),timber-3)
	campaign.encounters.append("ravenwood:0");campaign.cleared.append("ravenwood")
	assert_true(campaign.claim_quest("ravenwood:threshold"))
	assert_false(campaign.claim_quest("ravenwood:anchor","invalid"))
	assert_true(campaign.claim_quest("ravenwood:anchor","watch"))
	assert_false(campaign.claim_quest("ravenwood:anchor","roads"))
	var restored:=progress()
	assert_eq(restored.story_choices.ravenwood,"watch")
	assert_eq(restored.discoveries.size(),2)
	assert_eq(restored.quest_count("ravenwood").x,4)

func test_all_111_quests_can_complete_with_canon_settlements_unchanged() -> void:
	var campaign:=progress();var inventory:=EquipmentState.new(PACK,CAMP)
	inventory.quantities.iron_ingot=200;inventory.quantities.seasoned_wood=200;inventory.quantities.leather_strip=200;inventory.save()
	for region in campaign.data.regions:
		if region=="deep":continue
		campaign.visited.append(region)
		for site in campaign.quests.sites[region]:assert_true(campaign.discover(site.id))
		campaign.encounters.append(region+":0");campaign.encounters.append(region+(":101" if region=="ravenwood" else ":100"));campaign.cleared.append(region)
		assert_true(campaign.recruit(campaign.data.regions[region].hero_pair[0]))
		for suffix in ["signs","supplies","road","threshold","anchor","oath"]:
			assert_true(campaign.claim_quest(region+":"+suffix,"roads" if suffix=="anchor" else ""),region+":"+suffix)
		assert_eq(campaign.quest_count(region),Vector2i(6,6))
	campaign.visited.append("deep")
	for stage in range(3):
		campaign.final_stage=stage+1
		assert_true(campaign.claim_quest("deep:front"+str(stage)))
	assert_eq(campaign.claimed_quests.size(),111)
	assert_eq(progress().claimed_quests.size(),111)
	for region in ["eldergrove","shadowfen","cursed_mire"]:assert_eq(campaign.data.regions[region].settlement,"")

func test_boss_telegraph_guard_poison_cleanse_and_revival() -> void:
	var campaign:=progress();campaign.cleared.append("ravenwood");campaign.recruit("ravenwood_1")
	var battle:=BattleState.new();battle.setup(campaign,"marsh",2)
	var foe:Dictionary=battle.enemies[0]
	battle._enemy_action(foe);battle._enemy_action(foe)
	assert_true(str(foe.intent).begins_with("POWER"))
	battle.waiting=1;assert_true(battle.act("skill"))
	for ally in battle.allies:assert_true(ally.guard)
	battle._enemy_action(foe)
	for ally in battle.allies:assert_false(ally.poison,"Ward blocks poison")
	battle._enemy_action(foe);battle._enemy_action(foe);battle._enemy_action(foe)
	assert_true(battle.allies.any(func(unit):return unit.poison))
	battle.inventory.quantities.antidote=1;battle.waiting=0;assert_true(battle.act("antidote"))
	for ally in battle.allies:assert_false(ally.poison)
	battle.allies[1].hp=0;battle.waiting=0
	assert_false(battle.act("revive"),"Revival requires healer discipline")
	campaign.disciplines.append("healer");assert_true(battle.act("revive"));assert_gt(int(battle.allies[1].hp),0)
	battle.waiting=0;assert_false(battle.act("invalid"))

func test_real_regional_discovery_cannot_be_overwritten_by_exploration_save() -> void:
	get_tree().set_meta("campaign_region","frostpeaks");get_tree().set_meta("campaign_room","forest")
	var area=load("res://scenes/campaign_area.tscn").instantiate()
	area.baking=true
	add_child_autofree(area);area.set_physics_process(false)
	var campaign:=progress();campaign.visited.append("frostpeaks");campaign.current="frostpeaks";campaign.save()
	area.campaign=campaign;area.baking=false;area.player.position.z=6.0
	assert_eq(area.nearby_discovery().id,"frostpeaks:first")
	area._interact();area.persist_exploration()
	assert_true(area._can_camp(),"Outdoor camps are safe")
	area.load_room("d0",0)
	assert_false(area._can_camp(),"Cannot rest beside a live encounter")
	campaign.encounters.append("frostpeaks:0")
	assert_true(area._can_camp(),"Cleared chamber becomes a checkpoint")
	area.load_room("forest",6.0)
	assert_true("frostpeaks:first" in progress().discoveries)
	assert_true(area.nearby_discovery().is_empty())
	await get_tree().process_frame
	area.baking=true;area.free()
	await get_tree().process_frame
	for key in ["campaign_region","campaign_room"]:
		if get_tree().has_meta(key):get_tree().remove_meta(key)

func test_fort_tutorial_has_temporary_squad_without_recruiting_a_guardian() -> void:
	var campaign:=progress();var battle:=BattleState.new();battle.setup(campaign,"ravenwood",101)
	assert_eq(battle.allies.size(),2)
	assert_eq(battle.allies[1].id,"fort_watch")
	assert_eq(battle.enemies[0].name,"Blackthorn Alpha Wolf")
	assert_false(battle.boss)
	assert_true(campaign.recruited.is_empty())
	battle.enemies[0].hp=0;battle._check_end()
	assert_eq(battle.outcome,"victory")
	assert_false("ravenwood" in campaign.cleared)
	assert_eq(campaign.quest_status("ravenwood:road"),"ready")

func test_repeatable_patrols_earn_resources_but_cannot_replay_a_reward() -> void:
	var campaign:=progress()
	assert_true(campaign.reward("ravenwood",1001,"sword",false).is_empty(),"Cannot skip patrol sequence")
	for i in range(3):
		assert_false(campaign.reward("ravenwood",1000+i,"sword",false).is_empty())
		var coins:=campaign.gold
		assert_true(campaign.reward("ravenwood",1000+i,"sword",false).is_empty())
		assert_eq(campaign.gold,coins)
	assert_eq(int(progress().patrols.ravenwood),3)
	var inventory:=EquipmentState.new(PACK,CAMP)
	assert_eq(int(inventory.quantities.entropic_essence),1)
	assert_false("ravenwood" in campaign.cleared,"Patrols cannot restore an anchor")
	assert_true(campaign.reward("deep",1000,"sword",false).is_empty())
