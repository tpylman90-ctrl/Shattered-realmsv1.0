extends "res://scripts/woodland.gd"
var campaign: CampaignState
var territory_id:="ravenwood"
var region_record: Dictionary
var baking:=false
var enemy_marker: Node3D
const PALETTES={"forest":["6c8050","806b44","68715d"],"snow":["d5e5e7","a5bac4","8a9ca7"],"mountain":["73766b","8b806a","7a8184"],"volcanic":["26282a","4a3e35","363a40"],"marsh":["3f5131","655c3a","4e5a47"],"coast":["b4ac78","c3ac76","8f9b91"],"plains":["8e9b52","a48a56","7e8d6e"],"ruins":["55545d","716b67","747c83"],"desert":["d4ae6d","d7ae67","ac885c"],"void":["302339","4c3457","4a4059"]}

func _ready() -> void:
	campaign=CampaignState.new()
	territory_id=str(get_tree().get_meta("campaign_region",campaign.current))
	if not campaign.data.regions.has(territory_id): territory_id="ravenwood"
	region_record=campaign.data.regions[territory_id]
	if not baking: campaign.travel(territory_id)
	var old_room:=str(campaign.area_rooms.get(territory_id,""))
	var old_position: Variant=campaign.area_positions.get(territory_id,null)
	save_enabled=false
	super._ready()
	if old_room==room_id and old_position is Vector3 and can_walk(old_position) and not baking:
		player.position=old_position
		_update_camera(true)
	for child in get_children():
		if child is CanvasLayer:
			for control in child.get_children():
				if control is Button and control.text=="RAVENWOOD MAP": control.text="AREA ROUTES"

func _room_registry() -> Dictionary:
	var rooms: Dictionary={}
	var chambers: Array=region_record.chambers
	rooms.forest={"title":region_record.name.to_upper()+" · "+str(region_record.roads[0]).to_upper(),"name":region_record.roads[0],"subtitle":region_record.hook,"length":22.0,"seed":region_record.seed,"theme":"regional","exits":{"north":{"to":"crossing","arrival":"south"},"south":{"to":"town" if not str(region_record.settlement).is_empty() else "world","arrival":""}}}
	rooms.crossing={"title":region_record.name.to_upper()+" · "+str(region_record.roads[1]).to_upper(),"name":region_record.roads[1],"subtitle":region_record.objective,"length":24.0,"seed":int(region_record.seed)+17,"theme":"regional","exits":{"north":{"to":"d0","arrival":"south"},"south":{"to":"forest","arrival":"north"}}}
	for i in range(chambers.size()):
		var key:="d"+str(i)
		rooms[key]={"title":str(region_record.dungeon).to_upper()+" · "+str(chambers[i]).to_upper(),"name":chambers[i],"subtitle":"Restore the anchor. Clear the chamber to open the way.","length":18.0,"seed":int(region_record.seed)+37+i*23,"theme":"dungeon","exits":{"south":{"to":("ravenwood_return" if territory_id=="ravenwood" else "crossing") if i==0 else "d"+str(i-1),"arrival":"north"},"north":{"to":"world" if i==chambers.size()-1 else "d"+str(i+1),"arrival":"south"}}}
	if territory_id=="ravenwood":
		rooms.erase("forest");rooms.erase("crossing")
	return rooms

func _initial_room() -> String:
	if territory_id=="deep": return "d"+str(mini(campaign.final_stage,2))
	var requested:=str(get_tree().get_meta("campaign_room",campaign.area_rooms.get(territory_id,"forest")))
	return requested if room_data.has(requested) else "d0" if territory_id=="ravenwood" else "forest"

func _make_territory_map() -> Control:
	var map=preload("res://scripts/area_map.gd").new();map.registry=room_data;return map

func _materials() -> void:
	super._materials()
	var palette: Array=PALETTES[region_record.biome]
	materials.ground.albedo_color=Color('#'+palette[0])
	materials.road.albedo_color=Color('#'+palette[1])
	materials.stone.albedo_color=Color('#'+palette[2])
	var roof:=StandardMaterial3D.new();roof.albedo_color=Color('#'+palette[1]).darkened(0.25);roof.roughness=0.9;materials.roof=roof
	var plaster:=StandardMaterial3D.new();plaster.albedo_color=Color("9a9b7e") if region_record.biome not in ["volcanic","void"] else Color("49454b");plaster.roughness=0.95;materials.plaster=plaster
	if region_record.biome=="snow": materials.moss.albedo_color=Color("d9e4dc")

	if region_record.biome=="snow":
		materials.ground.albedo_texture=null;materials.ground.albedo_color=Color("7895a5")
		materials.road.albedo_texture=null;materials.road.albedo_color=Color("536f81")
		materials.stone.albedo_texture=null;materials.stone.albedo_color=Color("8aa3b1")
	if region_record.biome in ["desert","coast"]:
		materials.ground.albedo_texture=load("res://assets/woodland/road.webp")
	if region_record.biome=="volcanic":
		materials.roof.albedo_color=Color("29272b");materials.stone.albedo_color=Color("29282c")

