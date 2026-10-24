extends Control
var direction := Vector2.ZERO
var finger := -1
var knob := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	draw_circle(Vector2(90, 90), 76, Color(0.04, 0.07, 0.06, 0.58))
	draw_arc(Vector2(90, 90), 76, 0, TAU, 64, Color(0.7, 0.65, 0.45, 0.8), 2)
	draw_circle(Vector2(90, 90) + knob, 30, Color(0.6, 0.58, 0.42, 0.75))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and finger == -1 and local.distance_to(Vector2(90, 90)) < 90:
			finger = event.index
			_update(local)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			finger = -1
			_update(Vector2(90, 90))
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		_update(get_global_transform_with_canvas().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()

func _update(local: Vector2) -> void:
	knob = (local - Vector2(90, 90)).limit_length(55)
	direction = knob / 55
	queue_redraw()
