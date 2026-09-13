extends Control
## Collection: monsters, team (max 3) with slot swap, inventory, real-time hatch progress

@onready var list: ItemList = $VBox/MonsterList
@onready var info: Label = $VBox/InfoLabel
@onready var team_label: Label = $VBox/TeamLabel
@onready var inv_label: Label = $VBox/InvLabel
@onready var hatch_label: Label = $VBox/HatchLabel
@onready var hatch_bar: ProgressBar = $VBox/HatchBar

var selected_idx: int = -1

func _ready() -> void:
	_refresh()
	if list:
		list.item_selected.connect(_on_item_selected)
	set_process(true)

func _process(_delta: float) -> void:
	_update_hatch()

func _refresh() -> void:
	if list:
		list.clear()
		for m in GameManager.owned_monsters:
			var txt = "%s  Lv.%d  [%s]  HP%d ATK%d" % [
				m.get("name", "?"), m.get("level", 1), m.get("rank", "E"),
				m.get("max_hp", 0), m.get("atk", 0)
			]
			list.add_item(txt)
	_update_team_label()
	_update_inv()
	_update_hatch()

func _update_team_label() -> void:
	var names = []
	for i in range(GameManager.player_team.size()):
		var m = GameManager.player_team[i]
		names.append("[%d] %s" % [i + 1, m.get("name", "?")])
	if team_label:
		team_label.text = "Team (max 3): " + (", ".join(names) if names else "(empty)  — use Move Up/Down to reorder")

func _update_inv() -> void:
	var parts = []
	for k in GameManager.inventory:
		parts.append("%s x%d" % [k, GameManager.inventory[k]])
	for b in GameManager.balls:
		parts.append("%sBall x%d (Lv%d)" % [b, GameManager.balls[b], GameManager.ball_levels.get(b, 1)])
	if inv_label:
		inv_label.text = "Inventory: " + (", ".join(parts) if parts else "(empty)")

func _update_hatch() -> void:
	if not hatch_label:
		return
	if GameManager.hatching_egg.is_empty():
		var eggs = GameManager.inventory.get("boss_egg", 0)
		hatch_label.text = "Hatch: %d Boss Egg(s) available" % eggs
		if hatch_bar:
			hatch_bar.value = 0
			hatch_bar.visible = false
	else:
		var p = GameManager.get_hatch_progress()
		hatch_label.text = "Hatching... %.0f%%  (Finish when 100%%)" % (p * 100)
		if hatch_bar:
			hatch_bar.visible = true
			hatch_bar.max_value = 100
			hatch_bar.value = p * 100

func _on_item_selected(idx: int) -> void:
	selected_idx = idx
	if idx < 0 or idx >= GameManager.owned_monsters.size():
		return
	var m = GameManager.owned_monsters[idx]
	info.text = "%s\nRank %s | Lv.%d | EXP %d/%d\nHP %d  ATK %d  DEF %d  SPD %d\nSkills: %s" % [
		m.get("name", "?"), m.get("rank", "E"), m.get("level", 1),
		m.get("exp", 0), m.get("exp_to_next", 50),
		m.get("max_hp", 0), m.get("atk", 0), m.get("def", 0), m.get("spd", 0),
		", ".join(m.get("skills", []))
	]

func _on_add_to_team() -> void:
	if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
		return
	if GameManager.player_team.size() >= 3:
		info.text = "Team full (max 3)!"
		return
	var m = GameManager.owned_monsters[selected_idx]
	for t in GameManager.player_team:
		if t.get("uid") == m.get("uid"):
			info.text = "Already in team"
			return
	GameManager.player_team.append(m.duplicate(true))
	SaveManager.save_game()
	_update_team_label()
	AudioManager.play_sfx("button")

func _on_remove_from_team() -> void:
	if selected_idx < 0:
		return
	var m = GameManager.owned_monsters[selected_idx]
	for i in range(GameManager.player_team.size() - 1, -1, -1):
		if GameManager.player_team[i].get("uid") == m.get("uid"):
			GameManager.player_team.remove_at(i)
			break
	SaveManager.save_game()
	_update_team_label()

func _on_clear_team() -> void:
	GameManager.player_team.clear()
	SaveManager.save_game()
	_update_team_label()

func _on_move_up() -> void:
	_swap_team_slot(-1)

func _on_move_down() -> void:
	_swap_team_slot(1)

func _swap_team_slot(dir: int) -> void:
	## Reorder team slots (drag-drop alternative that works reliably on mobile)
	if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
		return
	var uid = GameManager.owned_monsters[selected_idx].get("uid")
	var team_idx = -1
	for i in range(GameManager.player_team.size()):
		if GameManager.player_team[i].get("uid") == uid:
			team_idx = i
			break
	if team_idx < 0:
		info.text = "Add to team first, then reorder"
		return
	var new_idx = team_idx + dir
	if new_idx < 0 or new_idx >= GameManager.player_team.size():
		return
	var tmp = GameManager.player_team[team_idx]
	GameManager.player_team[team_idx] = GameManager.player_team[new_idx]
	GameManager.player_team[new_idx] = tmp
	SaveManager.save_game()
	_update_team_label()
	AudioManager.play_sfx("button")

func _on_feed() -> void:
	if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
		return
	if not GameManager.use_item("meat", 1) and not GameManager.use_item("premium_food", 1):
		info.text = "No food! Buy at Shop."
		return
	var m = GameManager.owned_monsters[selected_idx]
	m["exp"] = m.get("exp", 0) + 40
	while m["exp"] >= m.get("exp_to_next", 50):
		m["exp"] -= m["exp_to_next"]
		m["level"] = m.get("level", 1) + 1
		m["exp_to_next"] = DataManager._exp_for_level(m["level"])
		m["max_hp"] = int(m["max_hp"] * 1.08)
		m["hp"] = m["max_hp"]
		m["atk"] = int(m["atk"] * 1.07)
		m["def"] = int(m["def"] * 1.06)
		m["spd"] = int(m["spd"] * 1.04)
		AudioManager.play_sfx("level_up")
	for t in GameManager.player_team:
		if t.get("uid") == m.get("uid"):
			for k in ["level", "exp", "max_hp", "hp", "atk", "def", "spd"]:
				t[k] = m[k]
	SaveManager.save_game()
	_refresh()
	_on_item_selected(selected_idx)

func _on_start_hatch() -> void:
	if GameManager.start_hatch("boss_egg"):
		info.text = "Started hatching Boss Egg"
		_update_hatch()
	else:
		info.text = "Need Boss Egg or already hatching"

func _on_finish_hatch() -> void:
	var mon = GameManager.finish_hatch()
	if mon:
		info.text = "Hatched: " + mon.get("name", "Boss!")
		AudioManager.play_sfx("level_up")
		_refresh()
	else:
		info.text = "Not ready yet"

func _on_speed_hatch() -> void:
	if GameManager.speed_up_hatch():
		info.text = "Hatch speed boosted!"
		_update_hatch()
	else:
		info.text = "Need Premium Food or 80 Gold"

func _on_back() -> void:
	SceneManager.go_mode_select()
