extends Control
var campaign:=CampaignState.new()
var column: VBoxContainer
var message: Label
func _ready() -> void:
	var background:=ColorRect.new();background.color=Color("112923");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background)
	var back:=Button.new();back.text="WORLD MAP";back.position=Vector2(1060,22);back.size=Vector2(185,55);back.pressed.connect(func():get_tree().change_scene_to_file("res://scenes/world_map.tscn"));add_child(back)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(35,95);scroll.size=Vector2(1210,590);add_child(scroll)
	column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",14);scroll.add_child(column)
	var title:=Label.new();title.text="CHRONICLE & PARTY";title.position=Vector2(35,25);title.add_theme_font_size_override("font_size",32);add_child(title)
	var tab:=str(get_tree().get_meta("game_menu_tab","journal"))
	if tab=="recruit": _recruit(str(get_tree().get_meta("recruit_region",campaign.current)))
	elif tab=="ending": _ending()
	elif tab=="new": _new_game()
	else: _journal()
func _text(text: String,size: int = 20) -> Label:
	var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",size);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.x=1120;column.add_child(label);return label
func _button(text: String,callback: Callable) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size=Vector2(1120,52);button.pressed.connect(callback);column.add_child(button)
func _journal() -> void:
	_text("Level %d · EXP %d/%d · Gold %d\nCompanions %d/9 required · Restored anchors %d/18\n%s" % [campaign.level,campaign.xp,campaign.level*55,campaign.gold,campaign.recruited.size(),campaign.cleared.filter(func(id):return id!="deep").size(),"The Devouring Deep is sealed." if campaign.final_stage>=3 else "Restore the anchors and assemble nine companions for three final fronts."],23)
	_button("REGIONAL QUESTS & GUARDIAN STORIES",func():
		get_tree().set_meta("campaign_region",campaign.current);get_tree().set_meta("quest_return_scene","res://scenes/game_menu.tscn");get_tree().change_scene_to_file("res://scenes/quests.tscn"))
	_text("ACTIVE PARTY · Wayfarer + up to three companions",24)
	for id in campaign.recruited:
		var hero: Dictionary=campaign.data.heroes[id]
		_button(("✓ " if id in campaign.party else "+ ")+hero.name+" · "+hero.role,func():
			var selection: Array=campaign.party.duplicate()
			if id in selection:selection.erase(id)
			elif selection.size()<3:selection.append(id)
			campaign.set_party(selection);get_tree().reload_current_scene())
	_text("REGIONAL OBJECTIVES",24)
	for id in campaign.data.regions:
		var region: Dictionary=campaign.data.regions[id]
		if id in campaign.visited:
			_text(("✓ " if id in campaign.cleared else "• ")+region.name+" — "+region.objective,18)
			if id in campaign.cleared and not region.hero_pair.is_empty():
				var chosen:=false
				for hero in region.hero_pair:
					if hero in campaign.recruited:chosen=true
				if not chosen:_button("RECRUIT FROM "+region.name.to_upper(),func():get_tree().set_meta("game_menu_tab","recruit");get_tree().set_meta("recruit_region",id);get_tree().reload_current_scene())
	_text("DISCIPLINES · "+", ".join(campaign.disciplines),22)
	_text("Equip a recruited guardian’s Oath Chest to learn their discipline.",18)
	_text("WEAPON MASTERY",24)
	for family in campaign.mastery:_text(family.capitalize()+": "+str(campaign.mastery[family])+" AP · "+("Mastered" if campaign.mastery[family]>=3 else "Master at 3 victories"),18)
	_text("SAVE SLOTS & SETTINGS",24)
	message=_text("Autosaves occur on progression, travel and equipment changes.",18)
	for slot in range(1,4):
		_button("SAVE SLOT %d · %s" % [slot,SaveSlots.label(slot)],func():message.text="Saved." if SaveSlots.save_slot(slot)==OK else "Save failed.")
		_button("LOAD SLOT "+str(slot),func():
			if SaveSlots.load_slot(slot)==OK:get_tree().set_meta("game_menu_tab","journal");get_tree().change_scene_to_file("res://scenes/main.tscn")
			else:message.text="This slot is empty or unreadable.")
	_button("TOGGLE MUSIC",func():get_node("/root/GameAudio").toggle())
	if campaign.final_stage>=3:_button("VIEW ENDING",func():get_tree().set_meta("game_menu_tab","ending");get_tree().reload_current_scene())
	_button("MAIN MENU",func():get_tree().change_scene_to_file("res://scenes/main.tscn"))
func _recruit(region_id: String) -> void:
	var region: Dictionary=campaign.data.regions[region_id]
	_text(region.name+" · Anchor restored",30)
	_text("Choose one guardian to join your expedition. The other remains to defend their homeland. This choice is saved.",23)
	for id in region.hero_pair:
		var hero: Dictionary=campaign.data.heroes[id]
		_button(hero.name+" · "+hero.role.capitalize(),func():
			if campaign.recruit(id):get_tree().set_meta("game_menu_tab","journal");get_tree().reload_current_scene())
	_button("DECIDE LATER",func():get_tree().set_meta("game_menu_tab","journal");get_tree().reload_current_scene())
func _new_game() -> void:
	for paragraph in campaign.data.prologue:_text(paragraph,25)
	_text("Starting a new campaign replaces current autosaves. Manual save slots are preserved.",19)
	_button("BEGIN NEW CAMPAIGN",func():SaveSlots.new_campaign();get_tree().set_meta("game_menu_tab","journal");get_tree().change_scene_to_file("res://scenes/hero_select.tscn"))
func _ending() -> void:
	if campaign.final_stage<3:_text("The final anchor has not yet been restored.");return
	campaign.ending_seen=true;campaign.save()
	_text("THE SHATTERED REALMS · ENDURE",34)
	for paragraph in campaign.data.ending:_text(paragraph,25)
	_text("Campaign clear · Level %d · %d companions · %d anchors restored\nOriginal first-pass campaign, environments, equipment and music.\nThank you for exploring Shattered Realms." % [campaign.level,campaign.recruited.size(),campaign.cleared.size()],22)
	_button("CONTINUE EXPLORING",func():get_tree().change_scene_to_file("res://scenes/world_map.tscn"))
