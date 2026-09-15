extends Control
## Main hub. The geometry intentionally follows the supplied 14-zone blueprint.
## 10/9/11/12/13/14 are fixed in the upper rail; 1/2/3/4/5/6 in the lower rail;
## 7 is the open center; 8 is the small left-side Farm panel.

const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"
const BASE_SIZE := Vector2(1280, 720)
const TAN := Color("#B89567")
const STONE := Color("#6F563B")
const TAN_LIGHT := Color("#C7A879")
const TAN_DARK := Color("#96764F")
const WHITE := Color.WHITE

var layout_root: Control
var hp_zone: ShapeButton
var mana_zone: ShapeButton
var coin_zone: ShapeButton
var gem_zone: ShapeButton
var coming_panel: PanelContainer
var coming_label: Label
var title_label: Label

func _ready() -> void:
    _build_ui()
    _refresh_stats()
    if not GameManager.gold_changed.is_connected(_refresh_stats):
        GameManager.gold_changed.connect(_refresh_stats)
    if GameManager.has_signal("gems_changed") and not GameManager.gems_changed.is_connected(_on_gems_changed):
        GameManager.gems_changed.connect(_on_gems_changed)
    if GameManager.has_signal("castle_hp_changed") and not GameManager.castle_hp_changed.is_connected(_on_castle_changed):
        GameManager.castle_hp_changed.connect(_on_castle_changed)
    AudioManager.play_bgm("menu")
    if not GameManager.has_chosen_starter:
        await get_tree().create_timer(0.15).timeout
        SceneManager.go_starter_select()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_instance_valid(layout_root):
        _layout_root()

func _background() -> void:
    var bg := TextureRect.new()
    bg.texture = load(BG_TEXTURE) if ResourceLoader.exists(BG_TEXTURE) else null
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    var shade := ColorRect.new()
    shade.color = Color(0.06, 0.04, 0.02, 0.34)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

func _build_ui() -> void:
    for c in get_children():
        c.free()
    _background()

    layout_root = Control.new()
    layout_root.name = "Exact14ZoneLayout"
    layout_root.size = BASE_SIZE
    add_child(layout_root)
    _layout_root()

    # ----- ZONE 7: open centre / background -----
    title_label = _label("CATCH A MONSTER", 30)
    title_label.position = Vector2(340, 272)
    title_label.size = Vector2(600, 42)
    layout_root.add_child(title_label)
    var mode := _label("TOWER DEFENSE", 17)
    mode.position = Vector2(425, 311)
    mode.size = Vector2(430, 30)
    layout_root.add_child(mode)
    var hint := _label("BATTLE is the main mode", 13)
    hint.position = Vector2(430, 343)
    hint.size = Vector2(420, 28)
    layout_root.add_child(hint)

    # ----- TOP RAIL: 10 / 9 / 11 / 12 / 13 / 14 -----
    hp_zone = _zone("TEAM HP\n0 / 0", ShapeButton.Shape.RIGHT_SLOPE, 18)
    mana_zone = _zone("MANA\n0", ShapeButton.Shape.RIGHT_SLOPE, 15)
    coin_zone = _zone("COIN\n0", ShapeButton.Shape.RECT, 18)
    gem_zone = _zone("GEM\n0", ShapeButton.Shape.LEFT_SLOPE, 18)
    var hunter := _zone("HUNTER", ShapeButton.Shape.QUAD, 16)
    var dungeon := _zone("DUNGEON", ShapeButton.Shape.LEFT_SLOPE, 16)

    _place(hp_zone, Rect2(16, 14, 356, 68))
    _place(mana_zone, Rect2(16, 82, 356, 48))
    _place(coin_zone, Rect2(372, 14, 290, 68))
    _place(gem_zone, Rect2(662, 14, 214, 68))
    _place(hunter, Rect2(876, 14, 174, 96))
    _place(dungeon, Rect2(1050, 14, 214, 96))

    # ----- ZONE 8: Farm, intentionally compact -----
    var farm := _zone("FARM", ShapeButton.Shape.RECT, 16)
    _place(farm, Rect2(16, 142, 180, 126))
    farm.pressed.connect(func(): _coming_soon("Farm"))

    # ----- BOTTOM RAIL: 1 / 2 / 3 / 4 / 5 / 6 -----
    var settings := _zone("SETTINGS", ShapeButton.Shape.RECT, 14)
    var team := _zone("TEAM", ShapeButton.Shape.RECT, 16)
    var shop := _zone("SHOP", ShapeButton.Shape.RIGHT_SLOPE, 16)
    var battle := _zone("BATTLE", ShapeButton.Shape.BATTLE, 22)
    var index := _zone("INDEX", ShapeButton.Shape.LEFT_SLOPE, 15)
    var evolution := _zone("EVOLUTION", ShapeButton.Shape.LEFT_SLOPE, 15)

    _place(settings, Rect2(16, 610, 170, 94))
    _place(team, Rect2(186, 610, 188, 94))
    _place(shop, Rect2(374, 610, 178, 94))
    _place(battle, Rect2(512, 585, 256, 119))
    _place(index, Rect2(768, 610, 178, 94))
    _place(evolution, Rect2(946, 610, 318, 94))

    settings.pressed.connect(_on_settings)
    team.pressed.connect(_on_team)
    shop.pressed.connect(_on_shop)
    battle.pressed.connect(_on_battle)
    index.pressed.connect(func(): _coming_soon("Index"))
    evolution.pressed.connect(func(): _coming_soon("Evolution"))
    hunter.pressed.connect(func(): _coming_soon("Hunter"))
    dungeon.pressed.connect(func(): _coming_soon("Dungeon"))

    _build_coming_soon_overlay()

