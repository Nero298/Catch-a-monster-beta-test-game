extends Node2D
## Main combat controller - horizontal defense + hunt/dungeon
## Player units fixed on LEFT in 1-3 slots. Enemies spawn from RIGHT. Smart auto-battle.

signal wave_cleared(wave: int)
signal combat_ended(won: bool)

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var castle: Area2D = $Castle
@onready var units_container: Node2D = $Units
@onready var hud: CanvasLayer = $HUD
@onready var catch_ui: Control = $HUD/CatchUI

var current_enemies: Array[Unit] = []
var player_units: Array[Unit] = []
var wave_timer: float = 0.0
var spawn_interval: float = 3.0
var enemies_to_spawn: int = 0
var enemies_spawned: int = 0
var is_spawning: bool = false
var is_boss_wave: bool = false
var target_for_catch: Dictionary = {}  # store data only after death
var unit_scene: PackedScene
var selected_unit_idx: int = 0  # which player unit receives manual skill
var gold_earned_this_run: int = 0
var monsters_caught_this_run: Array = []
var wave_transitioning: bool = false

# Slot Y offsets for 1-3 player units (relative to player_spawn)
const SLOT_OFFSETS := [0.0, -75.0, 75.0]

func _ready() -> void:
	unit_scene = preload("res://scenes/combat/Unit.tscn")
	_configure_playfield()
	GameManager.start_game()
	gold_earned_this_run = 0
	monsters_caught_this_run.clear()
	_setup_player_team()
	_connect_hud()
	if GameManager.current_mode == GameManager.GameMode.DUNGEON:
		GameManager.max_waves = 15
	elif GameManager.current_mode == GameManager.GameMode.HUNT:
		GameManager.max_waves = 8
	else:
		GameManager.max_waves = 10
	_start_next_wave()
	GameManager.game_over.connect(_on_game_over)
	GameManager.castle_hp_changed.connect(_on_castle_hp)
	GameManager.gold_changed.connect(_on_gold_changed)
	if castle and not castle.body_entered.is_connected(_on_castle_body_entered):
		castle.body_entered.connect(_on_castle_body_entered)
	AudioManager.play_bgm("combat")

func _configure_playfield() -> void:
	var view := get_viewport_rect().size
	if view.x <= 10 or view.y <= 10:
		view = Vector2(1280, 720)
	spawn_point.position = Vector2(view.x - 100.0, view.y * 0.55)
	player_spawn.position = Vector2(max(150.0, view.x * 0.22), view.y * 0.55)
	castle.position = Vector2(56.0, view.y * 0.55)
	var bg := get_node_or_null("BG") as Control
	if bg:
		bg.position = Vector2.ZERO
		bg.size = view
	var shade := get_node_or_null("Shade") as Control
	if shade:
		shade.position = Vector2.ZERO
		shade.size = view
	var ground := get_node_or_null("Ground") as Control
	if ground:
		ground.position = Vector2(0, view.y * 0.73)
		ground.size = Vector2(view.x, view.y * 0.27)
	# HUD spans the real viewport; this removes the dead dark strip on wide phones.
	var top_bar := hud.get_node_or_null("TopBar") as Control
	if top_bar:
		top_bar.position = Vector2.ZERO
		top_bar.size = Vector2(view.x, 76.0)
		var wave := top_bar.get_node_or_null("WaveLabel") as Control
		if wave:
			wave.position.x = max(330.0, view.x * 0.33)
			wave.size.x = max(320.0, view.x * 0.34)
		var gold := top_bar.get_node_or_null("GoldLabel") as Control
		if gold:
			gold.position.x = max(760.0, view.x - 270.0)
			gold.size.x = 245.0
	var bottom := hud.get_node_or_null("Bottom") as Control
	if bottom:
		bottom.position = Vector2.ZERO
		bottom.position.y = view.y - 140.0
		bottom.size = Vector2(view.x, 140.0)
		var skills := bottom.get_node_or_null("SkillBar") as Control
		if skills:
			skills.position.x = max(330.0, view.x * 0.28)
			skills.position.y = 48.0
			skills.size.x = max(620.0, view.x - skills.position.x - 28.0)

