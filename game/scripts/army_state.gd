class_name ArmyState
extends RefCounted
var campaign: CampaignState
var region:="ravenwood"
var units: Array[Dictionary]=[]
var first_capture:=false
var outcome:=""
var log_text:="Select a company, then move or attack."
func setup(progress: CampaignState, place: String) -> void:
	campaign=progress;region=place
	units.append({"name":"Wayfarer","side":0,"type":"hero","cell":Vector2i(0,1),"hp":70+campaign.level*10,"attack":18+campaign.level*3,"ap":2})
	for i in range(campaign.army.size()):
		var company: Dictionary=campaign.army[i]
		var cell:=Vector2i(0,[0,2,3,3][i]) if i<3 else Vector2i(1,3)
		units.append({"name":company.name,"side":0,"type":company.type,"cell":cell,"hp":45+campaign.level*10,"attack":12+campaign.level*3,"ap":2})
	for i in range(3): units.append({"name":["Raider Guard","Enemy Archers","Rift Company"][i],"side":1,"type":"archer" if i==1 else "infantry","cell":Vector2i(5,i),"hp":35+campaign.level*10,"attack":10+campaign.level*2,"ap":2})
func unit_at(cell: Vector2i) -> int:
	for i in range(units.size()):
		if units[i].hp>0 and units[i].cell==cell: return i
	return -1
func distance(a: Vector2i,b: Vector2i) -> int:
	return absi(a.x-b.x)+absi(a.y-b.y)
func act(index: int, cell: Vector2i) -> bool:
	if not outcome.is_empty() or index<0 or index>=units.size(): return false
	var unit: Dictionary=units[index]
	if unit.side!=0 or unit.hp<=0 or unit.ap<=0: return false
	if cell.x<0 or cell.x>=6 or cell.y<0 or cell.y>=4: return false
	var target:=unit_at(cell)
	if target>=0:
		if units[target].side==0: return false
		var reach:=2 if unit.type=="archer" else 3 if unit.type=="mage" else 1
		if distance(unit.cell,cell)>reach: return false
		units[target].hp=maxi(0,units[target].hp-unit.attack);unit.ap=0;log_text=unit.name+" attacks "+units[target].name+"."
	else:
		if distance(unit.cell,cell)!=1 or cell in [Vector2i(2,1),Vector2i(3,2)]: return false
		unit.cell=cell;unit.ap-=1;log_text=unit.name+" advances."
	_check();return true
func end_turn() -> void:
	if not outcome.is_empty(): return
	for foe in units:
		if foe.side!=1 or foe.hp<=0: continue
		var target: Dictionary={}
		for ally in units:
			if ally.side==0 and ally.hp>0 and (target.is_empty() or distance(foe.cell,ally.cell)<distance(foe.cell,target.cell)): target=ally
		if target.is_empty(): break
		var reach:=2 if foe.type=="archer" else 1
		if distance(foe.cell,target.cell)>reach:
			var options:=[foe.cell+Vector2i(-1,0),foe.cell+Vector2i(1,0),foe.cell+Vector2i(0,-1),foe.cell+Vector2i(0,1)]
			for point in options:
				if point.x>=0 and point.x<6 and point.y>=0 and point.y<4 and unit_at(point)<0 and not point in [Vector2i(2,1),Vector2i(3,2)] and distance(point,target.cell)<distance(foe.cell,target.cell): foe.cell=point;break
		if distance(foe.cell,target.cell)<=reach: target.hp=maxi(0,target.hp-foe.attack)
	for unit in units:
		if unit.side==0: unit.ap=2
	log_text="Enemy companies have acted. Your companies regain their actions."
	_check()
func _check() -> void:
	var friendly:=0;var hostile:=0
	for unit in units:
		if unit.hp<=0: continue
		if unit.side==0: friendly+=1
		else: hostile+=1
	if hostile==0:
		outcome="victory"
		if not region in campaign.secured:
			first_capture=true;campaign.secured.append(region);campaign.gold+=100;campaign.save()
	elif friendly==0: outcome="defeat"
