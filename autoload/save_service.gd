extends Node

const SAVE_PATH := "user://savegame.json"

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for write: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(GameState.to_save_data(), "\t"))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open save file for read: %s" % SAVE_PATH)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is not a dictionary: %s" % SAVE_PATH)
		return false
	GameState.load_save_data(parsed)
	return true

func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK:
		push_error("Cannot delete save file: %s" % SAVE_PATH)
		return false
	return true