func load_room(id: String, spawn_z: float, arrival_side: String = "") -> void:
	super.load_room(id,spawn_z,arrival_side)
	if baking: return
	campaign.area_rooms[territory_id]=room_id
	campaign.area_positions[territory_id]=player.position
	campaign.save()
	if _chamber_index()>=0 or (room_id=="crossing" and territory_id!="deep"):
		var stage:=_chamber_index() if _chamber_index()>=0 else 100
		if not campaign.is_done(territory_id,stage):
			enemy_marker=MonsterModel.new();scenery.add_child(enemy_marker);enemy_marker.position=Vector3(path_x(-3),walk_height(-3),-3);enemy_marker.build(region_record.monster,Color("66765a"),stage==region_record.chambers.size()-1 or territory_id=="deep")

func _chamber_index() -> int:
	return int(room_id.substr(1)) if room_id.begins_with("d") else -1

func path_x(z: float) -> float:
	if room_data.has(room_id) and room_data[room_id].theme=="dungeon": return 0.0
	return sin(z*0.12)*1.4

func walk_height(_z: float) -> float:
	return 0.18

func ground_height(x: float,z: float) -> float:
	if room_data.has(room_id) and room_data[room_id].theme=="dungeon": return 0.18
	var distance:=absf(x-path_x(z))
	var side:=maxf(0,distance-3)
	var h:=0.18+side*0.09+sin(x*0.31+z*0.21)*sin(z*0.23)*minf(1.4,side*0.17)
	if region_record.biome=="volcanic" and absf(x+12)<2:return -0.6
	if region_record.biome=="coast" and x < -5: h=lerpf(h,-0.8,clampf((-x-5)/5.0,0,1))
	return h

func can_walk(point: Vector3) -> bool:
	if _chamber_index()>=0 and not campaign.is_done(territory_id,_chamber_index()) and point.z < -4.5: return false
	return super.can_walk(point)

func _terrain() -> void:
	if _chamber_index()<0:
		super._terrain();return
	_box(Vector3(0,-0.2,0),Vector3(15,0.75,46),"stone")
	for side in [-1,1]:
		for i in range(8):
			var z:=-21.0+i*6
			_box(Vector3(side*6,2,z),Vector3(1,4,1.1),"stone")
			_box(Vector3(side*6,4.2,z),Vector3(1.5,0.4,1.5),"stone")
			_lantern(Vector3(side*4.5,2.2,z))
		_box(Vector3(side*7,1.7,0),Vector3(0.7,3.8,46),"stone")
	for z in [-15.0,-3.0,9.0]:
		_box(Vector3(0,4.5,z),Vector3(13.5,0.55,0.9),"stone")
		for i in range(5): _rock(Vector3(rng.randf_range(4.5,6.5)*(-1 if i%2 else 1),0,z+rng.randf_range(-2,2)),Vector3(0.3,0.3,0.4))

func _vegetation() -> void:
	if _chamber_index()>=0: return
	var biome: String=region_record.biome
	if baking and get_tree().get_meta("bake_city",false):
		for i in range(18):
			var x:=rng.randf_range(-24,24);var z:=rng.randf_range(-43,-27)
			if biome in ["forest","marsh","plains"]:_tree(Vector3(x,ground_height(x,z),z),10)
			else:_rock(Vector3(x,ground_height(x,z),z),Vector3(3,4+rng.randf()*3,3))
		return
	if biome in ["forest","marsh","plains"]:
		super._vegetation()
		if biome=="plains":
			for i in range(130):
				var x:=5.0+(i%13)*0.42;var z:=-13.0+(i/13)*0.65;var y:=ground_height(x,z)
				_segment(Vector3(x,y,z),Vector3(x,y+0.7,z),0.014,"wood")
		return
	for i in range(65):
		var z:=rng.randf_range(-36,29);var x:=rng.randf_range(5.5,24)*(-1 if i%2 else 1)
		var p:=Vector3(x,ground_height(x,z),z)
		if biome=="snow":
			_segment(p,p+Vector3(0,6.5,0),0.18,"bark")
			for layer in range(4):
				var cone:=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=2.4-layer*0.45;cone.height=2.5;cone.radial_segments=16
				_queue("snow_canopy_"+str(layer),cone,"moss",Transform3D(Basis.IDENTITY,p+Vector3(0,2+layer*1.25,0)))
		elif biome in ["volcanic","void"]:
			if i%3==0:
				_segment(p,p+Vector3(0,5,0),0.18,"bark")
				_segment(p+Vector3(0,3,0),p+Vector3(1,4.5,0),0.07,"bark")
			else: _rock(p,Vector3(1.2,2.5+randf(),1.3))
		elif biome=="coast" or biome=="desert":
			if i%4==0:
				_segment(p,p+Vector3(0,5,0),0.17,"bark")
				for j in range(7): _card("leaf",p+Vector3(cos(j)*1.1,5,sin(j)*1.1),Vector3(PI*0.4,j,0),2.4)
		else: _rock(p,Vector3(2.5,3.0+rng.randf()*3,2.5))

