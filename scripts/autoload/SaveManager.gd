extends Node
## Local save system - saves to user://CatchAMonster_Data/ (persistent on device)

const SAVE_DIR := "user://CatchAMonster_Data/"
const SAVE_FILE := "player_save.json"
const BACKUP_FILE := "player_save_backup.json"
const SAVE_VERSION := 3


func _ready() -> void:
	_ensure_dir()
	load_game()


func _ensure_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("CatchAMonster_Data"):
			dir.make_dir("CatchAMonster_Data")
			print("[SaveManager] Created save directory: ", SAVE_DIR)


func save_game() -> bool:
	var data := {
		"version": SAVE_VERSION,
		"player_name": GameManager.player_name,
		"gold": GameManager.gold,
		"has_chosen_starter": GameManager.has_chosen_starter,
		"owned_monsters": GameManager.owned_monsters,
		"player_team": GameManager.player_team,
		"inventory": GameManager.inventory,
		"balls": GameManager.balls,
		"ball_levels": GameManager.ball_levels,
		"castle_max_hp": GameManager.castle_max_hp,
		"difficulty": GameManager.difficulty,
		"show_damage_numbers": GameManager.show_damage_numbers,
		"volume_bgm": GameManager.volume_bgm,
		"volume_sfx": GameManager.volume_sfx,
		"hatching_egg": GameManager.hatching_egg,
		"timestamp": Time.get_unix_time_from_system()
	}

	var json_str := JSON.stringify(data, "\t")
	var path := SAVE_DIR + SAVE_FILE
	var tmp_path := SAVE_DIR + SAVE_FILE + ".tmp"

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error(
			"[SaveManager] Failed to open temp save: "
			+ str(FileAccess.get_open_error())
		)
		return false

	file.store_string(json_str)
	file.close()

	if FileAccess.file_exists(path):
		var remove_error := DirAccess.remove_absolute(path)
		if remove_error != OK:
			push_error(
				"[SaveManager] Failed to remove old save: "
				+ str(remove_error)
			)
			return false

	var rename_error := DirAccess.rename_absolute(tmp_path, path)
	if rename_error != OK:
		push_error(
			"[SaveManager] Failed to commit save: "
			+ str(rename_error)
		)
		return false

	var backup := FileAccess.open(SAVE_DIR + BACKUP_FILE, FileAccess.WRITE)
	if backup:
		backup.store_string(json_str)
		backup.close()

	print("[SaveManager] Game saved to ", path)
	return true


func load_game() -> bool:
	var path := SAVE_DIR + SAVE_FILE

	if not FileAccess.file_exists(path):
		print("[SaveManager] No save found, starting fresh")
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Cannot open save file")
		return false

	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_str)

	if err != OK:
		push_error("[SaveManager] JSON parse error")
		return false

	var data = json.data

	if typeof(data) != TYPE_DICTIONARY:
		push_error("[SaveManager] Save data is not a dictionary")
		return false

	GameManager.player_name = data.get("player_name", "Trainer")
	GameManager.gold = data.get("gold", 150)
	GameManager.has_chosen_starter = data.get("has_chosen_starter", false)
	GameManager.owned_monsters = data.get("owned_monsters", [])
	GameManager.player_team = data.get("player_team", [])
	GameManager.inventory = data.get("inventory", {})
	GameManager.balls = data.get(
		"balls",
		{
			"basic": 15,
			"great": 3,
			"ultra": 0
		}
	)
	GameManager.ball_levels = data.get(
		"ball_levels",
		{
			"basic": 1,
			"great": 1,
			"ultra": 1
		}
	)
	GameManager.castle_max_hp = data.get("castle_max_hp", 1000)
	GameManager.difficulty = data.get("difficulty", "Normal")
	GameManager.show_damage_numbers = data.get("show_damage_numbers", true)
	GameManager.volume_bgm = data.get("volume_bgm", 0.7)
	GameManager.volume_sfx = data.get("volume_sfx", 0.9)
	GameManager.hatching_egg = data.get("hatching_egg", {})

	print(
		"[SaveManager] Game loaded successfully (v",
		data.get("version", 1),
		")"
	)

	return true


func delete_save() -> void:
	var dir := DirAccess.open(SAVE_DIR)

	if dir:
		dir.remove(SAVE_FILE)
		dir.remove(BACKUP_FILE)
		print("[SaveManager] Save deleted")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_DIR + SAVE_FILE)
