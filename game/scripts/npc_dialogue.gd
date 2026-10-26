extends PanelContainer
signal closed

var speaker: Label
var body: Label
var choices: HBoxContainer
var record: Dictionary
var current_topic := -1

func _ready() -> void:
	position = Vector2(205, 410)
	size = Vector2(800, 255)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.045, 0.98)
	style.border_color = Color(0.63, 0.52, 0.29)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	add_child(content)
	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size", 24)
	speaker.add_theme_color_override("font_color", Color(0.95, 0.82, 0.51))
	content.add_child(speaker)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(750, 96)
	body.add_theme_font_size_override("font_size", 21)
	content.add_child(body)
	choices = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	content.add_child(choices)
	hide()

func open_npc(data: Dictionary) -> void:
	record = data
	current_topic = -1
	speaker.text = data.name + "  ·  " + data.role
	body.text = data.greeting
	for child in choices.get_children():
		child.free()
	for index in data.topics.size():
		var topic_index: int = index
		var button := Button.new()
		button.text = data.topics[index].label
		button.custom_minimum_size = Vector2(210, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): select_topic(topic_index))
		choices.add_child(button)
	var goodbye := Button.new()
	goodbye.text = "Goodbye"
	goodbye.custom_minimum_size = Vector2(150, 54)
	goodbye.pressed.connect(close_dialogue)
	choices.add_child(goodbye)
	show()
	move_to_front()
	choices.get_child(0).grab_focus()

func select_topic(index: int) -> void:
	if index < 0 or index >= record.topics.size():
		return
	current_topic = index
	body.text = record.topics[index].text

func close_dialogue() -> void:
	hide()
	closed.emit()
