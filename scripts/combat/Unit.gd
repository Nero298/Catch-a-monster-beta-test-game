extends CharacterBody2D
class_name Unit
## Unit with real spritesheet (5 frames: idle0, idle1, attack, hit, death) + AnimationPlayer + hit particles

signal died(unit: Unit)
signal hp_changed(current: int, max_hp: int)
signal attacked(target: Unit, damage: int, is_crit: bool)

enum Side { PLAYER, ENEMY }

@export var data: Dictionary = {}
var side: int = Side.ENEMY  # FIX: dùng int thay vì Side để tránh lỗi headless export
var max_hp: int = 100
var hp: int = 100
var atk: int = 10
var def: int = 5
var spd: int = 10
var level: int = 1
var is_alive: bool = true
var skill_cooldowns: Dictionary = {}
var mana: float = 50.0
var max_mana: float = 50.0
var mana_regen: float = 6.0  # per second
var move_speed: float = 80.0
var attack_range: float = 70.0
var attack_timer: float = 0.0
var base_attack_interval: float = 1.2
var slot_index: int = 0

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var color_rect: ColorRect = $Visual/ColorRect
@onready var name_tag: Label = $Visual/NameTag
@onready var hp_bar: ProgressBar = $HPBar
@onready var name_label: Label = $NameLabel
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hit_particles: CPUParticles2D = $HitParticles

const FRAME_W := 64
const FRAME_H := 64

func setup(monster_data: Dictionary, unit_side: int, p_slot: int = 0) -> void:  # unit_side is int for export-safe builds
	data = monster_data.duplicate(true)
	side = unit_side
	slot_index = p_slot
	z_index = 20
	visible = true
	level = data.get("level", 1)
	max_hp = data.get("max_hp", 100)
	hp = data.get("hp", max_hp)
	atk = data.get("atk", 10)
	def = data.get("def", 5)
	spd = data.get("spd", 10)
	is_alive = true
	move_speed = 40.0 + spd * 3.0
	base_attack_interval = max(0.55, 1.5 - spd * 0.03)
	max_mana = 40.0 + level * 6.0 + spd * 1.5
	mana = max_mana
	mana_regen = 5.0 + spd * 0.15
	_setup_collision_layers()
	_load_sprite()
	_setup_animations()
	_update_hp_bar()
	_setup_hp_bar_style()
	if name_label:
		name_label.text = data.get("name", "???") + " Lv." + str(level)
	if name_tag:
		name_tag.text = data.get("name", "?").substr(0, 8)
	if anim_player and anim_player.has_animation("spawn"):
		_play_anim("spawn")
	if anim_player and anim_player.has_animation("idle"):
		anim_player.queue("idle")
	if visual:
		visual.modulate = Color.WHITE

func _setup_collision_layers() -> void:
	if side == Side.PLAYER:
		collision_layer = 1
		collision_mask = 2
		add_to_group("player_units")
	else:
		collision_layer = 2
		collision_mask = 1 | 4
		add_to_group("enemies")

func _load_sprite() -> void:
	var path = data.get("sprite", "")
	if path.is_empty():
		path = DataManager.get_sprite_path(data.get("id", "slime"))
	if color_rect:
		color_rect.visible = false
	if visual:
		visual.visible = true
		visual.modulate = Color.WHITE
	if sprite and ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		sprite.texture = tex
		# Only treat as horizontal spritesheet if width covers multiple frames
		var is_sheet := tex.get_width() >= FRAME_W * 2
		sprite.region_enabled = is_sheet
		if is_sheet:
			sprite.region_rect = Rect2(0, 0, FRAME_W, FRAME_H)
		else:
			sprite.region_enabled = false
		sprite.visible = true
		sprite.centered = true
		# Scale to readable size on mobile
		var target_h := 96.0
		var sy := target_h / max(1.0, float(tex.get_height() if not is_sheet else FRAME_H))
		var sx := sy
		if side == Side.PLAYER:
			sprite.scale = Vector2(sx * 1.15, sy * 1.15)
		else:
			# Face left (toward castle) — negative X flips
			sprite.scale = Vector2(-sx, sy)
	elif color_rect:
		color_rect.visible = true
		color_rect.color = data.get("color", Color(0.7, 0.7, 0.7))