func _setup_player_team() -> void:
	var team = GameManager.player_team
	if team.is_empty() and not GameManager.owned_monsters.is_empty():
		# Fallback: take first 3 owned
		for i in range(mini(3, GameManager.owned_monsters.size())):
			team.append(GameManager.owned_monsters[i])
		GameManager.player_team = team
	# Never allow a blank battle when a starter/owned monster exists.
	if team.is_empty() and GameManager.has_chosen_starter:
		var starter := DataManager.create_monster_instance("sproutusk", 5)
		if not starter.is_empty():
			GameManager.owned_monsters.append(starter.duplicate(true))
			GameManager.player_team = [starter.duplicate(true)]
			team = GameManager.player_team
			SaveManager.save_game()
	player_units.clear()
	for i in range(team.size()):
		if i >= 3:
			break
		var mdata = team[i]
		var u = unit_scene.instantiate() as Unit
		units_container.add_child(u)
		var y_off = SLOT_OFFSETS[i] if i < SLOT_OFFSETS.size() else (i - 1) * 70.0
		u.global_position = player_spawn.global_position + Vector2(0, y_off)
		u.setup(mdata, 0, i)
		u.died.connect(_on_player_unit_died)
		u.hp_changed.connect(func(_cur: int, _max_hp: int): _sync_castle_hp_from_team())
		player_units.append(u)
	_sync_castle_hp_from_team()
	_refresh_team_slot_labels()
	_update_skill_labels()

func _refresh_team_slot_labels() -> void:
	for i in range(3):
		var path = "UnitStrip/UnitSelect/Unit%d" % (i + 1)
		if not hud or not hud.has_node(path):
			continue
		var btn = hud.get_node(path)
		if i < player_units.size() and player_units[i] and player_units[i].is_alive:
			var d = player_units[i].data
			btn.text = "%s Lv.%d" % [d.get("name", "Unit"), d.get("level", 1)]
			btn.disabled = false
		else:
			btn.text = "SLOT %d" % (i + 1)
			btn.disabled = true

func _connect_hud() -> void:
	if hud.has_node("Bottom/SkillBar/Skill1"):
		hud.get_node("Bottom/SkillBar/Skill1").pressed.connect(func(): _use_skill_manual(0))
	if hud.has_node("Bottom/SkillBar/Skill2"):
		hud.get_node("Bottom/SkillBar/Skill2").pressed.connect(func(): _use_skill_manual(1))
	if hud.has_node("Bottom/SkillBar/Skill3"):
		hud.get_node("Bottom/SkillBar/Skill3").pressed.connect(func(): _use_skill_manual(2))
	if hud.has_node("Bottom/PauseBtn"):
		hud.get_node("Bottom/PauseBtn").pressed.connect(_toggle_pause)
	if hud.has_node("Bottom/AutoBtn"):
		hud.get_node("Bottom/AutoBtn").pressed.connect(_toggle_auto)
	if hud.has_node("UnitStrip/UnitSelect/Unit1"):
		hud.get_node("UnitStrip/UnitSelect/Unit1").pressed.connect(func(): _select_unit(0))
	if hud.has_node("UnitStrip/UnitSelect/Unit2"):
		hud.get_node("UnitStrip/UnitSelect/Unit2").pressed.connect(func(): _select_unit(1))
	if hud.has_node("UnitStrip/UnitSelect/Unit3"):
		hud.get_node("UnitStrip/UnitSelect/Unit3").pressed.connect(func(): _select_unit(2))
	if catch_ui:
		catch_ui.visible = false
		if catch_ui.has_node("ThrowBasic"):
			catch_ui.get_node("ThrowBasic").pressed.connect(func(): _try_catch("basic"))
		if catch_ui.has_node("ThrowGreat"):
			catch_ui.get_node("ThrowGreat").pressed.connect(func(): _try_catch("great"))
		if catch_ui.has_node("ThrowUltra"):
			catch_ui.get_node("ThrowUltra").pressed.connect(func(): _try_catch("ultra"))
		if catch_ui.has_node("CancelCatch"):
			catch_ui.get_node("CancelCatch").pressed.connect(_cancel_catch)
	# Pause menu buttons
	if hud.has_node("PauseMenu/ResumeBtn"):
		hud.get_node("PauseMenu/ResumeBtn").pressed.connect(_resume_from_pause)
	if hud.has_node("PauseMenu/RestartBtn"):
		hud.get_node("PauseMenu/RestartBtn").pressed.connect(func(): SceneManager.go_combat())
	if hud.has_node("PauseMenu/QuitBtn"):
		hud.get_node("PauseMenu/QuitBtn").pressed.connect(func(): SceneManager.go_main_menu())

