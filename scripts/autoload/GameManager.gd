extends Node
## Central game state manager

signal gold_changed(new_amount: int)
signal gems_changed(new_amount: int)
signal castle_hp_changed(current: int, max_hp: int)
signal game_over(won: bool)
signal monster_caught(monster_data: Dictionary)
signal wave_changed(wave: int)
signal inventory_changed

enum GameMode { NONE, DEFENSE, HUNT, DUNGEON }
enum GameState { MENU, STARTER_SELECT, PLAYING, PAUSED, RESULT, COLLECTION, SHOP }

var current_mode: GameMode = GameMode.NONE
var current_state: GameState = GameState.MENU
var gold: int = 150
var gems: int = 0
var castle_max_hp: int = 1000
var castle_hp: int = 1000
var current_wave: int = 0
var max_waves: int = 15
var difficulty: String = "Normal"  # Easy, Normal, Hard, Nightmare
var selected_island: String = "forest"
var auto_battle: bool = false
var player_team: Array = []  # Active monsters in battle (max 3)
var owned_monsters: Array = []  # All owned
var inventory: Dictionary = {}  # item_id -> count
var balls: Dictionary = {"basic": 15, "great": 3, "ultra": 0}
var ball_levels: Dictionary = {"basic": 1, "great": 1, "ultra": 1}
var player_name: String = "Trainer"
var has_chosen_starter: bool = false
# Settings
var show_damage_numbers: bool = true
var volume_bgm: float = 0.7
var volume_sfx: float = 0.9
# Hatch system
var hatching_egg: Dictionary = {}  # {item_id, start_time, duration}
var hatch_speed_boost: float = 1.0

func _ready() -> void:
	randomize()

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func add_gems(amount: int) -> void:
	gems += amount
	gems_changed.emit(gems)

func spend_gems(amount: int) -> bool:
	if gems >= amount:
		gems -= amount
		gems_changed.emit(gems)
		return true
	return false

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func damage_castle(amount: int) -> void:
	castle_hp = max(0, castle_hp - amount)
	castle_hp_changed.emit(castle_hp, castle_max_hp)
	if castle_hp <= 0:
		game_over.emit(false)

func heal_castle(amount: int) -> void:
	castle_hp = min(castle_max_hp, castle_hp + amount)
	castle_hp_changed.emit(castle_hp, castle_max_hp)

func recalculate_base_hp_from_team() -> void:
	## Base HP = sum of max_hp of monsters currently in the active team (max 3).
	var total := 0
	for m in player_team:
		if typeof(m) == TYPE_DICTIONARY:
			total += int(m.get("max_hp", m.get("hp", 100)))
	if total <= 0:
		total = 300  # fallback if team empty
	castle_max_hp = total
	castle_hp = total
	castle_hp_changed.emit(castle_hp, castle_max_hp)

func reset_castle() -> void:
	recalculate_base_hp_from_team()
	castle_hp_changed.emit(castle_hp, castle_max_hp)

func set_mode(mode: GameMode) -> void:
	current_mode = mode

func start_game() -> void:
	current_state = GameState.PLAYING
	current_wave = 0
	reset_castle()

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false

func add_owned_monster(data: Dictionary) -> void:
	owned_monsters.append(data.duplicate(true))
	monster_caught.emit(data)

func get_active_team() -> Array:
	return player_team

func set_team(team: Array) -> void:
	player_team.clear()
	for m in team:
		if player_team.size() >= 3:
			break
		player_team.append(m.duplicate(true))
	recalculate_base_hp_from_team()
	SaveManager.save_game()

func set_starter(monster_id: String) -> void:
	var starter = DataManager.create_monster_instance(monster_id, 5)
	if starter:
		owned_monsters.clear()
		owned_monsters.append(starter)
		player_team = [starter.duplicate(true)]
		has_chosen_starter = true
		recalculate_base_hp_from_team()
		SaveManager.save_game()

func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count
	inventory_changed.emit()

func use_item(item_id: String, count: int = 1) -> bool:
	if inventory.get(item_id, 0) >= count:
		inventory[item_id] -= count
		if inventory[item_id] <= 0:
			inventory.erase(item_id)
		inventory_changed.emit()
		return true
	return false

func get_ball_upgrade_cost(ball_id: String) -> int:
	var lvl = ball_levels.get(ball_id, 1)
	return 100 * lvl * lvl + 50

func upgrade_ball(ball_id: String) -> bool:
	var cost = get_ball_upgrade_cost(ball_id)
	if spend_gold(cost):
		ball_levels[ball_id] = ball_levels.get(ball_id, 1) + 1
		SaveManager.save_game()
		return true
	return false

func start_hatch(egg_id: String = "boss_egg") -> bool:
	if inventory.get(egg_id, 0) <= 0:
		return false
	if not hatching_egg.is_empty():
		return false  # already hatching
	use_item(egg_id, 1)
	hatching_egg = {
		"item_id": egg_id,
		"start_time": Time.get_unix_time_from_system(),
		"duration": 300.0  # 5 minutes base
	}
	SaveManager.save_game()
	return true

func get_hatch_progress() -> float:
	if hatching_egg.is_empty():
		return 0.0
	var elapsed = Time.get_unix_time_from_system() - hatching_egg.start_time
	var dur = hatching_egg.duration / max(0.1, hatch_speed_boost)
	return clampf(elapsed / dur, 0.0, 1.0)

func finish_hatch() -> Dictionary:
	if get_hatch_progress() < 1.0:
		return {}
	hatching_egg = {}
	# Give strong boss-derived monster
	var mon = DataManager.create_monster_instance("boss_inferno", 12)
	mon["name"] = "Hatchling Inferno"
	mon["rank"] = "A"
	add_owned_monster(mon)
	SaveManager.save_game()
	return mon

func speed_up_hatch() -> bool:
	if hatching_egg.is_empty():
		return false
	if use_item("premium_food", 1) or spend_gold(80):
		hatch_speed_boost = 5.0
		return true
	return false
