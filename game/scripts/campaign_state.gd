class_name CampaignState
extends RefCounted
const SAVE_PATH := "user://campaign.cfg"
var path := SAVE_PATH
var equipment_path := EquipmentState.SAVE_PATH
var data: Dictionary
var current := "ravenwood"
var visited: Array = ["ravenwood"]
var cleared: Array = []
var encounters: Array = []
var recruited: Array = []
var defenders: Array = []
var party: Array = []
var secured: Array = []
var disciplines:Array=["warrior","mage","ranger"]
var mastery: Dictionary = {}
var area_rooms: Dictionary = {}
var area_positions: Dictionary = {}
var level := 1
var xp := 0
var gold := 60
var final_stage := 0
var final_used: Array = []
var ending_seen := false
var army: Array = [{"name":"Blackthorn Militia","type":"infantry"},{"name":"Town Archers","type":"archer"}]

func _init(save_path: String = SAVE_PATH, inventory_path: String = EquipmentState.SAVE_PATH) -> void:
	path=save_path
	equipment_path=inventory_path
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
	var file := ConfigFile.new()
	if file.load(path)!=OK: return
	current=str(file.get_value("campaign","current","ravenwood"))
	if not data.regions.has(current): current="ravenwood"
	for key in ["visited","cleared","encounters","recruited","defenders","party","secured","final_used","army","disciplines"]:
		var value: Variant=file.get_value("campaign",key,get(key))
		if value is Array: set(key,value)
	var rooms: Variant=file.get_value("campaign","area_rooms",{})
	if rooms is Dictionary: area_rooms=rooms
	var positions: Variant=file.get_value("campaign","area_positions",{})
	if positions is Dictionary: area_positions=positions
	var learned: Variant=file.get_value("campaign","mastery",{})
	if learned is Dictionary: mastery=learned
	level=clampi(int(file.get_value("campaign","level",1)),1,99)
	xp=maxi(0,int(file.get_value("campaign","xp",0)))
	gold=maxi(0,int(file.get_value("campaign","gold",60)))
	final_stage=clampi(int(file.get_value("campaign","final_stage",0)),0,3)
	ending_seen=bool(file.get_value("campaign","ending_seen",false))

func save() -> Error:
	var file := ConfigFile.new()
	for key in ["current","visited","cleared","encounters","recruited","defenders","party","secured","mastery","area_rooms","area_positions","level","xp","gold","final_stage","final_used","ending_seen","army","disciplines"]:
		file.set_value("campaign",key,get(key))
	return file.save(path)

func can_travel(region: String) -> bool:
	if not data.regions.has(region): return false
	if region=="deep" and recruited.size()<9: return false
	if region in visited: return true
	for neighbor in data.regions[region].neighbors:
		if neighbor in visited: return true
	return false

func travel(region: String) -> bool:
	if not can_travel(region): return false
	current=region
	if not region in visited: visited.append(region)
	save()
	return true

func encounter_key(region: String, stage: int) -> String:
	return region+":"+str(stage)

func is_done(region: String, stage: int) -> bool:
	return encounter_key(region,stage) in encounters

func recruit(hero: String) -> bool:
	if not data.heroes.has(hero): return false
	var region: String=data.heroes[hero].region
	if not region in cleared: return false
	for candidate in data.regions[region].hero_pair:
		if candidate in recruited or candidate in defenders: return false
	recruited.append(hero)
	for candidate in data.regions[region].hero_pair:
		if candidate!=hero: defenders.append(candidate)
	if party.size()<3: party.append(hero)
	var inventory:=EquipmentState.new(equipment_path,path)
	inventory.claim_cache("recruit:"+hero,{"chest_"+hero:1})
	save()
	return true

func set_party(heroes: Array) -> bool:
	if heroes.size()>3: return false
	var found := {}
	for hero in heroes:
		if not hero in recruited or found.has(hero): return false
		found[hero]=true
	party=heroes.duplicate()
	save()
	return true

func battle_party(finale: bool) -> Array:
	if not finale: return party.duplicate()
	var result := []
	for hero in recruited:
		if not hero in final_used: result.append(hero)
		if result.size()==3: break
	return result

func reward(region: String, stage: int, family: String, boss: bool, finale: bool = false) -> Dictionary:
	if finale and (stage!=final_stage or recruited.size()<9 or battle_party(true).size()!=3): return {}
	var key := encounter_key(region,stage)
	if key in encounters: return {}
	encounters.append(key)
	var gain := 28+level*9+(40 if boss else 0)
	var coins := 25+level*8+(60 if boss else 0)
	xp+=gain
	gold+=coins
	while xp>=level*55 and level<99:
		xp-=level*55
		level+=1
	mastery[family]=int(mastery.get(family,0))+1
	var inventory := EquipmentState.new(equipment_path,path)
	inventory.claim_cache("battle:"+key,{"iron_ingot":3 if boss else 1,"seasoned_wood":2,"leather_strip":1})
	if boss and (not finale or stage==2) and not region in cleared: cleared.append(region)
	if finale:
		for hero in battle_party(true): final_used.append(hero)
		final_stage=mini(3,final_stage+1)
	sync_equipment()
	save()
	return {"xp":gain,"gold":coins,"level":level,"mastery":int(mastery[family])}

func rest(cost: int = 15) -> bool:
	if current in secured and cost>0:cost=mini(cost,10)
	if gold<cost: return false
	gold-=cost
	var inventory := EquipmentState.new(equipment_path,path)
	inventory.hp=inventory.max_hp
	inventory.mp=inventory.max_mp
	inventory.poisoned=false
	inventory.save()
	save()
	return true

func buy(id: String, quantity: int = 1) -> bool:
	var inventory := EquipmentState.new(equipment_path,path)
	if quantity<=0 or not inventory.catalog.items.has(id): return false
	var item: Dictionary=inventory.catalog.items[id]
	var cost:int=price(id,quantity)
	if item.get("kind","")=="weapon" and item.get("territory","")!="starter" and not item.get("territory","") in visited:return false
	if cost<=0 or gold<cost: return false
	gold-=cost
	inventory.quantities[id]=int(inventory.quantities.get(id,0))+quantity
	inventory.save()
	save()
	return true

func hire(kind: String) -> bool:
	if not kind in ["infantry","archer","mage"] or army.size()>=4 or gold<80: return false
	gold-=80
	army.append({"name":kind.capitalize()+" Company","type":kind})
	save()
	return true

func sync_equipment() -> void:
	var inventory:=EquipmentState.new(equipment_path,path)
	var target_hp:=100+(level-1)*16
	var target_mp:=40+(level-1)*3
	inventory.hp=mini(target_hp,inventory.hp+maxi(0,target_hp-inventory.max_hp))
	inventory.mp=mini(target_mp,inventory.mp+maxi(0,target_mp-inventory.max_mp))
	inventory.max_hp=target_hp;inventory.max_mp=target_mp;inventory.save()

func price(id: String,quantity: int = 1) -> int:
	var inventory:=EquipmentState.new(equipment_path,path)
	if not inventory.catalog.items.has(id):return 0
	var value:=int(inventory.catalog.items[id].get("price",0))*quantity
	return maxi(1,int(value*0.9)) if current in secured else value