func _setup_animations() -> void:
	if not anim_player:
		return
	var lib := anim_player.get_animation_library("") if anim_player.has_animation_library("") else null
	if lib == null:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)
	var is_sheet := false
	if sprite and sprite.texture:
		is_sheet = sprite.region_enabled and sprite.texture.get_width() >= FRAME_W * 2
	if is_sheet:
		_add_full_anim(lib, "idle", [0, 1], 0.32, true, Vector2.ONE, Vector2.ONE)
		_add_full_anim(lib, "attack", [2, 1, 0], 0.12, false, Vector2(1.12, 0.94), Vector2(1.0, 1.0))
		_add_full_anim(lib, "hit", [3, 0], 0.10, false, Vector2(0.96, 1.04), Vector2(1.0, 1.0))
		_add_full_anim(lib, "death", [4], 0.45, false, Vector2(0.90, 0.90), Vector2(1.0, 0.0))
		_add_full_anim(lib, "spawn", [0, 1], 0.12, false, Vector2(0.75, 0.75), Vector2(1.0, 1.0))
	else:
		# Single-frame art: bob / squash only (no region frame swap)
		_add_bob_anim(lib, "idle", 0.55, true)
		_add_bob_anim(lib, "attack", 0.18, false, Vector2(1.18, 0.88), Vector2(1.0, 1.0))
		_add_bob_anim(lib, "hit", 0.12, false, Vector2(0.92, 1.08), Vector2(1.0, 1.0))
		_add_bob_anim(lib, "death", 0.4, false, Vector2(1.0, 1.0), Vector2(0.2, 0.2))
		_add_bob_anim(lib, "spawn", 0.2, false, Vector2(0.5, 0.5), Vector2(1.0, 1.0))

func _add_bob_anim(lib: AnimationLibrary, anim_name: String, length: float, loop: bool, start_s: Vector2 = Vector2.ONE, end_s: Vector2 = Vector2.ONE) -> void:
	if lib.has_animation(anim_name):
		return
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var base = Vector2(1.15, 1.15) if side == Side.PLAYER else Vector2(1.0, 1.0)
	var scale_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(scale_track, NodePath("Visual:scale"))
	if loop:
		anim.track_insert_key(scale_track, 0.0, base * Vector2(1.0, 1.0))
		anim.track_insert_key(scale_track, length * 0.5, base * Vector2(1.04, 0.96))
		anim.track_insert_key(scale_track, length, base * Vector2(1.0, 1.0))
	else:
		anim.track_insert_key(scale_track, 0.0, base * start_s)
		anim.track_insert_key(scale_track, length, base * end_s)
	if anim_name == "hit":
		var mod_track := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(mod_track, NodePath("Visual:modulate"))
		anim.track_insert_key(mod_track, 0.0, Color(1.5, 0.6, 0.6))
		anim.track_insert_key(mod_track, length, Color.WHITE)
	lib.add_animation(anim_name, anim)