func _process(delta: float) -> void:
	_update_skill_labels()
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if is_spawning and enemies_spawned < enemies_to_spawn:
		wave_timer -= delta
		if wave_timer <= 0:
			_spawn_enemy()
			wave_timer = spawn_interval
	# Check wave clear (guard against multi-fire while awaiting)
	if not wave_transitioning and not is_spawning and current_enemies.is_empty() and enemies_spawned >= enemies_to_spawn and enemies_to_spawn > 0:
		_on_wave_cleared()
	# Smarter auto-battle: prefer ready skills on nearest units
	if GameManager.auto_battle and not player_units.is_empty():
		_auto_battle_tick()

func _auto_battle_tick() -> void:
	for u in player_units:
		if not u.is_alive:
			continue
		var idx = u.get_ready_skill_index()
		if idx >= 0:
			u.use_skill(idx)
			break  # one skill per frame to avoid spam

func _start_next_wave() -> void:
	wave_transitioning = false
	GameManager.current_wave += 1
	GameManager.wave_changed.emit(GameManager.current_wave)
	current_enemies.clear()
	enemies_spawned = 0
	is_boss_wave = false
	var diff_mult = _difficulty_mult()
	if GameManager.current_mode == GameManager.GameMode.DUNGEON:
		if GameManager.current_wave == 5 or GameManager.current_wave == 10:
			is_boss_wave = true
			enemies_to_spawn = 1
			spawn_interval = 1.0
		elif GameManager.current_wave >= 15:
			is_boss_wave = true
			enemies_to_spawn = 1
		else:
			enemies_to_spawn = int((3 + GameManager.current_wave) * diff_mult)
			spawn_interval = max(1.0, 3.0 - GameManager.current_wave * 0.1)
	elif GameManager.current_mode == GameManager.GameMode.HUNT:
		enemies_to_spawn = 4 + GameManager.current_wave / 2
		spawn_interval = 2.4
	else:
		enemies_to_spawn = int((4 + GameManager.current_wave) * diff_mult)
		spawn_interval = max(1.3, 3.2 - GameManager.current_wave * 0.12)
	is_spawning = true
	wave_timer = 0.05
	_update_wave_label()

func _difficulty_mult() -> float:
	match GameManager.difficulty:
		"Easy": return 0.7
		"Hard": return 1.35
		"Nightmare": return 1.7
		_: return 1.0

func _spawn_enemy() -> void:
	var monster_id = _pick_enemy_id()
	var level = 1 + GameManager.current_wave / 2
	if is_boss_wave:
		if GameManager.current_wave >= 15:
			monster_id = "boss_inferno"
			level = 18 + GameManager.current_wave
		else:
			monster_id = "dragon_whelp"
			level = 8 + GameManager.current_wave
	var mdata = DataManager.create_monster_instance(monster_id, level)
	# Apply difficulty HP/ATK scale
	var mult = _difficulty_mult()
	mdata.max_hp = int(mdata.max_hp * mult)
	mdata.hp = mdata.max_hp
	mdata.atk = int(mdata.atk * (0.9 + mult * 0.15))
	var u = unit_scene.instantiate() as Unit
	units_container.add_child(u)
	_configure_playfield()
	u.global_position = spawn_point.global_position + Vector2(0, randf_range(-65, 65))
	u.setup(mdata, 1)  # 1 = Unit.Side.ENEMY (fix headless export enum bug)
	u.died.connect(_on_enemy_died)
	current_enemies.append(u)
	enemies_spawned += 1
	if enemies_spawned >= enemies_to_spawn:
		is_spawning = false

