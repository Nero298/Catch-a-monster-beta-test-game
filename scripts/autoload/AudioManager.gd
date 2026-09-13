extends Node
## Plays real SFX/BGM from assets/audio/

var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var current_bgm: String = ""
var sfx_cache: Dictionary = {}

const SFX_PATHS := {
	"attack": "res://assets/audio/sfx/attack.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"death": "res://assets/audio/sfx/death.wav",
	"catch_success": "res://assets/audio/sfx/catch_success.wav",
	"catch_fail": "res://assets/audio/sfx/catch_fail.wav",
	"level_up": "res://assets/audio/sfx/level_up.wav",
	"button": "res://assets/audio/sfx/button.wav",
}
const BGM_PATHS := {
	"menu": "res://assets/audio/bgm/menu.wav",
	"combat": "res://assets/audio/bgm/combat.wav",
	"dungeon": "res://assets/audio/bgm/dungeon.wav",
}

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(sfx_player)
	add_child(bgm_player)
	_apply_volumes()

func _apply_volumes() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = linear_to_db(clampf(GameManager.volume_bgm, 0.01, 1.0)) - 6.0
	if is_instance_valid(sfx_player):
		sfx_player.volume_db = linear_to_db(clampf(GameManager.volume_sfx, 0.01, 1.0))

func play_sfx(sfx_name: String) -> void:
	_apply_volumes()
	var path = SFX_PATHS.get(sfx_name, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	if not sfx_cache.has(sfx_name):
		sfx_cache[sfx_name] = load(path)
	sfx_player.stream = sfx_cache[sfx_name]
	sfx_player.play()

func play_bgm(bgm_name: String) -> void:
	if current_bgm == bgm_name and bgm_player.playing:
		return
	current_bgm = bgm_name
	_apply_volumes()
	var path = BGM_PATHS.get(bgm_name, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	bgm_player.stream = load(path)
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()
	current_bgm = ""

func set_bgm_volume(v: float) -> void:
	GameManager.volume_bgm = clampf(v, 0.0, 1.0)
	_apply_volumes()

func set_sfx_volume(v: float) -> void:
	GameManager.volume_sfx = clampf(v, 0.0, 1.0)
	_apply_volumes()
