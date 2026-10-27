extends Control
var campaign:=CampaignState.new()
var region: Dictionary
var status: Label
var column: VBoxContainer
var list: ItemList
var offers: Array[String]=[]
func _ready() -> void:
	var id:=str(get_tree().get_meta("campaign_region",campaign.current))
	region=campaign.data.regions[id]
	campaign.current=id;campaign.save()
	var texture:=TextureRect.new();texture.size=Vector2(1280,720);texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var path:="res://assets/cities/"+id+".webp"
	if id=="ravenwood": path="res://assets/ravenwood/gate.webp"
	if ResourceLoader.exists(path): texture.texture=load(path)
	add_child(texture)
	var shade:=ColorRect.new();shade.color=Color(0.02,0.04,0.035,0.2);shade.size=Vector2(1280,720);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(730,20);panel.size=Vector2(520,680);add_child(panel)
	column=VBoxContainer.new();column.add_theme_constant_override("separation",12);var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(510,665);panel.add_child(scroll);scroll.add_child(column)
	var title:=Label.new();title.text=region.settlement if not str(region.settlement).is_empty() else region.name+" · Trail Respite";title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.custom_minimum_size.x=480;title.add_theme_font_size_override("font_size",30);column.add_child(title)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size=Vector2(480,90);column.add_child(status)
	_refresh()
	if not str(region.settlement).is_empty():
		_button("INN · Rest "+str(10 if campaign.current in campaign.secured else 15)+" gold",func(): status.text="Rested. Health and focus restored." if campaign.rest(15) else "Not enough gold.";_refresh())
		_button("PROVISIONS & GEAR",_shop)
		_button("SMITHY",func(): get_tree().set_meta("equipment_return_scene","res://scenes/settlement.tscn");get_tree().change_scene_to_file("res://scenes/equipment.tscn"))
		var company:=OptionButton.new();company.custom_minimum_size=Vector2(480,42)
		for label in ["Infantry Company","Archer Company","Mage Company"]:company.add_item(label)
		column.add_child(company)
		_button("RECRUIT COMPANY · 80 gold",func():status.text="Company recruited." if campaign.hire(["infantry","archer","mage"][company.selected]) else "Need 80 gold and room for a company.";_refresh())
	else:
		_button("REST ON THE TRAIL",func(): campaign.rest(0);status.text="The expedition rests.";_refresh())
	_button("SECURE / DEFEND TERRITORY",func(): get_tree().set_meta("campaign_region",region.id);get_tree().change_scene_to_file("res://scenes/army_battle.tscn"))
	_button("LOCAL QUESTS & GUARDIANS",func():get_tree().set_meta("campaign_region",region.id);get_tree().set_meta("quest_return_scene","res://scenes/settlement.tscn");get_tree().change_scene_to_file("res://scenes/quests.tscn"))
	_button("JOURNAL & COMPANIONS",func(): get_tree().set_meta("game_menu_tab","journal");get_tree().change_scene_to_file("res://scenes/game_menu.tscn"))
	_button("LEAVE",_leave)

func _refresh() -> void:
	var inventory:=EquipmentState.new()
	status.text="Gold %d · Level %d\nHP %d / %d · MP %d / %d\n%s" % [campaign.gold,campaign.level,inventory.hp,inventory.max_hp,inventory.mp,inventory.max_mp,region.objective]

func _shop() -> void:
	for child in column.get_children(): child.queue_free()
	var heading:=Label.new();heading.text="PROVISIONS · Gold "+str(campaign.gold);heading.add_theme_font_size_override("font_size",26);column.add_child(heading)
	list=ItemList.new();list.custom_minimum_size=Vector2(480,390);list.fixed_icon_size=Vector2i(42,42);column.add_child(list)
	var inventory:=EquipmentState.new()
	offers.assign(["potion","ether","antidote","padded_coat","iron_guard","trail_boots","focus_charm","iron_ingot","seasoned_wood","leather_strip"])
	for id in offers: list.add_item(inventory.catalog.items[id].name+" · "+str(campaign.price(id))+" gold",load(inventory.catalog.items[id].icon))
	var message:=Label.new();message.text="Select an item to buy.";column.add_child(message)
	_button("BUY SELECTED",func():
		if list.get_selected_items().is_empty(): return
		var id:=offers[list.get_selected_items()[0]]
		message.text="Purchased "+inventory.catalog.items[id].name if campaign.buy(id) else "Not enough gold."
		heading.text="PROVISIONS · Gold "+str(campaign.gold))
	_button("BACK",func(): get_tree().reload_current_scene())

func _leave() -> void:
	if region.id=="ravenwood": get_tree().change_scene_to_file("res://scenes/ravenwood.tscn")
	else:
		get_tree().set_meta("campaign_room","forest");get_tree().change_scene_to_file("res://scenes/campaign_area.tscn")

func _button(text: String, callback: Callable) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size=Vector2(480,52);button.pressed.connect(callback);column.add_child(button)