func _pick_enemy_id() -> String:
	if GameManager.current_mode == GameManager.GameMode.HUNT:
		var island = DataManager.islands.get(GameManager.selected_island, DataManager.islands.get("forest", {}))
		var pool = island.get("monsters", ["slime"])
		return pool[randi() % pool.size()]
	var pool = ["slime", "wolf", "bat", "golem"]
	if GameManager.current_wave > 4:
		pool.append("dragon_whelp")
	return pool[randi() % pool.size()]

func _on_enemy_died(unit: Unit) -> void:
	current_enemies.erase(unit)
	if GameManager.current_mode == GameManager.GameMode.HUNT and not unit.data.get("is_boss", false):
		_offer_catch(unit)

func _on_player_unit_died(unit: Unit) -> void:
	player_units.erase(unit)
	_sync_castle_hp_from_team()
	if player_units.is_empty():
		GameManager.game_over.emit(false)

func _sync_castle_hp_from_team() -> void:
	var max_total := 0
	var cur_total := 0
	for u in player_units:
		if is_instance_valid(u):
			max_total += int(u.max_hp)
			cur_total += int(u.hp)
	if max_total > 0:
		GameManager.castle_max_hp = max_total
		GameManager.castle_hp = cur_total
		GameManager.castle_hp_changed.emit(GameManager.castle_hp, GameManager.castle_max_hp)

func _on_wave_cleared() -> void:
	if wave_transitioning:
		return
	wave_transitioning = true
	wave_cleared.emit(GameManager.current_wave)
	if GameManager.current_wave >= GameManager.max_waves:
		_victory()
		wave_transitioning = false
	else:
		await get_tree().create_timer(1.4).timeout
		if GameManager.current_state == GameManager.GameState.PLAYING:
			_start_next_wave()
		wave_transitioning = false

func _victory() -> void:
	var bonus = 80 * GameManager.current_wave
	match GameManager.difficulty:
		"Hard": bonus = int(bonus * 1.5)
		"Nightmare": bonus = int(bonus * 2.2)
	GameManager.add_gold(bonus)
	gold_earned_this_run += bonus
	# TD (Defense) victory grants 1 gem
	if GameManager.current_mode == GameManager.GameMode.DEFENSE:
		GameManager.add_gems(1)
	if GameManager.current_mode == GameManager.GameMode.DUNGEON and GameManager.difficulty in ["Hard", "Nightmare"]:
		GameManager.inventory["boss_egg"] = GameManager.inventory.get("boss_egg", 0) + 1
	SaveManager.save_game()
	combat_ended.emit(true)
	_show_result(true)

func _on_game_over(won: bool) -> void:
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.RESULT
	if not won:
		_show_result(false)

func _show_result(won: bool) -> void:
	GameManager.current_state = GameManager.GameState.RESULT
	AudioManager.stop_bgm()
	if hud.has_node("ResultPanel"):
		var panel = hud.get_node("ResultPanel")
		panel.visible = true
		if panel.has_node("ResultLabel"):
			panel.get_node("ResultLabel").text = "VICTORY!" if won else "DEFEAT..."
		if panel.has_node("DetailLabel"):
			var detail = "Gold earned: ~%d\nCaught: %d" % [gold_earned_this_run, monsters_caught_this_run.size()]
			if won and GameManager.current_mode == GameManager.GameMode.DEFENSE:
				detail += "\nGem +1"
			if won and GameManager.current_mode == GameManager.GameMode.DUNGEON and GameManager.difficulty in ["Hard", "Nightmare"]:
				detail += "\nBoss Egg obtained!"
			panel.get_node("DetailLabel").text = detail
		if panel.has_node("RetryBtn"):
			var btn = panel.get_node("RetryBtn")
			if not btn.pressed.is_connected(_on_retry):
				btn.pressed.connect(_on_retry)
		if panel.has_node("MenuBtn"):
			var btn2 = panel.get_node("MenuBtn")
			if not btn2.pressed.is_connected(_on_menu):
				btn2.pressed.connect(_on_menu)

func _on_retry() -> void:
	SceneManager.go_combat()

