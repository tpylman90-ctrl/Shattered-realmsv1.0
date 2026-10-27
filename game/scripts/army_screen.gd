extends Control
var state:=ArmyState.new()
var campaign_override: CampaignState
var selected:=0
var labels: Array[Label]=[]
var status: Label
var detail: Label
func _ready() -> void:
	var campaign:=campaign_override if campaign_override!=null else CampaignState.new();state.setup(campaign,str(get_tree().get_meta("campaign_region",campaign.current)))
	_label("TACTICAL ARMY · "+campaign.data.regions[state.region].name,Vector2(30,20),30)
	status=_label("",Vector2(30,75),19)
	for y in range(4):
		for x in range(6):
			var label:=_label("",Vector2(40+x*145,145+y*115),15);label.size=Vector2(135,100);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;labels.append(label)
	detail=_label("",Vector2(940,170),18);detail.size=Vector2(300,300);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button("END TURN",Vector2(940,520),func():state.end_turn();_refresh())
	_button("RETURN",Vector2(940,600),func():get_tree().change_scene_to_file("res://scenes/settlement.tscn"))
	_refresh()
func _refresh() -> void:
	for y in range(4):
		for x in range(6):
			var id:=state.unit_at(Vector2i(x,y));labels[y*6+x].text="" if id<0 else state.units[id].name+"\nHP "+str(state.units[id].hp)+" · AP "+str(state.units[id].ap)
	status.text=state.log_text
	if not state.outcome.is_empty(): status.text=("TERRITORY SECURED · +100 gold · Local service discount" if state.first_capture else "TERRITORY DEFENDED") if state.outcome=="victory" else "The companies withdraw. Your roster is preserved."
	var unit: Dictionary=state.units[selected]
	detail.text=unit.name+"\n\nMove to adjacent empty squares.\nAttack enemies in range.\n\nRange: melee 1, archers 2,\nmages 3.\n\nTwo actions per turn.\nAttacking ends that company’s turn."
	queue_redraw()
func _gui_input(event: InputEvent) -> void:
	var point:=Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT: point=event.position
	elif event is InputEventScreenTouch and event.pressed: point=event.position
	else: return
	var cell:=Vector2i(floori((point.x-40)/145),floori((point.y-145)/115))
	if cell.x<0 or cell.x>=6 or cell.y<0 or cell.y>=4:return
	var unit:=state.unit_at(cell)
	if unit>=0 and state.units[unit].side==0:selected=unit
	else:state.act(selected,cell)
	_refresh()
func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("142c29"))
	for y in range(4):
		for x in range(6):
			var cell:=Vector2i(x,y);var color:=Color("3b5545") if (x+y)%2 else Color("314a3b")
			var id:=state.unit_at(cell)
			if id>=0:color=Color("365b79") if state.units[id].side==0 else Color("78473f")
			if cell in [Vector2i(2,1),Vector2i(3,2)]:color=Color("676452")
			draw_rect(Rect2(40+x*145,145+y*115,138,108),color)
			if id==selected:draw_rect(Rect2(40+x*145,145+y*115,138,108),Color("ead396"),false,3)
func _label(text: String,at: Vector2,size: int) -> Label:
	var label:=Label.new();label.text=text;label.position=at;label.add_theme_font_size_override("font_size",size);add_child(label);return label
func _button(text: String,at: Vector2,callback: Callable) -> void:
	var button:=Button.new();button.text=text;button.position=at;button.size=Vector2(300,60);button.pressed.connect(callback);add_child(button)
