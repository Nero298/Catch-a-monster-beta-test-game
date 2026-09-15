extends Control
## Main hub: fixed 14-zone layout. TD is the only active game mode for now.

const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"
const TAN := Color("#B89567")
const TAN_DARK := Color("#96764F")
const WHITE := Color.WHITE

var coin_label: Label
var gem_label: Label
var hp_label: Label
var mana_label: Label
var coming_panel: PanelContainer
var coming_label: Label
var team_preview: HBoxContainer

func _ready() -> void:
    _build_ui()
    _refresh_stats()
    if not GameManager.gold_changed.is_connected(_on_gold):
        GameManager.gold_changed.connect(_on_gold)
    if GameManager.has_signal("gems_changed") and not GameManager.gems_changed.is_connected(_on_gems):
        GameManager.gems_changed.connect(_on_gems)
    if GameManager.has_signal("castle_hp_changed") and not GameManager.castle_hp_changed.is_connected(_on_team_state_changed):
        GameManager.castle_hp_changed.connect(_on_team_state_changed)
    AudioManager.play_bgm("menu")
    if not GameManager.has_chosen_starter:
        await get_tree().create_timer(0.15).timeout
        SceneManager.go_starter_select()

func _panel(alpha := 0.90) -> StyleBoxFlat:
    return UITheme.flat(Color(TAN.r, TAN.g, TAN.b, alpha), TAN, 8, 3)

func _label(text: String, size := 15) -> Label:
    return UITheme.label(text, size)

func _button(text: String, size := 15) -> Button:
    return UITheme.button(text, Vector2(0, 44), size)

func _shape_button(text: String, shape: ShapeButton.Shape, size := 15) -> ShapeButton:
    var b := ShapeButton.new()
    b.text = text
    b.shape = shape
    b.custom_minimum_size = Vector2(0, 86)
    b.add_theme_font_size_override("font_size", size)
    return b

func _background(parent: Control) -> void:
    var bg := TextureRect.new()
    if ResourceLoader.exists(BG_TEXTURE):
        bg.texture = load(BG_TEXTURE)
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(bg)
    var shade := ColorRect.new()
    shade.color = Color(0.05, 0.035, 0.02, 0.42)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(shade)

func _build_ui() -> void:
    for c in get_children():
        c.queue_free()
    _background(self)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 6)
    margin.add_child(root)

    # TOP: 10 / 11 / 12 / 13 / 14
    var top := HBoxContainer.new()
    top.custom_minimum_size.y = 68
    top.add_theme_constant_override("separation", 6)
    root.add_child(top)
    var z10 := _stat_card("10", "TEAM HP")
    hp_label = z10.get_node("VBox/Value") as Label
    top.add_child(z10)
    var z11 := _stat_card("11", "COIN")
    coin_label = z11.get_node("VBox/Value") as Label
    top.add_child(z11)
    var z12 := _stat_card("12", "GEM")
    gem_label = z12.get_node("VBox/Value") as Label
    top.add_child(z12)

    var hunter := _button("HUNTER", 17)
    hunter.custom_minimum_size.x = 180
    hunter.pressed.connect(func(): _coming_soon("Hunter"))
    top.add_child(hunter)
    var dungeon := _button("DUNGEON", 17)
    dungeon.custom_minimum_size.x = 180
    dungeon.pressed.connect(func(): _coming_soon("Dungeon"))
    top.add_child(dungeon)

    # MIDDLE: 9/8 | 7 | (open)
    var middle := HBoxContainer.new()
    middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
    middle.add_theme_constant_override("separation", 8)
    root.add_child(middle)

    var left := VBoxContainer.new()
    left.custom_minimum_size.x = 155
    left.add_theme_constant_override("separation", 8)
    middle.add_child(left)

    var mana_card := PanelContainer.new()
    mana_card.custom_minimum_size.y = 88
    mana_card.add_theme_stylebox_override("panel", _panel(0.94))
    left.add_child(mana_card)
    var mv := VBoxContainer.new()
    mana_card.add_child(mv)
    mv.add_child(_label("MANA", 13))
    mana_label = _label("", 16)
    mana_label.name = "ManaValue"
    mv.add_child(mana_label)
    mv.add_child(_label("TEAM RESOURCE", 10))

    var farm := _button("FARM", 18)
    farm.custom_minimum_size.y = 0
    farm.size_flags_vertical = Control.SIZE_EXPAND_FILL
    farm.pressed.connect(func(): _coming_soon("Farm"))
    left.add_child(farm)

    # 7 Background / stage area.
    var stage := PanelContainer.new()
    stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stage.add_theme_stylebox_override("panel", UITheme.flat(Color(0.05, 0.03, 0.02, 0.24), TAN, 10, 2))
    middle.add_child(stage)
    var stage_box := VBoxContainer.new()
    stage_box.alignment = BoxContainer.ALIGNMENT_CENTER
    stage_box.add_theme_constant_override("separation", 10)
    stage.add_child(stage_box)
    stage_box.add_child(_label("CATCH A MONSTER", 34))
    var td := _label("TOWER DEFENSE", 18)
    stage_box.add_child(td)
    stage_box.add_child(_label("TEAM → choose up to 3 monsters", 13))
    team_preview = HBoxContainer.new()
    team_preview.alignment = BoxContainer.ALIGNMENT_CENTER
    team_preview.add_theme_constant_override("separation", 10)
    stage_box.add_child(team_preview)
    _fill_team_preview()
    stage_box.add_child(_label("BATTLE is the main mode", 13))

    # BOTTOM: 1 / 2 / 3 / 4 / 5 / 6
    var bottom := HBoxContainer.new()
    bottom.custom_minimum_size.y = 96
    bottom.add_theme_constant_override("separation", 6)
    root.add_child(bottom)

    var z1 := _button("SETTINGS", 15)
    z1.pressed.connect(_on_settings)
    bottom.add_child(z1)
    var z2 := _button("TEAM", 16)
    z2.pressed.connect(_on_team)
    bottom.add_child(z2)
    var z3 := _button("SHOP", 16)
    z3.pressed.connect(_on_shop)
    bottom.add_child(z3)
    var z4 := _shape_button("BATTLE", ShapeButton.Shape.BATTLE, 24)
    z4.custom_minimum_size.x = 300
    z4.pressed.connect(_on_battle)
    bottom.add_child(z4)
    var z5 := _button("INDEX", 15)
    z5.pressed.connect(func(): _coming_soon("Index"))
    bottom.add_child(z5)
    var z6 := _button("EVOLUTION", 15)
    z6.pressed.connect(func(): _coming_soon("Evolution"))
    bottom.add_child(z6)

    _build_coming_soon_overlay()

