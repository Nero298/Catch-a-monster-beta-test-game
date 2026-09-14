extends Node
## Data-driven loader: reads JSON from res://data/  (no long hard-coded dictionaries)

var monsters: Dictionary = {}
var skills: Dictionary = {}
var balls: Dictionary = {}
var items: Dictionary = {}
var islands: Dictionary = {}

const RANK_VALUES := {"E": 1, "D": 2, "C": 3, "B": 4, "A": 5, "S": 6, "SS": 7}

func _ready() -> void:
	_load_all_data()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[DataManager] Missing: " + path)
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var txt = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(txt) != OK:
		push_error("[DataManager] JSON parse error: " + path)
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}

func _load_all_data() -> void:
	monsters = _load_json("res://data/monsters.json")
	skills = _load_json("res://data/skills.json")
	balls = _load_json("res://data/balls.json")
	items = _load_json("res://data/items.json")
	islands = _load_json("res://data/islands.json")
	# Convert color arrays to Color
	for id in monsters:
		var c = monsters[id].get("color", [0.7, 0.7, 0.7])
		if c is Array and c.size() >= 3:
			monsters[id]["color"] = Color(c[0], c[1], c[2])
	for id in islands:
		var c = islands[id].get("bg_color", [0.2, 0.2, 0.25])
		if c is Array and c.size() >= 3:
			islands[id]["bg_color"] = Color(c[0], c[1], c[2])
	print("[DataManager] Loaded JSON: ", monsters.size(), " monsters, ", skills.size(), " skills, ", balls.size(), " balls")

func create_monster_instance(monster_id: String, level: int = 1) -> Dictionary:
	if not monsters.has(monster_id):
		push_error("Unknown monster: " + monster_id)
		return {}
	var base = monsters[monster_id]
	var instance = base.duplicate(true)
	instance["uid"] = _generate_uid()
	instance["level"] = level
	instance["exp"] = 0
	instance["exp_to_next"] = _exp_for_level(level)
	var mult = 1.0 + (level - 1) * 0.08
	instance["max_hp"] = int(base.base_hp * mult)
	instance["hp"] = instance["max_hp"]
	instance["atk"] = int(base.base_atk * mult)
	instance["def"] = int(base.base_def * mult)
	instance["spd"] = int(base.base_spd * mult)
	instance["skills"] = base.skills.duplicate()
	return instance

func _generate_uid() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi() % 100000)

func _exp_for_level(level: int) -> int:
	return int(50 * pow(level, 1.4))

func calc_catch_rate(monster: Dictionary, ball_id: String, hp_ratio: float) -> float:
	var base_catch = monster.get("catch_rate", 0.3)
	var ball_data = balls.get(ball_id, balls.get("basic", {}))
	var ball_mult = ball_data.get("base_rate", 1.0)
	var level_bonus = 1.0 + (GameManager.ball_levels.get(ball_id, 1) - 1) * 0.15
	var hp_factor = 1.5 - hp_ratio
	var rank_penalty = 1.0 / max(1.0, RANK_VALUES.get(monster.get("rank", "E"), 1) * 0.35)
	var rate = base_catch * ball_mult * level_bonus * hp_factor * rank_penalty
	return clampf(rate, 0.05, 0.95)

func get_skill(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})

func get_starters() -> Array:
	return ["chamander", "glazadon", "sproutusk"]

func get_sprite_path(monster_id: String) -> String:
	var m = monsters.get(monster_id, {})
	return m.get("sprite", "res://assets/sprites/monsters/slime.png")
