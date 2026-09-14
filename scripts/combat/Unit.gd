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

func setup(monster_data: Dictionary, unit_side: int, p_slot: int = 0) -> void:  # FIX: unit_side là int
	data = monster_data.duplicate(true)
	side = unit_side
	slot_index = p_slot
	level = data.get("level", 1)
	max_hp = data.get("max_hp", 100)
	hp = data.get("hp", max_hp)
	atk = data.get("atk", 10)
	def = data.get("def", 5)
	spd = data.get("spd", 10)
	is_alive = true
	move_speed = 40.0 + spd * 3.0
	base_attack_interval = max(0.55, 1.5 - spd * 0.03)
	_setup_collision_layers()
	_load_sprite()
	_setup_animations()
	_update_hp_bar()
	_setup_hp_bar_style()
	if name_label:
		name_label.text = data.get("name", "???") + " Lv." + str(level)
	if name_tag:
		name_tag.text = data.get("name", "?").substr(0, 8)
	_play_anim("spawn")
	if anim_player and anim_player.has_animation("idle"):
		anim_player.queue("idle")

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
	if sprite and ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		sprite.texture = tex
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, FRAME_W, FRAME_H)
		sprite.visible = true
		sprite.centered = true
		if side == Side.PLAYER:
			sprite.scale = Vector2(1.2, 1.2)
		else:
			sprite.scale = Vector2(-1.0, 1.0)
	elif color_rect:
		color_rect.visible = true
		color_rect.color = data.get("color", Color(0.7, 0.7, 0.7))

func _setup_animations() -> void:
	if not anim_player:
		return
	var lib = anim_player.get_animation_library("") if anim_player.has_animation_library("") else null
	if lib == null:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)
	_add_frame_anim(lib, "idle", [0, 1], 0.35, true)
	_add_frame_anim(lib, "attack", [2], 0.25, false)
	_add_frame_anim(lib, "hit", [3], 0.2, false)
	_add_frame_anim(lib, "death", [4], 0.45, false)
	_add_frame_anim(lib, "spawn", [0], 0.15, false)

func _add_frame_anim(lib: AnimationLibrary, anim_name: String, frames: Array, step: float, loop: bool) -> void:
	if lib.has_animation(anim_name):
		return
	var anim = Animation.new()
	anim.length = max(0.05, frames.size() * step)
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("Visual/Sprite2D:region_rect"))
	for i in range(frames.size()):
		var f = frames[i]
		anim.track_insert_key(track, i * step, Rect2(f * FRAME_W, 0, FRAME_W, FRAME_H))
	lib.add_animation(anim_name, anim)

func _play_anim(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

func _physics_process(delta: float) -> void:
	if not is_alive or GameManager.current_state != GameManager.GameState.PLAYING:
		return
	attack_timer -= delta
	_update_cooldowns(delta)
	if side == Side.ENEMY:
		_enemy_ai(delta)
	else:
		_player_ai(delta)

func _enemy_ai(_delta: float) -> void:
	velocity = Vector2(move_speed, 0)
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
	skill_cooldowns[skill_id] = float(skill.get("cooldown", 2.0))
	_play_anim("attack")
	if anim_player and anim_player.has_animation("idle"):
		anim_player.queue("idle")
	AudioManager.play_sfx("attack")
	return true

func get_ready_skill_index() -> int:
	var skills_arr = data.get("skills", [])
	for i in range(skills_arr.size()):
		if skill_cooldowns.get(skills_arr[i], 0.0) <= 0.0:
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
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 55, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)
