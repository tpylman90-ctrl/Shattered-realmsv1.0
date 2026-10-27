class_name BattleState
extends RefCounted
var campaign: CampaignState
var inventory: EquipmentState
var region := "ravenwood"
var stage := 0
var finale := false
var boss := false
var allies: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var waiting := -1
var outcome := ""
var log_text := "The encounter begins."
var reward: Dictionary = {}
var elapsed := 0.0

func setup(progress: CampaignState, place: String, chamber: int, final_battle: bool = false) -> void:
	campaign=progress
	campaign.sync_equipment()
	inventory=EquipmentState.new(campaign.equipment_path,campaign.path)
	region=place
	stage=chamber
	finale=final_battle
	var record: Dictionary=campaign.data.regions[region]
	boss=finale or stage==record.chambers.size()-1
	var stats:=inventory.stats()
	var level:=campaign.level
	allies=[{"id":"player","name":"Wayfarer","hp":maxi(1,inventory.hp),"max_hp":inventory.max_hp,"mp":inventory.mp,"max_mp":inventory.max_mp,"attack":int(stats.attack)+level*3,"magic":int(stats.magic)+level*3,"defense":int(stats.defense)+level,"atb":30.0,"guard":false,"poison":inventory.poisoned,"role":str(inventory.catalog.items[inventory.equipped.body].get("discipline","player"))}]
	for id in campaign.battle_party(finale):
		var hero: Dictionary=campaign.data.heroes[id]
		allies.append({"id":id,"name":hero.name,"hp":95+level*16,"max_hp":95+level*16,"mp":35,"max_mp":35,"attack":12+level*3,"magic":14+level*3 if hero.role in ["mage","healer"] else 6+level*2,"defense":6+level,"atb":10.0+allies.size()*5,"guard":false,"poison":false,"role":hero.role})
	var tutorial:=region=="ravenwood" and stage==101
	if tutorial:
		allies.append({"id":"fort_watch","name":"Blackthorn Watch","hp":95,"max_hp":95,"mp":24,"max_mp":24,"attack":15,"magic":6,"defense":9,"atb":20.0,"guard":false,"poison":false,"role":"guardian"})
		log_text="The watch joins you. Select Attack or Skill when ATB fills. Guard restores focus; the watch’s Skill wards the party."
	var count:=1 if boss or tutorial else 2
	for i in range(count):
		var hp:=100+level*28 if boss else 30+level*12
		if tutorial: hp=75+level*12
		if finale: hp=210+level*38+stage*70
		enemies.append({"name":"Blackthorn Alpha Wolf" if tutorial else record.boss if boss else record.name+" "+["Prowler","Sentinel"][i],"hp":hp,"max_hp":hp,"attack":9+level*3+(3 if boss else 0),"defense":2+level,"atb":0.0+i*20,"poison":false,"guard":false,"turns":0,"intent":"Strike"})

func tick(delta: float) -> void:
	if not outcome.is_empty() or waiting>=0: return
	elapsed+=delta
	for i in range(allies.size()):
		if allies[i].hp<=0: continue
		var pace:=1.0
		if i==0:
			var rates:Dictionary={"sword":1.1,"greatsword":0.85,"axe":0.9,"bow":1.05,"crossbow":0.9,"cannon":0.72,"scythe":0.85,"staff":0.95,"spear":1.0,"daggers":1.35}
			pace=float(rates[inventory.catalog.items[inventory.equipped.weapon].family])
		allies[i].atb=minf(100,float(allies[i].atb)+delta*(23+i*2)*pace)
		if allies[i].atb>=100:
			waiting=i
			return
	for foe in enemies:
		if foe.hp<=0: continue
		foe.atb=float(foe.atb)+delta*18
		if foe.atb>=100:
			foe.atb=0.0
			if foe.poison: foe.hp=maxi(0,foe.hp-maxi(2,int(foe.max_hp*0.04)))
			if foe.hp<=0: continue
			_enemy_action(foe)
	_check_end()

