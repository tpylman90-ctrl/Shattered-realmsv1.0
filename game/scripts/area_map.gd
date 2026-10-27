extends Control
signal closed
var registry: Dictionary
var points: Dictionary={}
var current:="forest"
var visited: Array=[]
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var index:=0
	for id in registry:
		points[id]=Vector2(220+(index%3)*390,200+(index/3)*170)
		var label:=Label.new();label.text=registry[id].name;label.position=points[id]-Vector2(150,30);label.size=Vector2(300,60);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(label);index+=1
	var heading:=Label.new();heading.text="AREA ROUTES · Travel on foot";heading.position=Vector2(40,35);heading.add_theme_font_size_override("font_size",30);add_child(heading)
	var button:=Button.new();button.text="CLOSE";button.position=Vector2(1100,30);button.size=Vector2(140,55);button.pressed.connect(func(): hide();closed.emit());add_child(button)
func open(id: String, explored: Array) -> void:
	current=id;visited=explored.duplicate();show();queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.025,0.06,0.05,0.98))
	for id in registry:
		for exit in registry[id].exits.values():
			if points.has(exit.to): draw_line(points[id],points[exit.to],Color("56725d"),3,true)
	for id in points:
		var style:=StyleBoxFlat.new();style.bg_color=Color("6b5b35") if id==current else Color("2b4939") if id in visited else Color("172e25");style.border_color=Color("d9c183");style.set_border_width_all(2);style.set_corner_radius_all(8);draw_style_box(style,Rect2(points[id]-Vector2(155,35),Vector2(310,70)))