func _zone(text: String, shape: ShapeButton.Shape, font_size := 15) -> ShapeButton:
    var b := ShapeButton.new()
    b.text = text
    b.shape = shape
    b.fill_color = TAN
    b.border_color = STONE
    b.highlight_color = TAN_LIGHT
    b.pressed_color = TAN_DARK
    b.add_theme_font_size_override("font_size", font_size)
    b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    layout_root.add_child(b)
    return b

func _place(node: Control, rect: Rect2) -> void:
    node.position = rect.position
    node.size = rect.size

func _label(text: String, size := 15) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", WHITE)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

func _layout_root() -> void:
    if not is_instance_valid(layout_root):
        return
    var viewport := size
    var s := minf(viewport.x / BASE_SIZE.x, viewport.y / BASE_SIZE.y)
    layout_root.scale = Vector2.ONE * s
    layout_root.position = (viewport - BASE_SIZE * s) * 0.5

func _team_hp_text() -> String:
    var cur := 0
    var mx := 0
    for m in GameManager.player_team:
        if typeof(m) == TYPE_DICTIONARY:
            mx += int(m.get("max_hp", m.get("hp", 0)))
            cur += int(m.get("hp", m.get("max_hp", 0)))
    return "%d / %d" % [cur, mx] if mx > 0 else "0 / 0"

func _mana_text() -> String:
    var total_mp := 0
    for m in GameManager.player_team:
        if typeof(m) == TYPE_DICTIONARY:
            total_mp += int(40 + int(m.get("level", 1)) * 6 + int(m.get("spd", 10)) * 1.5)
    return str(total_mp)

func _refresh_stats(_unused := 0) -> void:
    if is_instance_valid(hp_zone): hp_zone.text = "TEAM HP\n%s" % _team_hp_text()
    if is_instance_valid(mana_zone): mana_zone.text = "MANA\n%s" % _mana_text()
    if is_instance_valid(coin_zone): coin_zone.text = "COIN\n%s" % GameManager.gold
    if is_instance_valid(gem_zone): gem_zone.text = "GEM\n%s" % GameManager.gems

func _on_gems_changed(_v: int) -> void:
    _refresh_stats()

func _on_castle_changed(_cur: int, _max_hp: int) -> void:
    _refresh_stats()

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
    coming_panel.add_theme_stylebox_override("panel", _flat(Color(0.04, 0.03, 0.02, 0.82), STONE, 0, 4))
    add_child(coming_panel)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    coming_panel.add_child(center)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(430, 205)
    card.add_theme_stylebox_override("panel", _flat(TAN, STONE, 8, 4))
    center.add_child(card)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 10)
    card.add_child(v)
    v.add_child(_label("COMING SOON", 28))
    coming_label = _label("", 15)
    coming_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    coming_label.custom_minimum_size.y = 70
    v.add_child(coming_label)
    var ok := ShapeButton.new()
    ok.text = "OK"
    ok.shape = ShapeButton.Shape.QUAD
    ok.fill_color = TAN
    ok.border_color = STONE
    ok.highlight_color = TAN_LIGHT
    ok.pressed_color = TAN_DARK
    ok.custom_minimum_size = Vector2(150, 48)
    ok.add_theme_font_size_override("font_size", 16)
    ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    ok.pressed.connect(func(): coming_panel.visible = false)
    v.add_child(ok)

func _flat(bg: Color, border: Color, radius := 8, width := 3) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = border
    box.set_border_width_all(width)
    box.set_corner_radius_all(radius)
    box.content_margin_left = 12
    box.content_margin_right = 12
    box.content_margin_top = 10
    box.content_margin_bottom = 10
    return box

func _coming_soon(feature_name: String) -> void:
    AudioManager.play_sfx("button")
    if is_instance_valid(coming_label):
        coming_label.text = "%s is coming soon.\nTower Defense is the current focus." % feature_name
    if is_instance_valid(coming_panel):
        coming_panel.visible = true
