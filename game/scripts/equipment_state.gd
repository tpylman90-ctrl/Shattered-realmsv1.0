class_name EquipmentState
extends RefCounted
const SAVE_PATH := "user://equipment.cfg"
var catalog: Dictionary
var quantities: Dictionary = {}
var equipped := {"weapon":"starter_sword","body":"travel_tunic","feet":"travel_boots","offhand":"wooden_buckler","accessory":"copper_charm"}
var claimed: Array = []
var hp := 100
var mp := 40
var poisoned := false
var path := SAVE_PATH

func _init(save_path: String = SAVE_PATH) -> void:
	path=save_path
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment_catalog.json"))
	for family in catalog.families:
		quantities["starter_"+family]=1
	for item in ["travel_tunic","travel_boots","wooden_buckler","copper_charm"]:
		quantities[item]=1
	quantities.merge({"potion":3,"ether":2,"antidote":2,"iron_ingot":5,"seasoned_wood":5,"leather_strip":3})
	var config := ConfigFile.new()
	if config.load(path)==OK:
		var inventory: Variant = config.get_value("equipment","quantities",{})
		if inventory is Dictionary:
			quantities={}
			for id in inventory:
				if catalog.items.has(id): quantities[id]=maxi(0,int(inventory[id]))
		var slots: Variant = config.get_value("equipment","equipped",{})
		if slots is Dictionary:
			for slot in equipped:
				var id: String = str(slots.get(slot,equipped[slot]))
				if catalog.items.has(id) and catalog.items[id].get("slot","")==slot and quantities.get(id,0)>0:
					equipped[slot]=id
		hp=clampi(int(config.get_value("vitals","hp",100)),0,100)
		mp=clampi(int(config.get_value("vitals","mp",40)),0,40)
		poisoned=bool(config.get_value("vitals","poisoned",false))
		var caches: Variant = config.get_value("equipment","claimed",[])
		if caches is Array: claimed=caches

func save() -> Error:
	var config := ConfigFile.new()
	config.set_value("equipment","quantities",quantities)
	config.set_value("equipment","equipped",equipped)
	config.set_value("equipment","claimed",claimed)
	config.set_value("vitals","hp",hp)
	config.set_value("vitals","mp",mp)
	config.set_value("vitals","poisoned",poisoned)
	return config.save(path)

func equip(id: String) -> bool:
	if quantities.get(id,0)<=0 or not catalog.items.has(id) or not catalog.items[id].has("slot"): return false
	equipped[catalog.items[id].slot]=id
	save()
	return true

func stats() -> Dictionary:
	var result := {"attack":2,"defense":0,"magic":0}
	for id in equipped.values():
		for stat in result: result[stat]+=int(catalog.items[id].get(stat,0))
	return result

func can_forge(id: String) -> bool:
	if not catalog.items.has(id): return false
	var item: Dictionary = catalog.items[id]
	if item.get("territory","")!="ravenwood": return false
	return ForgeRecipe.can_craft(quantities,item.get("materials",{}))

func forge(id: String) -> bool:
	if not can_forge(id): return false
	for material in catalog.items[id].materials:
		quantities[material]-=int(catalog.items[id].materials[material])
	quantities[id]=int(quantities.get(id,0))+1
	save()
	return true

func claim_cache(id: String, rewards: Dictionary) -> bool:
	if id in claimed or rewards.is_empty(): return false
	for item in rewards:
		if not catalog.items.has(item) or int(rewards[item])<=0: return false
	for item in rewards: quantities[item]=int(quantities.get(item,0))+int(rewards[item])
	claimed.append(id)
	save()
	return true

func use_item(id: String) -> bool:
	if quantities.get(id,0)<=0: return false
	if id=="potion" and hp<100: hp=mini(100,hp+50)
	elif id=="ether" and mp<40: mp=mini(40,mp+20)
	elif id=="antidote" and poisoned: poisoned=false
	else: return false
	quantities[id]-=1
	save()
	return true