func _gate() -> void:
	_landmark()

func _bridge() -> void:
	_landmark()

func _landmark() -> void:
	if _chamber_index()>=0: return
	if baking and get_tree().get_meta("bake_city",false): _settlement();return
	var biome: String=region_record.biome
	if biome in ["coast","marsh"]: _water_patch(Vector3(-13,-0.3,0),Vector2(23,38),false)
	if biome in ["volcanic","void"]:
		var glow:=StandardMaterial3D.new();glow.albedo_color=Color("cc542a") if biome=="volcanic" else Color("7e407f");glow.emission_enabled=true;glow.emission=glow.albedo_color;glow.emission_energy_multiplier=0.8;materials.fissure=glow
		_box(Vector3(-8,-0.15,-4),Vector3(6,0.12,24),"fissure")
	if biome in ["forest","marsh"]:
		_tree(Vector3(-7,ground_height(-7,-6),-6),14)
		for i in range(7): _rock(Vector3(-7+cos(i)*3,0.2,-6+sin(i)*3),Vector3(0.6,1.0,0.6))
	elif biome=="desert":
		for side in [-1,1]:
			_box(Vector3(side*4,2.0,-8),Vector3(1.1,4,1.1),"stone")
			_box(Vector3(side*4,4.2,-8),Vector3(1.6,0.4,1.6),"stone")
		_box(Vector3(0,4.7,-8),Vector3(9.0,0.7,1.3),"stone")
	else:
		for i in range(5): _box(Vector3(-5,0.5+i*0.7,-6),Vector3(1.6,0.65,1.4),"stone")
		_box(Vector3(-5,4.0,-6),Vector3(2.1,0.5,2.0),"stone")

func _settlement() -> void:
	var stone: bool=region_record.biome not in ["forest","marsh","coast"]
	for side in [-1,1]:
		for i in range(4):
			var p:=Vector3(side*(5.8+(i%2)*1.3),0,-13+i*7)
			p.y=ground_height(p.x,p.z)
			if region_record.biome=="marsh":
				for dx in [-1.7,1.7]:
					for dz in [-2.0,2.0]:_segment(p+Vector3(dx,0,dz),p+Vector3(dx,1.4,dz),0.16,"wood")
				p.y+=1.4
				_box(p,Vector3(5.2,0.2,5.7),"wood")
			_box(p+Vector3(0,1.5,0),Vector3(4.3,3,4.8),"stone" if stone else "plaster")
			if region_record.biome=="volcanic":
				_box(p+Vector3(0,3.3,0),Vector3(4.9,0.6,5.4),"roof")
				_box(p+Vector3(0,3.8,0),Vector3(3.7,0.4,4.4),"stone")
			else:
				var roof:=PrismMesh.new();roof.size=Vector3(5.2,2.0,5.7)
				_queue("house_roof",roof,"roof",Transform3D(Basis.IDENTITY,p+Vector3(0,4,0)))
			for offset in [-1.1,1.1]: _box(p+Vector3(offset,1.8,2.45),Vector3(0.65,0.85,0.08),"light")
			_box(p+Vector3(0,0.9,2.48),Vector3(0.9,1.8,0.12),"wood")
			for offset in [-2.0,2.0]: _box(p+Vector3(offset,1.5,2.5),Vector3(0.13,3,0.12),"wood")
	if region_record.biome=="marsh":
		for side in [-1,1]:
			for i in range(12):_segment(Vector3(side*(3+i*0.45),0,-21),Vector3(side*(3+i*0.45),3.2,-21),0.22,"bark")
		_box(Vector3(0,3.0,-21),Vector3(6.5,0.4,0.5),"wood")
	else:
		for side in [-1,1]:
			_box(Vector3(side*5.2,3.5,-21),Vector3(4,7,4),"stone")
			for i in range(4):_box(Vector3(side*5.2-1.5+i,7.2,-19),Vector3(0.6,0.8,0.8),"stone")
		_box(Vector3(0,5.5,-21),Vector3(7,1.4,2),"stone")
	if region_record.biome in ["volcanic","void"]:
		var lava:=StandardMaterial3D.new();lava.albedo_color=Color("b34b24");lava.emission_enabled=true;lava.emission=Color("db542a");materials.city_lava=lava
		_box(Vector3(-12,-0.1,0),Vector3(3,0.2,42),"city_lava")
	if region_record.biome=="coast":
		_water_patch(Vector3(-15,-0.3,0),Vector2(22,48),false)
		for i in range(6): _box(Vector3(-9,0.3,4+i),Vector3(9,0.2,0.9),"wood")
		for i in range(7): _box(Vector3(-12,0.5+i*0.8,-13),Vector3(2.7-i*0.1,0.8,2.7-i*0.1),"stone")
		_lantern(Vector3(-12,6.5,-13))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if territory_map.visible: return
	var stage:=_chamber_index() if _chamber_index()>=0 else 100
	if ((room_id=="crossing" and territory_id!="deep") or _chamber_index()>=0) and not campaign.is_done(territory_id,stage) and absf(player.position.z)<3:
		prompt.show();prompt.text="ENGAGE · "+(str(region_record.boss) if _chamber_index()==region_record.chambers.size()-1 or territory_id=="deep" else "CHAMBER GUARD")

