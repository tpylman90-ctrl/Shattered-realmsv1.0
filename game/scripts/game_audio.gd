extends Node
var player:=AudioStreamPlayer.new()
var current:=""
var muted:=false
func _ready() -> void:
	add_child(player);player.volume_db=-25
	var config:=ConfigFile.new()
	if config.load("user://settings.cfg")==OK:muted=bool(config.get_value("audio","muted",false))
func _process(_delta: float) -> void:
	if get_tree().current_scene==null:return
	var scene:=get_tree().current_scene.scene_file_path
	var track:="battle" if "battle" in scene else "town" if "settlement" in scene or "ravenwood.tscn" in scene else "ending" if "game_menu" in scene and str(get_tree().get_meta("game_menu_tab",""))=="ending" else "explore"
	if track!=current:
		current=track;var stream:AudioStreamWAV=load("res://assets/audio/"+track+".wav");stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=int(stream.get_length()*stream.mix_rate);player.stream=stream;player.play()
	player.volume_db=-80 if muted else -25
func toggle() -> void:
	muted=not muted;var config:=ConfigFile.new();config.set_value("audio","muted",muted);config.save("user://settings.cfg")
