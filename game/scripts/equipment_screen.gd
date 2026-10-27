extends Control
var state: EquipmentState
var selected := "starter_sword"
var item_ids: Array[String] = []
var list: ItemList
var details: Label
var status: Label
var equip_button: Button
var forge_button: Button
var territory: OptionButton
var family: OptionButton
var weapon: WeaponModel
var image: TextureRect
var preview: SubViewportContainer
var camera: Camera3D
var world: Node3D
var design_mode := false
var territory_ids: Array[String] = []
var family_ids: Array[String] = []
var dragging := false

func _ready() -> void:
	state=EquipmentState.new()
	var background := ColorRect.new()
	background.color=Color("102622")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_label("EQUIPMENT & SMITHY",Vector2(30,18),32)
	status=_label("",Vector2(32,63),19)
	var back := _button("BACK",Vector2(1110,22),Vector2(140,52),_back)
	back.tooltip_text="Return to exploration"
	_button("PACK",Vector2(32,105),Vector2(140,50),func(): design_mode=false; _refresh_list())
	_button("WEAPON DESIGNS",Vector2(185,105),Vector2(235,50),func(): design_mode=true; _refresh_list())
	territory=OptionButton.new()
	territory.position=Vector2(440,105)
	territory.size=Vector2(340,50)
	for id in state.catalog.territories:
		territory_ids.append(id)
		territory.add_item(state.catalog.territories[id].name)
	territory.item_selected.connect(func(_index): _select_design())
	add_child(territory)
	family=OptionButton.new()
	family.position=Vector2(795,105)
	family.size=Vector2(265,50)
	for id in state.catalog.families:
		family_ids.append(id)
		family.add_item(state.catalog.families[id])
	family.item_selected.connect(func(_index): _refresh_list())
	add_child(family)
	list=ItemList.new()
	list.position=Vector2(30,175)
	list.size=Vector2(390,500)
	list.fixed_icon_size=Vector2i(46,46)
	list.add_theme_font_size_override("font_size",19)
	list.item_selected.connect(func(index): show_item(item_ids[index]))
	add_child(list)
	preview=SubViewportContainer.new()
	preview.position=Vector2(440,175)
	preview.size=Vector2(385,430)
	preview.stretch=true
	add_child(preview)
	var viewport := SubViewport.new()
	viewport.size=Vector2i(385,430)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	preview.add_child(viewport)
	world=Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color("1c3330")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color("c3d1ce")
	settings.ambient_light_energy=0.7
	env.environment=settings
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-35,-25,0)
	sun.light_energy=1.6
	world.add_child(sun)
	camera=Camera3D.new()
	camera.position=Vector3(0,0.75,4.0)
	world.add_child(camera)
	camera.look_at(Vector3(0,0.75,0))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.0
	camera.current=true
	weapon=WeaponModel.new()
	world.add_child(weapon)
	image=TextureRect.new()
	image.position=Vector2(490,230)
	image.size=Vector2(280,280)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(image)
	details=_label("",Vector2(850,180),18)
	details.add_theme_constant_override("line_spacing",-2)
	details.size=Vector2(390,365)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	equip_button=_button("EQUIP",Vector2(850,560),Vector2(390,58),_equip_or_use)
	forge_button=_button("FORGE BASE WEAPON",Vector2(850,630),Vector2(390,58),_forge)
	_label("Drag the weapon to turn it • Base designs, not final upgrades",Vector2(440,610),15).size=Vector2(385,60)
	_refresh_list()

func _refresh_list() -> void:
	list.clear()
	item_ids.clear()
	territory.visible=design_mode
	family.visible=design_mode
	if design_mode:
		for id in state.catalog.territories:
			var key: String = id+"_"+family_ids[family.selected]
			item_ids.append(key)
			list.add_item(state.catalog.items[key].name,load(state.catalog.items[key].icon))
		_select_design()
	else:
		for id in state.quantities:
			if state.quantities[id]<=0: continue
			item_ids.append(id)
			list.add_item(state.catalog.items[id].name+" ×"+str(state.quantities[id]),load(state.catalog.items[id].icon))
		show_item(state.equipped.weapon)

func _select_design() -> void:
	show_item(territory_ids[territory.selected]+"_"+family_ids[family.selected])

func show_item(id: String) -> void:
	selected=id
	var item: Dictionary = state.catalog.items[id]
	var is_weapon: bool = item.kind=="weapon"
	preview.visible=is_weapon
	image.visible=not is_weapon
	if is_weapon:
		if design_mode and item.territory!="starter":
			territory.select(territory_ids.find(item.territory))
			family.select(family_ids.find(item.family))
		weapon.build(item)
		weapon.rotation=Vector3(0,-0.35,0)
		camera.size=3.3 if item.family in ["staff","scythe","spear"] else 2.9
		var focus := Vector3(-0.25 if item.family=="scythe" else 0.0,0.0 if item.family=="bow" else 0.75,0)
		camera.position=focus+Vector3(0,0,4)
		camera.look_at(focus)
	else: image.texture=load(item.icon)
	var text: String = item.name+"\n\n"+item.description
	if item.kind in ["weapon","gear"]:
		text+="\n\nATK %d   DEF %d   MAG %d" % [item.get("attack",0),item.get("defense",0),item.get("magic",0)]
		text+="\nSlot: "+str(item.get("slot",""))
	if is_weapon and not item.materials.is_empty():
		text+="\n\nRecipe:"
		for material in item.materials:
			text+="\n%s  %d / %d" % [state.catalog.items[material].name,state.quantities.get(material,0),item.materials[material]]
		if item.territory!="ravenwood": text+="\nDesign preview · territory not built yet"
	details.text=text
	equip_button.text="USE" if item.kind=="consumable" else "EQUIPPED" if id in state.equipped.values() else "EQUIP"
	equip_button.disabled=state.quantities.get(id,0)<=0 or (not item.has("slot") and item.kind!="consumable") or id in state.equipped.values()
	forge_button.visible=is_weapon and item.territory!="starter"
	forge_button.disabled=not state.can_forge(id)
	var stats := state.stats()
	status.text="HP %d / 100   MP %d / 40     ATK %d   DEF %d   MAG %d" % [state.hp,state.mp,stats.attack,stats.defense,stats.magic]

func _equip_or_use() -> void:
	if state.catalog.items[selected].kind=="consumable":
		if not state.use_item(selected): status.text="This item is not needed right now."; return
	else: state.equip(selected)
	var id := selected
	_refresh_list()
	show_item(id)

func _forge() -> void:
	var id := selected
	if state.forge(id):
		_refresh_list()
		show_item(id)
		status.text="Forged "+state.catalog.items[id].name+". It is now in your pack."

func _back() -> void:
	var destination := str(get_tree().get_meta("equipment_return_scene","res://scenes/main.tscn"))
	if get_tree().has_meta("equipment_return_scene"): get_tree().remove_meta("equipment_return_scene")
	get_tree().change_scene_to_file(destination)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		dragging=event.pressed and Rect2(preview.position,preview.size).has_point(event.position)
	if event is InputEventMouseMotion and dragging: weapon.rotation.y+=event.relative.x*0.012
	if event is InputEventScreenDrag and Rect2(preview.position,preview.size).has_point(event.position): weapon.rotation.y+=event.relative.x*0.012

func _label(text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text=text
	label.position=at
	label.add_theme_font_size_override("font_size",font_size)
	add_child(label)
	return label

func _button(text: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text=text
	button.position=at
	button.size=dimensions
	button.pressed.connect(callback)
	add_child(button)
	return button