func _on_menu() -> void:
	SceneManager.go_main_menu()

func _select_unit(idx: int) -> void:
	if idx < player_units.size() and player_units[idx].is_alive:
		selected_unit_idx = idx
		_update_skill_labels()

func _use_skill_manual(skill_idx: int) -> void:
	if player_units.is_empty():
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	var chosen: Unit = null
	if selected_unit_idx < player_units.size() and is_instance_valid(player_units[selected_unit_idx]) and player_units[selected_unit_idx].is_alive:
		chosen = player_units[selected_unit_idx]
	else:
		chosen = _find_best_unit_for_skill()
	if chosen and is_instance_valid(chosen):
		var ok = chosen.use_skill(skill_idx)
		_update_skill_labels()
		if ok:
			AudioManager.play_sfx("button")

func _find_best_unit_for_skill() -> Unit:
	var best: Unit = null
	var best_dist := INF
	for u in player_units:
		if not u.is_alive:
			continue
		var nearest = u._find_nearest_opponent()
		if nearest:
			var d = u.global_position.distance_to(nearest.global_position)
			if d < best_dist:
				best_dist = d
				best = u
	if best == null:
		for u in player_units:
			if u.is_alive:
				return u
	return best

func _update_skill_labels() -> void:
	if not hud or player_units.is_empty():
		return
	var u: Unit = null
	if selected_unit_idx < player_units.size() and is_instance_valid(player_units[selected_unit_idx]) and player_units[selected_unit_idx].is_alive:
		u = player_units[selected_unit_idx]
	else:
		for pu in player_units:
			if is_instance_valid(pu) and pu.is_alive:
				u = pu
				break
	if u == null:
		return
	var skills = u.data.get("skills", [])
	for i in range(3):
		var btn_path = "Bottom/SkillBar/Skill%d" % (i + 1)
		if hud.has_node(btn_path):
			var btn = hud.get_node(btn_path)
			if i < skills.size():
				var sid = skills[i]
				var sk = DataManager.get_skill(sid)
				var cd = float(u.skill_cooldowns.get(sid, 0.0))
				var cost = float(sk.get("mana_cost", 15))
				var nm = sk.get("name", "Skill")
				if cd > 0.05:
					btn.text = "%s\n%.1fs" % [nm, cd]
					btn.disabled = true
				elif u.mana < cost:
					btn.text = "%s\nMP %d" % [nm, int(cost)]
					btn.disabled = true
				else:
					btn.text = "%s\n%d MP" % [nm, int(cost)]
					btn.disabled = false
			else:
				btn.text = "-"
				btn.disabled = true

func _toggle_pause() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		var pm := hud.get_node_or_null("PauseMenu")
		if pm:
			pm.process_mode = Node.PROCESS_MODE_ALWAYS
			pm.visible = true
			pm.z_index = 100
		get_tree().paused = true
		GameManager.current_state = GameManager.GameState.PAUSED
	else:
		_resume_from_pause()

func _resume_from_pause() -> void:
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.PLAYING
	if hud.has_node("PauseMenu"):
		hud.get_node("PauseMenu").visible = false

func _toggle_auto() -> void:
	GameManager.auto_battle = not GameManager.auto_battle
	if hud.has_node("Bottom/AutoBtn"):
		hud.get_node("Bottom/AutoBtn").text = "AUTO: ON" if GameManager.auto_battle else "AUTO: OFF"

func _offer_catch(unit: Unit) -> void:
	target_for_catch = unit.data.duplicate(true)
	target_for_catch["last_hp"] = unit.hp
	target_for_catch["last_max_hp"] = unit.max_hp
	target_for_catch["last_level"] = unit.level
	if catch_ui:
		catch_ui.visible = true
		if catch_ui.has_node("InfoLabel"):
			var hp_ratio = float(unit.hp) / max(1, unit.max_hp)
			catch_ui.get_node("InfoLabel").text = "%s (HP %.0f%%)\nChoose Ball" % [unit.data.get("name", "?"), hp_ratio * 100]
		_update_ball_buttons()

