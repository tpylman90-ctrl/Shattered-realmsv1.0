extends Control
var campaign:=CampaignState.new()
var region_id: String
var column: VBoxContainer
var status: Label
var show_completed:=false

func _ready() -> void:
	region_id=str(get_tree().get_meta("campaign_region",campaign.current))
	if not campaign.data.regions.has(region_id):region_id=campaign.current
	var background:=ColorRect.new();background.color=Color("102522");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var title:=Label.new();title.text="REALM CHRONICLE";title.position=Vector2(30,20);title.add_theme_font_size_override("font_size",30);add_child(title)
	var back:=Button.new();back.text="RETURN";back.position=Vector2(1080,20);back.size=Vector2(170,55);back.pressed.connect(_back);add_child(back)
	var regions:=OptionButton.new();regions.position=Vector2(30,77);regions.size=Vector2(640,50);add_child(regions)
	for id in campaign.data.regions:
		if id in campaign.visited:
			regions.add_item(campaign.data.regions[id].name);regions.set_item_metadata(regions.item_count-1,id)
			if id==region_id:regions.select(regions.item_count-1)
	regions.item_selected.connect(func(index:int):region_id=str(regions.get_item_metadata(index));_populate())
	var completed:=CheckButton.new();completed.text="Completed";completed.position=Vector2(730,77);completed.size=Vector2(250,50);completed.toggled.connect(func(active:bool):show_completed=active;_populate());add_child(completed)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(30,140);scroll.size=Vector2(1220,550);add_child(scroll)
	column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",18);scroll.add_child(column)
	_populate()

func _text(text:String,size:int=21) -> Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.x=1160;label.add_theme_font_size_override("font_size",size);column.add_child(label);return label

func _button(text:String,callback:Callable) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size=Vector2(1160,55);button.pressed.connect(callback);column.add_child(button)

func _populate() -> void:
	for child in column.get_children():column.remove_child(child);child.queue_free()
	var region:Dictionary=campaign.data.regions[region_id]
	var count:=campaign.quest_count(region_id)
	_text(region.name+" · %d/%d missions complete · %d gold" % [count.x,count.y,campaign.gold],28)
	if campaign.quests.dialogue.has(region_id):
		var dialogue:Dictionary=campaign.quests.dialogue[region_id]
		_text(dialogue.after if region_id in campaign.cleared else dialogue.before)
		for i in range(region.hero_pair.size()):
			var hero:Dictionary=campaign.data.heroes[region.hero_pair[i]]
			_text(hero.name+": “"+str(dialogue.voices[i])+"”",19)
		if campaign.story_choices.has(region_id):_text("Your pledge: "+str(campaign.story_choices[region_id]).capitalize()+". The chosen supplies were added to your pack.",18)
	status=_text("Survey the gold-marked roadside sites with A / E. Rewards are claimed here; deliveries consume the listed materials.",18)
	if region_id=="ravenwood" and not campaign.is_done("ravenwood",101):
		_text("CAPTAIN’S BRIEFING · A wolf has broken through the fort’s palisade. The militia holds the yard; drive it back before following its trail into the woods.")
		_button("DEFEND BLACKTHORN · ALPHA WOLF",func():
			get_tree().set_meta("battle_request",{"region":"ravenwood","stage":101,"finale":false,"return_scene":"res://scenes/quests.tscn"})
			get_tree().set_meta("campaign_region","ravenwood");get_tree().change_scene_to_file("res://scenes/battle.tscn"))
	if region_id!="deep" and campaign.is_done(region_id,101 if region_id=="ravenwood" else 100):
		_button("ROAD PATROL · Repeatable supplies & EXP",func():
			get_tree().set_meta("campaign_region",region_id)
			get_tree().set_meta("battle_request",{"region":region_id,"stage":1000+int(campaign.patrols.get(region_id,0)),"finale":false})
			get_tree().change_scene_to_file("res://scenes/battle.tscn"))
	for id in campaign.quests.quests:
		var quest:Dictionary=campaign.quests.quests[id]
		if quest.region!=region_id:continue
		var state:=campaign.quest_status(id)
		if state=="completed" and not show_completed:continue
		_text(quest.title+" · "+state.to_upper(),24)
		_text(quest.conclusion if state=="completed" else quest.objective,20)
		if quest.goal.kind=="delivery":
			var inventory:=EquipmentState.new(campaign.equipment_path,campaign.path)
			_text("%s · %d/%d" % [inventory.catalog.items[quest.goal.item].name,int(inventory.quantities.get(quest.goal.item,0)),int(quest.goal.quantity)],18)
		if quest.goal.kind=="sites":
			for site in campaign.quests.sites.get(region_id,[]):
				_text(("✓ " if site.id in campaign.discoveries else "• ")+site.name+" · "+str(site.room).capitalize(),18)
		if state=="locked":
			var names:=PackedStringArray()
			for prerequisite in quest.requires:
				if not prerequisite in campaign.claimed_quests:names.append(campaign.quests.quests[prerequisite].title)
			_text("First complete: "+", ".join(names),18)
		if state=="ready":
			var inventory:=EquipmentState.new(campaign.equipment_path,campaign.path)
			var rewards:=PackedStringArray([str(quest.reward.gold)+" gold"])
			for item in quest.reward.items:rewards.append(str(quest.reward.items[item])+" × "+inventory.catalog.items[item].name)
			_text("Reward: "+", ".join(rewards),18)
			if quest.has("choices"):
				for option in quest.choices:
					var extras:=PackedStringArray()
					for item in option.items:extras.append(str(option.items[item])+" × "+inventory.catalog.items[item].name)
					_button(option.label+" · "+", ".join(extras),_claim.bind(id,str(option.id)))
			else:_button("COMPLETE · "+quest.title,_claim.bind(id,""))
		var separator:=HSeparator.new();column.add_child(separator)
	if region_id!="deep" and region_id in campaign.cleared:
		var recruited:=false
		for hero in region.hero_pair:
			if hero in campaign.recruited:recruited=true
		if not recruited:_button("CHOOSE YOUR COMPANION",func():get_tree().set_meta("game_menu_tab","recruit");get_tree().set_meta("recruit_region",region_id);get_tree().change_scene_to_file("res://scenes/game_menu.tscn"))

func _claim(id:String,choice:String) -> void:
	if campaign.claim_quest(id,choice):
		_populate();status.text=campaign.quests.quests[id].conclusion
	else:status.text="The objective is not ready. Check your supplies and earlier missions."

func _back() -> void:
	get_tree().change_scene_to_file(str(get_tree().get_meta("quest_return_scene","res://scenes/game_menu.tscn")))
