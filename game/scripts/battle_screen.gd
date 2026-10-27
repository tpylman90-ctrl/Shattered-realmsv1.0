extends Node3D
var state:=BattleState.new()
var campaign_override: CampaignState
var labels: Array[Label]=[]
var bars: Array[ProgressBar]=[]
var actors: Array[Node3D]=[]
var enemy_actors: Array[Node3D]=[]
var weapons: Array[Node3D]=[]
var commands: Array[Button]=[]
var log_label: Label
var result_panel: PanelContainer
var result_label: Label
var finish_button: Button
var displayed_result:=false
var target:=0
var canvas: CanvasLayer

func _ready() -> void:
	var campaign:=campaign_override if campaign_override!=null else CampaignState.new()
	var request: Dictionary=get_tree().get_meta("battle_request",{"region":campaign.current,"stage":0,"finale":false})
	state.setup(campaign,request.region,int(request.stage),bool(request.get("finale",false)))
	var background:=CanvasLayer.new();background.layer=-1;add_child(background)
	var image:=TextureRect.new();image.size=Vector2(1280,720);image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var path:="res://assets/battles/"+state.region+".webp"
	if ResourceLoader.exists(path): image.texture=load(path)
	else: image.modulate=Color("273a35")
	background.add_child(image)
	var env:=WorldEnvironment.new();var settings:=Environment.new();settings.background_mode=Environment.BG_CANVAS;settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("b5c5b7");settings.ambient_light_energy=0.7;env.environment=settings;add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-20,0);sun.light_energy=1.3;add_child(sun)
	var camera:=Camera3D.new();camera.position=Vector3(0,5.5,11);camera.fov=48;add_child(camera);camera.look_at(Vector3(0,0.7,0));camera.current=true
	for i in range(state.allies.size()):
		var actor:=Node3D.new();actor.position=Vector3(-3.6+(i%2)*1.1,0,(i/2)*1.7-1);add_child(actor)
		var hero=preload("res://scripts/hero_model.gd").new();actor.add_child(hero)
		var appearance: String=preload("res://scripts/hero_model.gd").selected() if i==0 else state.campaign.data.heroes[state.allies[i].id].appearance
		hero.setup(appearance,false);actor.rotation.y=PI*0.5;actors.append(actor)
		var held:=WeaponModel.new();actor.add_child(held)
		var family:="staff" if state.allies[i].role in ["mage","healer"] else "bow" if state.allies[i].role=="ranger" else "sword"
		held.build(state.inventory.catalog.items[state.inventory.equipped.weapon if i==0 else "starter_"+family])
		held.position=Vector3(0.35,0.72,0.1);held.scale=Vector3.ONE*0.6;held.rotation.z=-0.2;weapons.append(held)
	for i in range(state.enemies.size()):
		var foe:=MonsterModel.new();foe.position=Vector3(3.0,0,-0.8+i*2.4);add_child(foe)
		var colors:Dictionary={"forest":"657548","snow":"8ba9b8","mountain":"617b94","volcanic":"8e4435","marsh":"5c7140","coast":"4d8492","plains":"7d7954","ruins":"777385","desert":"b08b54","void":"694778"}
		foe.build(state.campaign.data.regions[state.region].monster,Color("#"+colors[state.campaign.data.regions[state.region].biome]),state.boss);enemy_actors.append(foe)
	_ui()
	_refresh()

