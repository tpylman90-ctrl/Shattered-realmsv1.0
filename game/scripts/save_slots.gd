class_name SaveSlots
extends RefCounted
const FILES:=["campaign.cfg","equipment.cfg","hero.cfg","ravenwood_exploration.cfg"]
# A single slot is replaced atomically. Its previous valid version remains recoverable.
static func save_slot(slot: int, root: String = "user://") -> Error:
	if slot<1 or slot>3:return ERR_INVALID_PARAMETER
	var snapshot:={"schema":2,"timestamp":Time.get_datetime_string_from_system(),"files":{},"hashes":{}}
	for name in FILES:
		if FileAccess.file_exists(root+name):
			var contents:=FileAccess.get_file_as_string(root+name)
			snapshot.files[name]=contents;snapshot.hashes[name]=contents.sha256_text()
	if snapshot.files.is_empty():return ERR_FILE_NOT_FOUND
	var destination:=root+"slot"+str(slot)+".json"
	var file:=FileAccess.open(destination+".tmp",FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot));file.close()
	if not _read_snapshot(destination).is_empty():
		var backup_error:=DirAccess.copy_absolute(destination,destination+".bak")
		if backup_error!=OK:return backup_error
	return DirAccess.rename_absolute(destination+".tmp",destination)

static func _read_snapshot(source: String) -> Dictionary:
	if not FileAccess.file_exists(source):return {}
	var snapshot:Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
	if not snapshot is Dictionary or not int(snapshot.get("schema",0)) in [1,2] or not snapshot.get("files") is Dictionary or snapshot.files.is_empty():return {}
	for name in snapshot.files:
		if not name in FILES or not snapshot.files[name] is String:return {}
		if snapshot.schema==2:
			if not snapshot.get("hashes") is Dictionary or snapshot.hashes.get(name,"")!=str(snapshot.files[name]).sha256_text():return {}
		var config:=ConfigFile.new()
		if config.parse(snapshot.files[name])!=OK:return {}
		var section:String={"campaign.cfg":"campaign","equipment.cfg":"inventory","hero.cfg":"hero","ravenwood_exploration.cfg":"exploration"}[name]
		# Old snapshots use their actual config sections; reject structurally empty data.
		if config.get_sections().is_empty():return {}
		if name=="campaign.cfg" and not config.has_section(section):return {}
	return snapshot

static func load_slot(slot: int, root: String = "user://") -> Error:
	if slot<1 or slot>3:return ERR_INVALID_PARAMETER
	var source:=root+"slot"+str(slot)+".json"
	var snapshot:=_read_snapshot(source)
	if snapshot.is_empty():snapshot=_read_snapshot(source+".bak")
	if snapshot.is_empty():return ERR_FILE_CORRUPT if FileAccess.file_exists(source) else ERR_FILE_NOT_FOUND
	# Validate everything and stage every write before replacing any current file.
	var previous:={}
	for name in FILES:
		if FileAccess.file_exists(root+name):previous[name]=FileAccess.get_file_as_string(root+name)
		if snapshot.files.has(name):
			var file:=FileAccess.open(root+name+".restore",FileAccess.WRITE)
			if file==null:return FileAccess.get_open_error()
			file.store_string(snapshot.files[name]);file.close()
	for name in FILES:
		var error:=OK
		if snapshot.files.has(name):error=DirAccess.rename_absolute(root+name+".restore",root+name)
		elif FileAccess.file_exists(root+name):error=DirAccess.remove_absolute(root+name)
		if error!=OK:
			for original in FILES:
				if previous.has(original):
					var rollback:=FileAccess.open(root+original,FileAccess.WRITE)
					if rollback!=null:rollback.store_string(previous[original]);rollback.close()
				elif FileAccess.file_exists(root+original):DirAccess.remove_absolute(root+original)
			return error
	return OK

static func new_campaign() -> void:
	for name in FILES:
		if name=="hero.cfg":continue
		if FileAccess.file_exists("user://"+name):DirAccess.remove_absolute("user://"+name)

static func label(slot: int) -> String:
	var source:="user://slot"+str(slot)+".json"
	if not FileAccess.file_exists(source) and not FileAccess.file_exists(source+".bak"):return "Empty"
	var snapshot:=_read_snapshot(source)
	if not snapshot.is_empty():return str(snapshot.get("timestamp","Saved"))
	snapshot=_read_snapshot(source+".bak")
	return "Recovery available · "+str(snapshot.get("timestamp","Saved")) if not snapshot.is_empty() else "Unreadable"
