extends Control
## Responsive landscape main menu for mobile + mouse.

const VIEW_SIZE := Vector2(1280, 720)
const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"

var gold_label: Label
var title_label: Label
var subtitle_label: Label
var play_btn: Button
var collection_btn: Button
var shop_btn: Button
var settings_btn: Button
var starter_preview: HBoxContainer

func _ready() -> void:
    _build_ui()
    _update_gold()
    GameManager.gold_changed.connect(_on_gold_changed)
    AudioManager.play_bgm("menu")

func _style_box(bg: Color, border: Color = Color.TRANSPARENT, radius := 18, border_width := 0) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = border
    box.set_border_width_all(border_width)
    box.set_corner_radius_all(radius)
    box.content_margin_left = 18
    box.content_margin_right = 18
    box.content_margin_top = 14
    box.content_margin_bottom = 14
    return box

func _label(text: String, size: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

func _button(text: String, min_size: Vector2, size: int) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.add_theme_font_size_override("font_size", size)
    b.add_theme_stylebox_override("normal", _style_box(Color("#18253a"), Color("#38506d"), 16, 1))
    b.add_theme_stylebox_override("hover", _style_box(Color("#223754"), Color("#79b8ff"), 16, 2))
    b.add_theme_stylebox_override("pressed", _style_box(Color("#102034"), Color("#8ee8d2"), 16, 2))
    return b

func _build_ui() -> void:
    var bg := TextureRect.new()
    bg.texture = load(BG_TEXTURE)
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.modulate = Color(0.55, 0.7, 0.72, 1.0)
    add_child(bg)

    var shade := ColorRect.new()
    shade.color = Color(0.03, 0.06, 0.11, 0.63)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

    var root := MarginContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("margin_left", 36)
    root.add_theme_constant_override("margin_right", 36)
    root.add_theme_constant_override("margin_top", 24)
    root.add_theme_constant_override("margin_bottom", 24)
    add_child(root)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    root.add_child(column)

    var top := HBoxContainer.new()
    top.custom_minimum_size.y = 64
    column.add_child(top)
    var player_card := PanelContainer.new()
    player_card.custom_minimum_size = Vector2(240, 64)
    player_card.add_theme_stylebox_override("panel", _style_box(Color(0.04, 0.09, 0.16, 0.92), Color("#314b68"), 14, 1))
    top.add_child(player_card)
    var pvb := VBoxContainer.new()
    player_card.add_child(pvb)
    pvb.add_child(_label(GameManager.player_name, 20))
    pvb.add_child(_label("Trainer • Local Save", 12))

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    gold_label = _label("✦ %d GOLD" % GameManager.gold, 20, HORIZONTAL_ALIGNMENT_RIGHT)
    gold_label.custom_minimum_size = Vector2(200, 64)
    top.add_child(gold_label)

    title_label = _label("CATCH A MONSTER", 48, HORIZONTAL_ALIGNMENT_CENTER)
    title_label.custom_minimum_size.y = 62
    title_label.add_theme_color_override("font_color", Color("#e8fbff"))
    column.add_child(title_label)
    subtitle_label = _label("DEFEND  •  HUNT  •  CATCH  •  RAISE", 15, HORIZONTAL_ALIGNMENT_CENTER)
    subtitle_label.custom_minimum_size.y = 28
    subtitle_label.add_theme_color_override("font_color", Color("#9fc6dc"))
    column.add_child(subtitle_label)

    var middle := HBoxContainer.new()
    middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
    middle.add_theme_constant_override("separation", 16)
    column.add_child(middle)

    var left_card := PanelContainer.new()
    left_card.custom_minimum_size = Vector2(330, 0)
    left_card.add_theme_stylebox_override("panel", _style_box(Color(0.04, 0.08, 0.14, 0.93), Color("#3a5773"), 20, 1))
    middle.add_child(left_card)
    var left := VBoxContainer.new()
    left.add_theme_constant_override("separation", 12)
    left_card.add_child(left)
    left.add_child(_label("YOUR ACTIVE TEAM", 16))
    starter_preview = HBoxContainer.new()
    starter_preview.alignment = BoxContainer.ALIGNMENT_CENTER
    starter_preview.add_theme_constant_override("separation", 10)
    starter_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left.add_child(starter_preview)
    _build_team_preview()
    var team_hint := _label("Up to 3 monsters • reorder in Collection", 12, HORIZONTAL_ALIGNMENT_CENTER)
    left.add_child(team_hint)

    var actions := VBoxContainer.new()
    actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    actions.add_theme_constant_override("separation", 12)
    middle.add_child(actions)

    play_btn = _button("▶  PLAY", Vector2(0, 82), 30)
    play_btn.add_theme_stylebox_override("normal", _style_box(Color("#1d5d62"), Color("#8ce5d4"), 18, 2))
    play_btn.add_theme_stylebox_override("hover", _style_box(Color("#267a78"), Color("#c5fff1"), 18, 2))
    play_btn.pressed.connect(_on_play)
    actions.add_child(play_btn)

    var mode_hint := _label("Defense / Hunt / Dungeon", 13, HORIZONTAL_ALIGNMENT_CENTER)
    mode_hint.custom_minimum_size.y = 28
    actions.add_child(mode_hint)

    var nav := HBoxContainer.new()
    nav.add_theme_constant_override("separation", 10)
    collection_btn = _button("▦ COLLECTION", Vector2(190, 56), 17)
    shop_btn = _button("◈ SHOP", Vector2(190, 56), 17)
    settings_btn = _button("⚙ SETTINGS", Vector2(190, 56), 17)
    collection_btn.pressed.connect(_on_collection)
    shop_btn.pressed.connect(_on_shop)
    settings_btn.pressed.connect(_on_settings)
    nav.add_child(collection_btn)
    nav.add_child(shop_btn)
    nav.add_child(settings_btn)
    actions.add_child(nav)

    var footer := _label("Version 0.2.3  •  Android landscape  •  Offline local save", 11, HORIZONTAL_ALIGNMENT_CENTER)
    footer.custom_minimum_size.y = 24
    footer.add_theme_color_override("font_color", Color("#7f9bb0"))
    column.add_child(footer)

    if not GameManager.has_chosen_starter:
        play_btn.text = "★  START ADVENTURE"
        collection_btn.disabled = true
        shop_btn.disabled = true

func _build_team_preview() -> void:
    for child in starter_preview.get_children():
        child.queue_free()
    for i in range(3):
        var panel := PanelContainer.new()
        panel.custom_minimum_size = Vector2(88, 160)
        panel.add_theme_stylebox_override("panel", _style_box(Color(0.07, 0.12, 0.19, 0.88), Color("#2d455d"), 14, 1))
        starter_preview.add_child(panel)
        var box := VBoxContainer.new()
        panel.add_child(box)
        var tex := TextureRect.new()
        tex.custom_minimum_size = Vector2(64, 86)
        tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        box.add_child(tex)
        var name := "EMPTY"
        if i < GameManager.player_team.size():
            var m: Dictionary = GameManager.player_team[i]
            var path: String = m.get("icon", "")
            if ResourceLoader.exists(path):
                tex.texture = load(path)
            name = m.get("name", "?")
        box.add_child(_label("SLOT %d" % (i + 1), 10, HORIZONTAL_ALIGNMENT_CENTER))
        box.add_child(_label(name, 11, HORIZONTAL_ALIGNMENT_CENTER))

func _on_gold_changed(amount: int) -> void:
    if is_instance_valid(gold_label):
        gold_label.text = "✦ %d GOLD" % amount

func _on_play() -> void:
    AudioManager.play_sfx("button")
    if not GameManager.has_chosen_starter:
        SceneManager.go_starter_select()
    else:
        SceneManager.go_mode_select()

func _on_collection() -> void:
    AudioManager.play_sfx("button")
    if GameManager.has_chosen_starter:
        SceneManager.go_collection()

func _on_shop() -> void:
    AudioManager.play_sfx("button")
    if GameManager.has_chosen_starter:
        SceneManager.go_shop()

func _on_settings() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_settings()
