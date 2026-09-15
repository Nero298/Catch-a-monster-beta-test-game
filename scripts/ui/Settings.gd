extends Control
## Settings with the same tan/white visual language.

const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"
var status: Label

func _ready() -> void:
    _build_ui()

func _bg() -> void:
    var bg := TextureRect.new()
    bg.texture = load(BG_TEXTURE) if ResourceLoader.exists(BG_TEXTURE) else null
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var shade := ColorRect.new()
    shade.color = Color(0.05, 0.035, 0.02, 0.48)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

func _build_ui() -> void:
    _bg()
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(560, 500)
    card.add_theme_stylebox_override("panel", UITheme.panel_tan(0.98))
    center.add_child(card)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 12)
    card.add_child(v)
    v.add_child(UITheme.label("SETTINGS", 28))

    var bgm := HSlider.new()
    bgm.name = "BGMSlider"
    bgm.min_value = 0
    bgm.max_value = 100
    bgm.value = GameManager.volume_bgm * 100.0
    bgm.value_changed.connect(_on_bgm)
    v.add_child(UITheme.label("BGM VOLUME", 14, HORIZONTAL_ALIGNMENT_LEFT))
    v.add_child(bgm)

    var sfx := HSlider.new()
    sfx.name = "SFXSlider"
    sfx.min_value = 0
    sfx.max_value = 100
    sfx.value = GameManager.volume_sfx * 100.0
    sfx.value_changed.connect(_on_sfx)
    v.add_child(UITheme.label("SFX VOLUME", 14, HORIZONTAL_ALIGNMENT_LEFT))
    v.add_child(sfx)

    var check := CheckButton.new()
    check.text = "SHOW DAMAGE NUMBERS"
    check.button_pressed = GameManager.show_damage_numbers
    check.toggled.connect(_on_dmg)
    check.add_theme_color_override("font_color", Color.WHITE)
    v.add_child(check)

    status = UITheme.label("", 13)
    v.add_child(status)
    var back := UITheme.button("BACK", Vector2(160, 48), 16)
    back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    back.pressed.connect(_on_back)
    v.add_child(back)

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
    if is_instance_valid(status): status.text = "Saved"
func _on_back() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_main_menu()
