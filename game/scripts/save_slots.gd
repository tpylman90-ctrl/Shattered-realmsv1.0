class_name SaveSlots
extends RefCounted
const FILES:=["campaign.cfg","equipment.cfg","hero.cfg","ravenwood_exploration.cfg"]
static func save_slot(slot: int) -> Error:
	if slot<1 or slot>3: return ERR_INVALID_PARAMETER
	var snapshot:={"schema":1,"timestamp":Time.get_datetime_string_from_system(),"files":{}}
	for name in FILES:
		if FileAccess.file_exists("user://"+name): snapshot.files[name]=FileAccess.get_file_as_string("user://"+name)
	var file:=FileAccess.open("user://slot"+str(slot)+".json.tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot));file.close()
	return DirAccess.rename_absolute("user://slot"+str(slot)+".json.tmp","user://slot"+str(slot)+".json")
static func load_slot(slot: int) -> Error:
	var source:="user://slot"+str(slot)+".json"
	if not FileAccess.file_exists(source): return ERR_FILE_NOT_FOUND
	var snapshot: Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
	if not snapshot is Dictionary or snapshot.get("schema",0)!=1 or not snapshot.get("files") is Dictionary: return ERR_FILE_CORRUPT
	for name in snapshot.files:
		if not name in FILES or not snapshot.files[name] is String: return ERR_FILE_CORRUPT
	for name in FILES:
		if snapshot.files.has(name):
			var file:=FileAccess.open("user://"+name,FileAccess.WRITE)
			if file==null: return FileAccess.get_open_error()
			file.store_string(snapshot.files[name]);file.close()
		elif FileAccess.file_exists("user://"+name): DirAccess.remove_absolute("user://"+name)
	return OK
static func new_campaign() -> void:
	for name in FILES:
		if name=="hero.cfg": continue
		if FileAccess.file_exists("user://"+name): DirAccess.remove_absolute("user://"+name)
static func label(slot: int) -> String:
	var source:="user://slot"+str(slot)+".json"
	if not FileAccess.file_exists(source): return "Empty"
	var snapshot: Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
	return str(snapshot.get("timestamp","Saved")) if snapshot is Dictionary else "Unreadable"