func _ui() -> void:
	canvas=CanvasLayer.new();add_child(canvas)
	var top:=PanelContainer.new();top.position=Vector2(20,16);top.size=Vector2(1240,76);canvas.add_child(top)
	log_label=Label.new();log_label.add_theme_font_size_override("font_size",22);log_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;top.add_child(log_label)
	for i in range(state.allies.size()):
		var label:=Label.new();label.position=Vector2(30,495+i*45);label.add_theme_font_size_override("font_size",18);canvas.add_child(label);labels.append(label)
		var bar:=ProgressBar.new();bar.position=Vector2(340,500+i*45);bar.size=Vector2(180,20);bar.show_percentage=false;canvas.add_child(bar);bars.append(bar)
	var titles:=["Attack","Skill · 6 MP","Guard / Focus","Heal · 8 MP","Potion","Retreat","Mastered Art · 5 MP"]
	var actions:=["attack","skill","guard","heal","potion","flee","learned"]
	for i in range(actions.size()):
		var button:=Button.new();button.text=titles[i];button.position=Vector2(555+(i%3)*230,510+(i/3)*70);button.size=Vector2(215,58);button.pressed.connect(_act.bind(actions[i]));canvas.add_child(button);commands.append(button)
	for i in range(state.enemies.size()):
		var button:=Button.new();button.name="Target"+str(i);button.position=Vector2(865,115+i*55);button.size=Vector2(385,48);button.text=state.enemies[i].name;button.pressed.connect(func(): target=i;_refresh());canvas.add_child(button)
	result_panel=PanelContainer.new();result_panel.position=Vector2(280,145);result_panel.size=Vector2(720,350);canvas.add_child(result_panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",20);result_panel.add_child(column)
	result_label=Label.new();result_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result_label.custom_minimum_size=Vector2(680,210);result_label.add_theme_font_size_override("font_size",24);column.add_child(result_label)
	finish_button=Button.new();finish_button.custom_minimum_size=Vector2(680,58);finish_button.pressed.connect(_finish);column.add_child(finish_button);result_panel.hide()

func _process(delta: float) -> void:
	state.tick(delta)
	_refresh()

func _act(command: String) -> void:
	var actor_index:=state.waiting
	if state.act(command,target) and actor_index>=0 and actor_index<actors.size() and command in ["attack","skill","learned"]:
		var actor:=actors[actor_index];var origin:=actor.position
		var tween:=create_tween();tween.tween_property(actor,"position",origin+Vector3(0.55,0,0),0.13);tween.tween_property(actor,"position",origin,0.17)
		var swing:=create_tween();swing.tween_property(weapons[actor_index],"rotation:z",-1.2,0.13);swing.tween_property(weapons[actor_index],"rotation:z",-0.2,0.17)
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(log_label): return
	log_label.text=state.log_text
	if state.waiting>=0: log_label.text+="\nCommand: "+state.allies[state.waiting].name+" · ATB paused"
	for i in range(state.allies.size()):
		var unit: Dictionary=state.allies[i]
		labels[i].text="%s\nHP %d/%d   MP %d" % [unit.name,unit.hp,unit.max_hp,unit.mp]
		bars[i].value=float(unit.atb)
		actors[i].visible=unit.hp>0
	for i in range(state.enemies.size()):
		var foe: Dictionary=state.enemies[i]
		enemy_actors[i].visible=foe.hp>0
		var button: Button=canvas.get_node("Target"+str(i))
		button.text=("▶ " if target==i else "")+foe.name+" · "+str(foe.hp)+" HP"
		button.disabled=foe.hp<=0
	for button in commands: button.disabled=state.waiting<0 or not state.outcome.is_empty()
	if not state.outcome.is_empty() and not displayed_result:
		displayed_result=true
		result_panel.show()
		if state.outcome=="victory":
			result_label.text="VICTORY\n\n"+("EXP +%d   Gold +%d\nLevel %d\nMaterials added to your pack.\nWeapon mastery +1" % [state.reward.xp,state.reward.gold,state.reward.level] if not state.reward.is_empty() else "This encounter has already been cleared.")
			finish_button.text="CONTINUE"
		elif state.outcome=="defeat":
			result_label.text="The expedition falls back.\n\nYour equipment and completed objectives are safe.\nRetry restores health and costs up to 10 gold."
			finish_button.text="RECOVER & RETRY"
		else:
			result_label.text="You retreat to the approach.\n\nNo rewards were granted."
			finish_button.text="RETURN TO EXPLORATION"

func _finish() -> void:
	if state.outcome=="defeat":
		state.campaign.gold=maxi(0,state.campaign.gold-10);state.campaign.save();state.inventory.hp=state.inventory.max_hp;state.inventory.mp=state.inventory.max_mp;state.inventory.poisoned=false;state.inventory.save()
		get_tree().reload_current_scene();return
	if state.finale and state.campaign.final_stage>=3:
		get_tree().set_meta("game_menu_tab","ending");get_tree().change_scene_to_file("res://scenes/game_menu.tscn");return
	if state.outcome=="victory" and state.boss and not state.finale:
		get_tree().set_meta("game_menu_tab","recruit");get_tree().set_meta("recruit_region",state.region);get_tree().change_scene_to_file("res://scenes/game_menu.tscn");return
	get_tree().change_scene_to_file("res://scenes/campaign_area.tscn")
