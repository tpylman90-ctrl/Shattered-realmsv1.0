extends SceneTree
func _initialize() -> void:call_deferred("run")
func settle() -> void:
	for i in range(4):await process_frame
func check(condition: bool,text: String) -> void:
	if not condition:push_error("FLOW FAILED: "+text);quit(1)
	assert(condition,text)
func press_named(parent: Node,text: String) -> bool:
	for child in parent.get_children():
		if child is Button and child.text==text:child.pressed.emit();return true
		if press_named(child,text):return true
	return false
func win_battle() -> void:
	var screen=current_scene
	screen.set_process(false)
	for i in range(20000):
		if not screen.state.outcome.is_empty():break
		screen.state.tick(0.25)
		if screen.state.waiting>=0:
			var ally:Dictionary=screen.state.allies[screen.state.waiting]
			var hurt:=false
			for unit in screen.state.allies:
				if unit.hp>0 and unit.hp<unit.max_hp*0.45:hurt=true
			if hurt and ally.mp>=8:screen.state.act("heal")
			elif hurt and screen.state.inventory.quantities.get("potion",0)>0:screen.state.act("potion")
			elif hurt and ally.mp<8:screen.state.act("guard")
			elif ally.mp>=6:screen.state.act("skill")
			else:screen.state.act("attack")
	check(screen.state.outcome=="victory","Battle victory")
	screen._refresh();screen._finish();await settle()
func run() -> void:
	set_meta("campaign_region","ravenwood")
	change_scene_to_file("res://scenes/quests.tscn");await settle()
	check(press_named(current_scene,"DEFEND BLACKTHORN · ALPHA WOLF"),"Captain mission encounter")
	await settle();await win_battle()
	check(current_scene.scene_file_path.ends_with("quests.tscn"),"Tutorial returns to mission journal")
	check(press_named(current_scene,"COMPLETE · The broken watch"),"Claim tutorial reward")
	check("ravenwood:road" in CampaignState.new().claimed_quests,"Tutorial reward persisted")
	change_scene_to_file("res://scenes/woodland.tscn");await settle()
	current_scene.set_physics_process(false)
	current_scene.load_room("spring",6);current_scene._interact()
	current_scene.load_room("ruins",7);current_scene._interact()
	check(CampaignState.new().discoveries.size()==2,"Real roadside surveys")
	current_scene.load_room("ruins",-22);current_scene._interact();await settle()
	check(current_scene.scene_file_path.ends_with("campaign_area.tscn"),"Ravenwood dungeon transition")
	check(current_scene.room_id=="d0","Hollow Oak Root Gate")
	for stage in range(5):
		if stage>0:current_scene.load_room("d"+str(stage),0)
		current_scene.set_physics_process(false);current_scene.player.position=Vector3(0,0.18,0);current_scene._interact();await settle()
		check(current_scene.scene_file_path.ends_with("battle.tscn"),"Encounter UI "+str(stage))
		await win_battle()
		if stage<4:
			check(press_named(current_scene,"MAKE CAMP"),"Safe chamber camp")
		print("Flow cleared Hollow Oak "+str(stage))
	check(current_scene.scene_file_path.ends_with("game_menu.tscn"),"Recruitment screen")
	check(press_named(current_scene,"Lyra Vane · Ranger"),"Recruit button")
	await settle()
	check("ravenwood_0" in CampaignState.new().recruited,"Recruit saved")
	check(press_named(current_scene,"WORLD MAP"),"World map button")
	await settle();current_scene.select_territory("frostpeaks");current_scene._travel();await settle()
	check(current_scene.territory_id=="frostpeaks","Neighbor travel")
	current_scene.enter_exit("south");await settle()
	check(current_scene.scene_file_path.ends_with("settlement.tscn"),"Icehelm settlement")
	check(press_named(current_scene,"PROVISIONS & GEAR"),"Shop button")
	await settle();current_scene.list.select(0)
	var quantity:int=EquipmentState.new().quantities.potion
	check(press_named(current_scene,"BUY SELECTED"),"Buy button")
	check(EquipmentState.new().quantities.potion==quantity+1,"Purchased item persisted")
	check(press_named(current_scene,"BACK"),"Shop back")
	await settle();check(press_named(current_scene,"SMITHY"),"Smithy button")
	await settle();current_scene.show_item("frostpeaks_sword");current_scene._forge()
	check(current_scene.forging,"Forge started")
	var item:Dictionary=current_scene.state.catalog.items.frostpeaks_sword
	current_scene.strikes=3+(int(item.style.index)+str(item.family).length())%4;current_scene.strike_accuracy=0
	current_scene._finish_forge()
	check(current_scene.state.quantities.get("frostpeaks_sword_masterwork",0)>0,"Masterwork created")
	current_scene._equip_or_use();check(EquipmentState.new().equipped.weapon=="frostpeaks_sword_masterwork","Equip persisted")
	current_scene._back();await settle()
	check(current_scene.scene_file_path.ends_with("settlement.tscn"),"Smithy return")
	check(SaveSlots.save_slot(1)==OK,"Save slot")
	check(SaveSlots.save_slot(1)==OK,"Overwrite slot")
	var campaign:=CampaignState.new();var gold:=campaign.gold;campaign.gold=0;campaign.save()
	check(SaveSlots.load_slot(1)==OK,"Load slot");check(CampaignState.new().gold==gold,"Save restored campaign")
	print("Flow passed recruitment, travel, shop, forge, equip and save/load")
	campaign=CampaignState.new();campaign.recruited=[]
	for id in campaign.data.regions:
		if campaign.data.regions[id].hero_pair.is_empty():continue
		campaign.recruited.append(campaign.data.regions[id].hero_pair[0])
		if campaign.recruited.size()==9:break
	campaign.final_stage=2;campaign.final_used=campaign.recruited.slice(0,6);campaign.current="deep";campaign.visited.append("deep");campaign.save();campaign.rest(0)
	set_meta("campaign_region","deep");set_meta("campaign_room","d2")
	change_scene_to_file("res://scenes/campaign_area.tscn");await settle()
	current_scene.set_physics_process(false);current_scene.player.position=Vector3(0,0.18,0);current_scene._interact();await settle();await win_battle()
	check(current_scene.scene_file_path.ends_with("game_menu.tscn"),"Ending scene")
	check(CampaignState.new().ending_seen,"Ending displayed and saved")
	var finished:=current_scene
	current_scene=null
	finished.queue_free()
	if root.has_node("GameAudio"):root.get_node("GameAudio").queue_free()
	await settle()
	print("FLOW PASSED: actual scene callbacks through ending")
	quit()
