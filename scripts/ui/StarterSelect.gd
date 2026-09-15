extends Control
## First-run starter selection, using the same tan UI language.

const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"
var container: HBoxContainer
var confirm_btn: Button
var desc_label: Label
var selected_id := ""
var starter_ids: Array = []

func _ready() -> void:
    _build()
    starter_ids = DataManager.get_starters()
    _build_cards()

func _build() -> void:
    var bg := TextureRect.new()
    bg.texture = load(BG_TEXTURE) if ResourceLoader.exists(BG_TEXTURE) else null
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var shade := ColorRect.new()
    shade.color = Color(0.05, 0.035, 0.02, 0.46)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 30)
    margin.add_theme_constant_override("margin_right", 30)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 12)
    margin.add_child(root)
    root.add_child(UITheme.label("CHOOSE YOUR STARTER", 30))
    desc_label = UITheme.label("Select one starter monster", 14)
    root.add_child(desc_label)
    container = HBoxContainer.new()
    container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    container.alignment = BoxContainer.ALIGNMENT_CENTER
    container.add_theme_constant_override("separation", 18)
    root.add_child(container)
    confirm_btn = UITheme.button("CONFIRM", Vector2(180, 52), 18)
    confirm_btn.disabled = true
    confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    confirm_btn.pressed.connect(_on_confirm)
    root.add_child(confirm_btn)

func _build_cards() -> void:
    for c in container.get_children(): c.queue_free()
    for id in starter_ids:
        var m: Dictionary = DataManager.monsters[id]
        var card := PanelContainer.new()
        card.custom_minimum_size = Vector2(260, 340)
        card.add_theme_stylebox_override("panel", UITheme.panel_tan(0.92))
        container.add_child(card)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 8)
        card.add_child(v)
        var tex := TextureRect.new()
        tex.custom_minimum_size = Vector2(130, 130)
        tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var path := str(m.get("icon", ""))
        if ResourceLoader.exists(path): tex.texture = load(path)
        v.add_child(tex)
        v.add_child(UITheme.label(str(m.get("name", "Monster")), 20))
        v.add_child(UITheme.label("RANK %s" % m.get("rank", "E"), 13))
        var choose := UITheme.button("SELECT", Vector2(160, 46), 15)
        choose.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        choose.pressed.connect(_on_select.bind(id, m))
        v.add_child(choose)

func _on_select(id: String, m: Dictionary) -> void:
    selected_id = id
    confirm_btn.disabled = false
    desc_label.text = "%s  |  HP %d  ATK %d  DEF %d  SPD %d" % [m.get("description", ""), m.get("base_hp", 0), m.get("base_atk", 0), m.get("base_def", 0), m.get("base_spd", 0)]
    AudioManager.play_sfx("button")
func _on_confirm() -> void:
    if selected_id.is_empty(): return
    GameManager.set_starter(selected_id)
    SceneManager.go_main_menu()