func _stat_card(zone: String, title: String) -> PanelContainer:
    var p := PanelContainer.new()
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    p.add_theme_stylebox_override("panel", _panel(0.92))
    var v := VBoxContainer.new()
    v.name = "VBox"
    p.add_child(v)
    var t := _label(title, 11)
    t.name = "Title"
    v.add_child(t)
    var value := _label("0", 17)
    value.name = "Value"
    v.add_child(value)
    return p

func _fill_team_preview() -> void:
    for c in team_preview.get_children():
        c.queue_free()
    for i in range(3):
        var card := PanelContainer.new()
        card.custom_minimum_size = Vector2(90, 112)
        card.add_theme_stylebox_override("panel", _panel(0.90))
        team_preview.add_child(card)
        var v := VBoxContainer.new()
        card.add_child(v)
        var tex := TextureRect.new()
        tex.custom_minimum_size = Vector2(58, 58)
        tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        v.add_child(tex)
        var nm := "EMPTY"
        if i < GameManager.player_team.size():
            var m: Dictionary = GameManager.player_team[i]
            nm = str(m.get("name", "Monster"))
            var path := str(m.get("icon", ""))
            if ResourceLoader.exists(path):
                tex.texture = load(path)
        var n := _label(nm, 11)
        v.add_child(n)

func _team_hp_text() -> String:
    var cur := 0
    var mx := 0
    for m in GameManager.player_team:
        if typeof(m) == TYPE_DICTIONARY:
            mx += int(m.get("max_hp", m.get("hp", 0)))
            cur += int(m.get("hp", m.get("max_hp", 0)))
    if mx <= 0:
        return "0 / 0"
    return "%d / %d" % [cur, mx]

func _refresh_stats() -> void:
    if is_instance_valid(coin_label): coin_label.text = str(GameManager.gold)
    if is_instance_valid(gem_label): gem_label.text = str(GameManager.gems)
    if is_instance_valid(hp_label): hp_label.text = _team_hp_text()
    if is_instance_valid(mana_label):
        var total_mp := 0
        for m in GameManager.player_team:
            if typeof(m) == TYPE_DICTIONARY:
                total_mp += int(40 + int(m.get("level", 1)) * 6 + int(m.get("spd", 10)) * 1.5)
        mana_label.text = str(total_mp)
    if is_instance_valid(team_preview):
        _fill_team_preview()

func _on_gold(_value: int) -> void: _refresh_stats()
func _on_gems(_value: int) -> void: _refresh_stats()
func _on_team_state_changed(_cur: int, _max_hp: int) -> void: _refresh_stats()

func _on_settings() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_settings()
func _on_team() -> void:
    AudioManager.play_sfx("button")
    if GameManager.has_chosen_starter:
        SceneManager.go_collection()
    else:
        SceneManager.go_starter_select()
func _on_shop() -> void:
    AudioManager.play_sfx("button")
    if GameManager.has_chosen_starter:
        SceneManager.go_shop()
    else:
        SceneManager.go_starter_select()
func _on_battle() -> void:
    AudioManager.play_sfx("button")
    if not GameManager.has_chosen_starter:
        SceneManager.go_starter_select()
        return
    if GameManager.player_team.is_empty():
        _coming_soon("Open TEAM and choose at least one monster first.")
        return
    GameManager.set_mode(GameManager.GameMode.DEFENSE)
    GameManager.difficulty = "Normal"
    GameManager.recalculate_base_hp_from_team()
    SceneManager.go_combat()

func _build_coming_soon_overlay() -> void:
    coming_panel = PanelContainer.new()
    coming_panel.visible = false
    coming_panel.z_index = 100
    coming_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    coming_panel.add_theme_stylebox_override("panel", UITheme.flat(Color(0.08, 0.05, 0.03, 0.88), TAN, 0, 0))
    add_child(coming_panel)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    coming_panel.add_child(center)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(430, 210)
    card.add_theme_stylebox_override("panel", _panel(0.98))
    center.add_child(card)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 12)
    card.add_child(v)
    v.add_child(_label("COMING SOON", 28))
    coming_label = _label("", 15)
    coming_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    v.add_child(coming_label)
    var ok := _button("OK", 16)
    ok.custom_minimum_size = Vector2(130, 46)
    ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    ok.pressed.connect(func(): coming_panel.visible = false)
    v.add_child(ok)

func _coming_soon(feature_name: String) -> void:
    AudioManager.play_sfx("button")
    if is_instance_valid(coming_label):
        coming_label.text = "%s is coming soon.\nTower Defense is the current focus." % feature_name
    if is_instance_valid(coming_panel):
        coming_panel.visible = true
