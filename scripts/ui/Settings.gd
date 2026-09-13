extends Control
## Settings: BGM/SFX volume, show damage numbers, save

@onready var bgm_slider: HSlider = $VBox/BGMSlider
@onready var sfx_slider: HSlider = $VBox/SFXSlider
@onready var dmg_check: CheckButton = $VBox/DamageCheck
@onready var status: Label = $VBox/StatusLabel

func _ready() -> void:
	if bgm_slider:
		bgm_slider.value = GameManager.volume_bgm * 100.0
		bgm_slider.value_changed.connect(_on_bgm)
	if sfx_slider:
		sfx_slider.value = GameManager.volume_sfx * 100.0
		sfx_slider.value_changed.connect(_on_sfx)
	if dmg_check:
		dmg_check.button_pressed = GameManager.show_damage_numbers
		dmg_check.toggled.connect(_on_dmg)

func _on_bgm(v: float) -> void:
	AudioManager.set_bgm_volume(v / 100.0)
	_save()

func _on_sfx(v: float) -> void:
	AudioManager.set_sfx_volume(v / 100.0)
	_save()

func _on_dmg(pressed: bool) -> void:
	GameManager.show_damage_numbers = pressed
	_save()

func _save() -> void:
	SaveManager.save_game()
	if status:
		status.text = "Saved"

func _on_back() -> void:
	AudioManager.play_sfx("button")
	SceneManager.go_main_menu()