func act(command: String, target_index: int = 0) -> bool:
	if waiting<0 or not outcome.is_empty() or not command in ["attack","skill","guard","heal","potion","flee","learned","ether","antidote","revive"]: return false
	var ally: Dictionary=allies[waiting]
	if command=="flee":
		outcome="retreat"
		_persist_vitals()
		return true
	if command=="potion":
		if inventory.quantities.get("potion",0)<=0: return false
		var target: Dictionary=ally
		for unit in allies:
			if unit.hp>0 and float(unit.hp)/unit.max_hp<float(target.hp)/target.max_hp: target=unit
		if target.hp>=target.max_hp: return false
		target.hp=mini(target.max_hp,target.hp+50)
		inventory.quantities.potion-=1
		log_text=ally.name+" uses a potion on "+target.name+"."
	elif command in ["ether","antidote"]:
		if int(inventory.quantities.get(command,0))<=0:return false
		if command=="ether":
			if ally.mp>=ally.max_mp:return false
			ally.mp=mini(ally.max_mp,ally.mp+25)
		else:
			var found:=false
			for unit in allies:
				if unit.poison:unit.poison=false;found=true
			if not found:return false
		inventory.quantities[command]-=1
		log_text=ally.name+" uses "+command+"."
	elif command=="revive":
		if ally.mp<12 or not (ally.role=="healer" or (waiting==0 and "healer" in campaign.disciplines)):return false
		var fallen:Dictionary={}
		for unit in allies:
			if unit.hp<=0:fallen=unit;break
		if fallen.is_empty():return false
		ally.mp-=12;fallen.hp=maxi(1,int(fallen.max_hp*0.35));fallen.atb=0.0;fallen.poison=false
		log_text=ally.name+" revives "+fallen.name+"."
	elif command=="skill" and ally.role in ["guardian","healer"]:
		if ally.mp<6:return false
		ally.mp-=6
		for unit in allies:
			if unit.hp<=0:continue
			if ally.role=="guardian":unit.guard=true
			else:unit.hp=mini(unit.max_hp,unit.hp+18+int(ally.magic*0.6));unit.poison=false
		log_text=ally.name+(" raises a party ward." if ally.role=="guardian" else " restores and cleanses the party.")
	elif command=="guard":
		ally.guard=true
		ally.mp=mini(ally.max_mp,ally.mp+4)
		log_text=ally.name+" guards and regains focus."
	elif command=="heal":
		if ally.mp<8: return false
		var target: Dictionary=ally
		for unit in allies:
			if unit.hp>0 and float(unit.hp)/unit.max_hp<float(target.hp)/target.max_hp: target=unit
		ally.mp-=8
		target.hp=mini(target.max_hp,target.hp+30+int(ally.magic))
		log_text=ally.name+" restores "+target.name+"."
	else:
		if target_index<0 or target_index>=enemies.size() or enemies[target_index].hp<=0:
			target_index=-1
			for i in range(enemies.size()):
				if enemies[i].hp>0: target_index=i; break
		if target_index<0: _check_end(); return false
		var foe: Dictionary=enemies[target_index]
		var power: float=ally.attack
		if command=="learned":
			if waiting!=0 or ally.mp<5 or not campaign.mastery.values().any(func(value):return int(value)>=3):return false
			ally.mp-=5;power=maxf(ally.attack*1.8,ally.magic*1.7)
			if int(campaign.mastery.get("daggers",0))>=3:foe.poison=true
		if command=="skill":
			if ally.mp<6: return false
			ally.mp-=6
			power=maxf(ally.attack*1.6,ally.magic*1.8)
			if ally.role=="warrior":foe.defense=maxi(0,int(foe.defense)-2)
			if ally.role=="ranger" or inventory.catalog.items[inventory.equipped.weapon].family=="daggers": foe.poison=true
		var weapon:Dictionary=inventory.catalog.items[inventory.equipped.weapon]
		if waiting==0 and weapon.get("infused",false):
			var element:String=campaign.data.regions[weapon.territory].element
			var target_element:String=campaign.data.regions[region].element
			var strong:Dictionary={"fire":"ice","ice":"fire","lightning":"water","water":"fire","wind":"earth","earth":"lightning","light":"dark","dark":"light","poison":"earth","void":"none"}
			if str(strong.get(element,""))==target_element:power*=1.3
			elif element==target_element:power*=0.8
		var damage:=maxi(1,int(power-foe.defense*0.35))
		foe.hp=maxi(0,foe.hp-damage)
		log_text=ally.name+" deals "+str(damage)+" to "+foe.name+"."
		ally.guard=false
		if waiting==0 and inventory.break_fragile():
			ally.attack=int(inventory.stats().attack)+campaign.level*3
			log_text+=" The damaged weapon breaks!"
	ally.atb=0.0
	if ally.poison: ally.hp=maxi(1,ally.hp-maxi(2,int(ally.max_hp*0.03)))
	waiting=-1
	_check_end()
	return true

func _check_end() -> void:
	if not outcome.is_empty(): return
	var living_foes:=0
	var living_allies:=0
	for unit in enemies:
		if unit.hp>0: living_foes+=1
	for unit in allies:
		if unit.hp>0: living_allies+=1
	if living_foes==0:
		outcome="victory"
		_persist_vitals()
		reward=campaign.reward(region,stage,inventory.catalog.items[inventory.equipped.weapon].family,boss,finale)
	elif living_allies==0:
		outcome="defeat"
		_persist_vitals()

func _persist_vitals() -> void:
	inventory.hp=int(allies[0].hp)
	inventory.mp=int(allies[0].mp)
	inventory.poisoned=bool(allies[0].poison)
	inventory.save()

func _enemy_action(foe: Dictionary) -> void:
	var living:Array[Dictionary]=[]
	for ally in allies:
		if ally.hp>0:living.append(ally)
	if living.is_empty():return
	foe.turns=int(foe.get("turns",0))+1
	var biome:String=campaign.data.regions[region].biome
	var special:bool=boss and int(foe.turns)%3==0
	var target:Dictionary=living[0]
	for ally in living:
		if ally.hp<target.hp:target=ally
	var targets:Array=living if special and biome in ["snow","volcanic","mountain","plains","void"] else [target]
	var description:="strikes"
	if special:
		description={"forest":"unleashes a briar rend","snow":"releases Frostfall","volcanic":"erupts","mountain":"calls Thunderfall","plains":"sweeps the line","void":"breaks the horizon","marsh":"spreads rot","coast":"surges with the tide","ruins":"drains life","desert":"strikes from a mirage"}.get(biome,"strikes")
	var total:=0
	for victim in targets:
		var damage:=maxi(1,int(foe.attack*(0.85 if targets.size()>1 else 1.2 if special else 1.0)-victim.defense*0.35))
		if victim.guard:damage=maxi(1,damage/2)
		victim.hp=maxi(0,victim.hp-damage);total+=damage
		if special and biome in ["marsh","forest"] and not victim.guard:victim.poison=true
		victim.guard=false
	if special and biome in ["ruins","coast"]:foe.hp=mini(foe.max_hp,foe.hp+total/2)
	log_text=foe.name+" "+str(description)+" · "+str(total)+" damage"+(" across the party." if targets.size()>1 else ".")
	foe.intent="POWER ATTACK · Guard now" if boss and int(foe.turns)%3==2 else "Strike"