func _update_ball_buttons() -> void:
	for bid in ["basic", "great", "ultra"]:
		var node_name = "Throw" + bid.capitalize()
		if catch_ui and catch_ui.has_node(node_name):
			var btn = catch_ui.get_node(node_name)
			var count = GameManager.balls.get(bid, 0)
			btn.text = "%s (%d)" % [bid.capitalize(), count]
			btn.disabled = count <= 0

func _try_catch(ball_id: String) -> void:
	if target_for_catch.is_empty() or GameManager.balls.get(ball_id, 0) <= 0:
		return
	GameManager.balls[ball_id] -= 1
	var hp_ratio = float(target_for_catch.get("last_hp", 1)) / max(1, target_for_catch.get("last_max_hp", 1))
	var rate = DataManager.calc_catch_rate(target_for_catch, ball_id, hp_ratio)
	var success = randf() < rate
	_play_catch_fx(success)
	if success:
		var new_mon = DataManager.create_monster_instance(target_for_catch.id, target_for_catch.get("last_level", 1))
		GameManager.add_owned_monster(new_mon)
		monsters_caught_this_run.append(new_mon)
		if catch_ui.has_node("InfoLabel"):
			catch_ui.get_node("InfoLabel").text = "SUCCESS! Caught " + new_mon.name
		AudioManager.play_sfx("catch_success")
	else:
		if catch_ui.has_node("InfoLabel"):
			catch_ui.get_node("InfoLabel").text = "Failed... Ball broke!"
		AudioManager.play_sfx("catch_fail")
	await get_tree().create_timer(1.3).timeout
	_cancel_catch()
	SaveManager.save_game()

func _play_catch_fx(success: bool) -> void:
	if not catch_ui:
		return
	var player := catch_ui.get_node_or_null("CatchFXPlayer") as AnimationPlayer
	if player == null:
		player = AnimationPlayer.new()
		player.name = "CatchFXPlayer"
		catch_ui.add_child(player)
		player.root_node = NodePath("..")
		var lib := AnimationLibrary.new()
		player.add_animation_library("", lib)
		for pair in [["success", Color(0.30, 1.0, 0.4)], ["fail", Color(1.0, 0.3, 0.3)]]:
			var anim := Animation.new()
			anim.length = 0.45
			var mod_track := anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(mod_track, NodePath(".:modulate"))
			anim.track_insert_key(mod_track, 0.0, pair[1])
			anim.track_insert_key(mod_track, 0.18, Color.WHITE)
			anim.track_insert_key(mod_track, anim.length, Color.WHITE)
			lib.add_animation(pair[0], anim)
	player.play("success" if success else "fail")

func _cancel_catch() -> void:
	target_for_catch = {}
	if catch_ui:
		catch_ui.visible = false

func _on_castle_hp(cur: int, mx: int) -> void:
	if hud.has_node("TopBar/CastleHPBar"):
		hud.get_node("TopBar/CastleHPBar").max_value = mx
		hud.get_node("TopBar/CastleHPBar").value = cur
	if hud.has_node("TopBar/CastleHPLabel"):
		hud.get_node("TopBar/CastleHPLabel").text = "CASTLE %d/%d" % [cur, mx]

func _on_gold_changed(g: int) -> void:
	if hud.has_node("TopBar/GoldLabel"):
		hud.get_node("TopBar/GoldLabel").text = "Gold: %d" % g

func _update_wave_label() -> void:
	if hud.has_node("TopBar/WaveLabel"):
		var extra = " [BOSS]" if is_boss_wave else ""
		hud.get_node("TopBar/WaveLabel").text = "Wave %d / %d%s" % [GameManager.current_wave, GameManager.max_waves, extra]

func _on_castle_body_entered(body: Node2D) -> void:
	if body is Unit and body.side == Unit.Side.ENEMY and body.is_alive:
		var dmg := 20 + body.level * 3
		# Castle HP is the aggregate HP of the three equipped monsters, so a leak
		# damages the team rather than a separate 1000-HP base.
		var target: Unit = null
		for u in player_units:
			if is_instance_valid(u) and u.is_alive:
				target = u
				break
		if target:
			target.take_damage(dmg, body)
		else:
			GameManager.game_over.emit(false)
		body.take_damage(99999)