func _interact() -> void:
	var stage:=_chamber_index() if _chamber_index()>=0 else 100
	if ((room_id=="crossing" and territory_id!="deep") or _chamber_index()>=0) and not campaign.is_done(territory_id,stage) and absf(player.position.z)<3:
		get_tree().set_meta("campaign_region",territory_id);get_tree().set_meta("campaign_room",room_id);get_tree().set_meta("battle_request",{"region":territory_id,"stage":stage,"finale":territory_id=="deep"});get_tree().change_scene_to_file("res://scenes/battle.tscn");return
	super._interact()

func enter_exit(side: String) -> void:
	if not room_data[room_id].exits.has(side): return
	if side=="north" and _chamber_index()>=0 and not campaign.is_done(territory_id,_chamber_index()): subtitle.text="Clear this chamber before moving deeper.";return
	var destination: String=room_data[room_id].exits[side].to
	if room_data.has(destination): super.enter_exit(side);return
	campaign.current=territory_id;campaign.save();get_tree().set_meta("campaign_region",territory_id)
	if destination=="ravenwood_return":
		get_tree().set_meta("woodland_entry","ruins");get_tree().change_scene_to_file("res://scenes/woodland.tscn")
	elif destination=="town": get_tree().change_scene_to_file("res://scenes/settlement.tscn")
	else: get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func persist_exploration(_path: String = EXPLORATION_SAVE) -> Error:
	if campaign!=null and is_instance_valid(player) and not baking:
		campaign.area_rooms[territory_id]=room_id
		campaign.area_positions[territory_id]=player.position
		return campaign.save()
	return OK

func current_cache() -> Dictionary:
	return {}

func _self_scene() -> String:
	return "res://scenes/campaign_area.tscn"

func _exit_text(destination: String) -> String:
	if destination=="town": return "ENTER "+str(region_record.settlement).to_upper()
	if destination=="ravenwood_return":return "BACK TO RAVENWOOD"
	return super._exit_text(destination)

func _lighting() -> void:
	super._lighting()
	var biome:String=region_record.biome
	var colors:Dictionary={"snow":["657f96","becfd8","9cacbf"],"volcanic":["33252b","8c6750","6b4d43"],"desert":["698a9a","d8c79e","b6a27a"],"coast":["58889f","bacfd5","8fb1bc"],"marsh":["4d625d","899d82","6d816d"],"ruins":["4b5369","9098ac","717f91"],"void":["1c1428","4c385b","4c3659"]}
	if not colors.has(biome):return
	var values:Array=colors[biome]
	for child in get_children():
		if child is WorldEnvironment:
			var settings:Environment=child.environment
			settings.fog_light_color=Color('#'+values[2])
			settings.ambient_light_color=Color('#'+values[1])
			var sky_material:ProceduralSkyMaterial=settings.sky.sky_material
			sky_material.sky_top_color=Color('#'+values[0]);sky_material.sky_horizon_color=Color('#'+values[1]);sky_material.ground_horizon_color=Color('#'+values[2])
		if child is DirectionalLight3D and biome in ["volcanic","void"]:
			child.light_color=Color("ffc693") if biome=="volcanic" else Color("bc9fd8")
