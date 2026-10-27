extends GutTest
const ROOT:="user://slot_recovery_test/"
func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	_clean()
func after_each() -> void:
	_clean()
func _clean() -> void:
	for name in DirAccess.get_files_at(ROOT):DirAccess.remove_absolute(ROOT+name)
func _write(name:String,text:String) -> void:
	var file:=FileAccess.open(ROOT+name,FileAccess.WRITE);file.store_string(text);file.close()
func test_corrupt_primary_recovers_previous_verified_snapshot() -> void:
	_write("campaign.cfg",'[campaign]\nlevel=2\ngold=40\n')
	assert_eq(SaveSlots.save_slot(1,ROOT),OK)
	_write("campaign.cfg",'[campaign]\nlevel=3\ngold=80\n')
	assert_eq(SaveSlots.save_slot(1,ROOT),OK)
	_write("slot1.json",'{"schema":2,"files":{"campaign.cfg":"tampered"}}')
	assert_eq(SaveSlots.load_slot(1,ROOT),OK)
	assert_true("level=2" in FileAccess.get_file_as_string(ROOT+"campaign.cfg"))
func test_invalid_slot_cannot_erase_current_progress_and_legacy_slots_migrate() -> void:
	var current:='[campaign]\nlevel=5\n'
	_write("campaign.cfg",current)
	_write("slot2.json",'{"schema":1,"files":{}}')
	assert_ne(SaveSlots.load_slot(2,ROOT),OK)
	assert_eq(FileAccess.get_file_as_string(ROOT+"campaign.cfg"),current)
	_write("slot2.json",JSON.stringify({"schema":1,"files":{"campaign.cfg":'[campaign]\nlevel=4\n'}}))
	assert_eq(SaveSlots.load_slot(2,ROOT),OK)
	assert_true("level=4" in FileAccess.get_file_as_string(ROOT+"campaign.cfg"))
	assert_eq(SaveSlots.save_slot(2,ROOT),OK)
	assert_eq(int(SaveSlots._read_snapshot(ROOT+"slot2.json").schema),2)
func test_checksum_rejects_modified_files_before_any_current_file_is_written() -> void:
	_write("campaign.cfg",'[campaign]\nlevel=2\n')
	assert_eq(SaveSlots.save_slot(3,ROOT),OK)
	var snapshot:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"slot3.json"))
	snapshot.files["campaign.cfg"]='[campaign]\nlevel=99\n'
	_write("slot3.json",JSON.stringify(snapshot))
	assert_ne(SaveSlots.load_slot(3,ROOT),OK)
	assert_true("level=2" in FileAccess.get_file_as_string(ROOT+"campaign.cfg"))
	assert_ne(SaveSlots.load_slot(0,ROOT),OK)