func _add_full_anim(lib: AnimationLibrary, anim_name: String, frames: Array, step: float, loop: bool, start_scale: Vector2, end_scale: Vector2) -> void:
	if lib.has_animation(anim_name):
		return
	var anim := Animation.new()
	anim.length = max(0.08, frames.size() * step)
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	var frame_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(frame_track, NodePath("Visual/Sprite2D:region_rect"))
	# CRITICAL: discrete keys — no lerp between region rects (that caused 2-frame slide jitter)
	anim.track_set_interpolation_type(frame_track, Animation.INTERPOLATION_NEAREST)
	anim.value_track_set_update_mode(frame_track, Animation.UPDATE_DISCRETE)
	for i in range(frames.size()):
		anim.track_insert_key(frame_track, i * step, Rect2(frames[i] * FRAME_W, 0, FRAME_W, FRAME_H))

	var scale_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(scale_track, NodePath("Visual:scale"))
	anim.track_insert_key(scale_track, 0.0, start_scale * (Vector2(1.2, 1.2) if side == Side.PLAYER else Vector2.ONE))
	anim.track_insert_key(scale_track, anim.length, end_scale * (Vector2(1.2, 1.2) if side == Side.PLAYER else Vector2.ONE))

	var pos_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(pos_track, NodePath("Visual:position"))
	var offset := Vector2(-5, 0) if anim_name == "attack" else Vector2.ZERO
	anim.track_insert_key(pos_track, 0.0, offset)
	anim.track_insert_key(pos_track, anim.length * 0.45, -offset)
	anim.track_insert_key(pos_track, anim.length, Vector2.ZERO)

	if anim_name == "spawn":
		var mod_track := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(mod_track, NodePath("Visual:modulate"))
		anim.track_insert_key(mod_track, 0.0, Color(1, 1, 1, 0))
		anim.track_insert_key(mod_track, anim.length * 0.65, Color.WHITE)
		anim.track_insert_key(mod_track, anim.length, Color.WHITE)
	lib.add_animation(anim_name, anim)

func _play_anim(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

func _physics_process(delta: float) -> void:
	if not is_alive or GameManager.current_state != GameManager.GameState.PLAYING:
		return
	attack_timer -= delta
	_update_cooldowns(delta)
	mana = min(max_mana, mana + mana_regen * delta)
	if side == Side.ENEMY:
		_enemy_ai(delta)
	else:
		_player_ai(delta)

func _enemy_ai(_delta: float) -> void:
	# Enemies spawn on the RIGHT and march LEFT toward player/castle
	velocity = Vector2(-move_speed, 0)
	move_and_slide()
	var nearest = _find_nearest_opponent()
	if nearest and global_position.distance_to(nearest.global_position) <= attack_range:
		velocity = Vector2.ZERO
		if attack_timer <= 0:
			_perform_basic_attack(nearest)
			attack_timer = base_attack_interval

func _player_ai(_delta: float) -> void:
	velocity = Vector2.ZERO
	var nearest = _find_nearest_opponent()
	if nearest and global_position.distance_to(nearest.global_position) <= attack_range * 1.8:
		if attack_timer <= 0:
			_perform_basic_attack(nearest)
			attack_timer = base_attack_interval

func _find_nearest_opponent() -> Unit:
	var group_name = "player_units" if side == Side.ENEMY else "enemies"
	var opponents = get_tree().get_nodes_in_group(group_name)
	var nearest: Unit = null
	var min_dist := INF
	for u in opponents:
		if u is Unit and u.is_alive:
			var d = global_position.distance_to(u.global_position)
			if d < min_dist:
				min_dist = d
				nearest = u
	return nearest

func _perform_basic_attack(target_unit: Unit) -> void:
	if not target_unit or not target_unit.is_alive:
		return
	var damage = max(1, atk - int(target_unit.def / 2.0))
	var is_crit = randf() < clampf(spd * 0.006, 0.03, 0.25)
	if is_crit:
		damage = int(damage * 1.6)
	target_unit.take_damage(damage, self, is_crit)
	attacked.emit(target_unit, damage, is_crit)
	_play_anim("attack")
	if anim_player and anim_player.has_animation("idle"):
		anim_player.queue("idle")
	AudioManager.play_sfx("attack")

func use_skill(skill_index: int) -> bool:
	if not is_alive:
		return false
	if skill_index < 0 or skill_index >= data.get("skills", []).size():
		return false
	var skill_id = data.skills[skill_index]
	if skill_cooldowns.get(skill_id, 0.0) > 0.0:
		return false
	var skill = DataManager.get_skill(skill_id)
	if skill.is_empty():
		return false
	var mana_cost := float(skill.get("mana_cost", 15))
	if mana < mana_cost:
		return false  # not enough mana — skill blocked even if CD ready
	var target_unit = _find_nearest_opponent()
	match skill.get("type", "damage"):
		"damage":
			if not target_unit: return false
			var dmg = int(skill.power * (1.0 + atk * 0.05))
			var is_crit = randf() < 0.12
			if is_crit: dmg = int(dmg * 1.5)
			target_unit.take_damage(dmg, self, is_crit)
		"buff_atk":
			atk = int(atk * 1.25)
		"buff_def":
			def = int(def * 1.3)
		"debuff_atk":
			if target_unit: target_unit.atk = max(1, int(target_unit.atk * 0.75))
		"debuff_def":
			if target_unit: target_unit.def = max(1, int(target_unit.def * 0.75))
		"dot_heal":
			if target_unit: target_unit.take_damage(skill.power, self)
			heal(skill.power)
		_:
			if target_unit: target_unit.take_damage(int(skill.get("power", 10)), self)
	var mana_cost_spend := float(skill.get("mana_cost", 15))
	mana = max(0.0, mana - mana_cost_spend)
	skill_cooldowns[skill_id] = float(skill.get("cooldown", 2.0))
	_play_anim("attack")
	if anim_player and anim_player.has_animation("idle"):
		anim_player.queue("idle")
	AudioManager.play_sfx("attack")
	return true

func get_ready_skill_index() -> int:
	var skills_arr = data.get("skills", [])
	for i in range(skills_arr.size()):
		if skill_cooldowns.get(skills_arr[i], 0.0) > 0.0:
			continue
		var sk = DataManager.get_skill(skills_arr[i])
		var cost = float(sk.get("mana_cost", 15))
		if mana >= cost:
			return i
	return -1

func _update_cooldowns(delta: float) -> void:
	for k in skill_cooldowns.keys():
		skill_cooldowns[k] = max(0.0, skill_cooldowns[k] - delta)

func take_damage(amount: int, _source: Unit = null, is_crit: bool = false) -> void:
	if not is_alive:
		return
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	_update_hp_bar()
	if GameManager.show_damage_numbers:
		_spawn_damage_number(amount, is_crit)
	_play_anim("hit")
	if hit_particles:
		hit_particles.restart()
		hit_particles.emitting = true
	AudioManager.play_sfx("hit")
	if anim_player and anim_player.has_animation("idle") and hp > 0:
		anim_player.queue("idle")
	if hp <= 0:
		_die()

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)
	_update_hp_bar()

func _die() -> void:
	is_alive = false
	died.emit(self)
	_play_anim("death")
	if side == Side.ENEMY:
		GameManager.add_gold(5 + level * 2)
	AudioManager.play_sfx("death")
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _setup_hp_bar_style() -> void:
	if not hp_bar: return
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.18, 0.85)
	bg.set_corner_radius_all(4)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 0.85, 0.4) if side == Side.PLAYER else Color(0.95, 0.3, 0.25)
	fill.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("background", bg)
	hp_bar.add_theme_stylebox_override("fill", fill)
	hp_bar.show_percentage = false

func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		hp_bar.visible = true

func _spawn_damage_number(amount: int, is_crit: bool = false) -> void:
	var label = Label.new()
	label.text = ("CRIT %d" % amount) if is_crit else str(amount)
	label.z_index = 20
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_crit:
		label.modulate = Color(1.0, 0.85, 0.15)
		label.add_theme_font_size_override("font_size", 22)
	else:
		label.modulate = Color(1.0, 0.35, 0.3) if side == Side.PLAYER else Color(1.0, 0.95, 0.4)
		label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(-30, -55)
	add_child(label)
	var ap := AnimationPlayer.new()
	label.add_child(ap)
	ap.root_node = NodePath("..")
	var lib := AnimationLibrary.new()
	ap.add_animation_library("", lib)
	var anim := Animation.new()
	anim.length = 0.7
	var pos_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(pos_track, NodePath(".:position"))
	anim.track_insert_key(pos_track, 0.0, label.position)
	anim.track_insert_key(pos_track, 0.7, label.position + Vector2(0, -55))
	var alpha_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(alpha_track, NodePath(".:modulate:a"))
	anim.track_insert_key(alpha_track, 0.0, 1.0)
	anim.track_insert_key(alpha_track, 0.7, 0.0)
	lib.add_animation("float", anim)
	ap.animation_finished.connect(func(_name): label.queue_free())
	ap.play("float")
