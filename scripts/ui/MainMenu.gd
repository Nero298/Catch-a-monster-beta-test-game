extends Control
## Main hub: fixed 16:9 composition matching the supplied 14-zone blueprint.
## Top: 10 HP / 9 MANA / 11 COIN / 12 GEM / 13 HUNTER / 14 DUNGEON
## Bottom: 1 SETTINGS / 2 TEAM / 3 SHOP / 4 BATTLE / 5 INDEX / 6 EVOLUTION
## Center 7 is background space; 8 is the compact FARM button.

const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"
const BASE_SIZE := Vector2(1536, 864)
const TAN := Color("#B89567")
const STONE_DARK := Color("#4B3827")
const STONE_MID := Color("#735638")
const STONE_LIGHT := Color("#D9C19A")

var layout_root: Control
var hp_zone: ShapeButton
var mana_zone: ShapeButton
var coin_zone: ShapeButton
var gem_zone: ShapeButton
var coming_panel: Control
var coming_label: Label

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
    shade.color = Color(0.03, 0.02, 0.01, 0.10)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

func _build_ui() -> void:
    for c in get_children():
        c.queue_free()
    _background()

    layout_root = Control.new()
    layout_root.name = "Exact14ZoneLayout"
    layout_root.size = BASE_SIZE
    add_child(layout_root)

    var title := _label("CATCH A MONSTER", 36)
    _place(title, Rect2(420, 305, 700, 48))
    layout_root.add_child(title)
    var subtitle := _label("— TOWER DEFENSE —", 20)
    _place(subtitle, Rect2(470, 353, 596, 36))
    layout_root.add_child(subtitle)

    # Top rail: 10 / 9 / 11 / 12 / 13 / 14
    hp_zone = _zone("HP\n0 / 0", ShapeButton.Shape.RIGHT_SLOPE, 19)
    mana_zone = _zone("MANA\n0", ShapeButton.Shape.RIGHT_SLOPE, 17)
    coin_zone = _zone("COIN\n0", ShapeButton.Shape.QUAD, 19)
    gem_zone = _zone("GEM\n0", ShapeButton.Shape.QUAD, 19)
    var hunter := _zone("HUNTER", ShapeButton.Shape.QUAD, 17)
    var dungeon := _zone("DUNGEON", ShapeButton.Shape.LEFT_SLOPE, 17)

    _place(hp_zone, Rect2(8, 8, 355, 62))
    _place(mana_zone, Rect2(8, 78, 230, 84))
    _place(coin_zone, Rect2(372, 8, 308, 62))
    _place(gem_zone, Rect2(688, 8, 374, 62))
    _place(hunter, Rect2(1070, 8, 220, 84))
    _place(dungeon, Rect2(1300, 8, 228, 84))

    # 8 Farm: compact, left-aligned, never a giant column.
    var farm := _zone("FARM", ShapeButton.Shape.QUAD, 17)
    _place(farm, Rect2(8, 184, 188, 112))
    farm.pressed.connect(func(): _coming_soon("Farm"))

    # Bottom rail: 1 / 2 / 3 / 4 / 5 / 6 with tiny, consistent gaps.
    var settings := _zone("SETTINGS", ShapeButton.Shape.QUAD, 16)
    var team := _zone("TEAM", ShapeButton.Shape.QUAD, 17)
    var shop := _zone("SHOP", ShapeButton.Shape.QUAD, 17)
    var battle := _zone("BATTLE", ShapeButton.Shape.BATTLE, 23)
    var index := _zone("INDEX", ShapeButton.Shape.LEFT_SLOPE, 17)
    var evolution := _zone("EVOLUTION", ShapeButton.Shape.LEFT_SLOPE, 16)

    _place(settings, Rect2(8, 773, 182, 83))
    _place(team, Rect2(198, 773, 194, 83))
    _place(shop, Rect2(400, 773, 194, 83))
    _place(battle, Rect2(602, 748, 424, 108))
    _place(index, Rect2(1036, 773, 226, 83))
    _place(evolution, Rect2(1272, 773, 256, 83))

    settings.pressed.connect(_on_settings)
    team.pressed.connect(_on_team)
    shop.pressed.connect(_on_shop)
    battle.pressed.connect(_on_battle)
    index.pressed.connect(func(): _coming_soon("Index"))
    evolution.pressed.connect(func(): _coming_soon("Evolution"))
    hunter.pressed.connect(func(): _coming_soon("Hunter"))
    dungeon.pressed.connect(func(): _coming_soon("Dungeon"))

    _build_coming_soon_overlay()
    _layout_root()

func _zone(value: String, shape_value: ShapeButton.Shape, font_size := 15) -> ShapeButton:
    var b := ShapeButton.new()
    b.shape = shape_value
    b.set_text(value)
    b.font_size = font_size
    b.fill_color = TAN
    b.stone_dark = STONE_DARK
    b.stone_mid = STONE_MID
    b.stone_light = STONE_LIGHT
    b.hover_fill = Color("#C9A978")
    b.pressed_fill = Color("#96754D")
    layout_root.add_child(b)
    return b

func _place(node: Control, rect: Rect2) -> void:
    node.position = rect.position
    node.size = rect.size

func _label(value: String, font_size := 15) -> Label:
    var l := Label.new()
    l.text = value
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.60))
    l.add_theme_constant_override("outline_size", 4)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

func _layout_root() -> void:
    if not is_instance_valid(layout_root):
        return
    var viewport := size
    if viewport.x <= 1 or viewport.y <= 1:
        return
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
    if is_instance_valid(hp_zone): hp_zone.set_text("HP\n%s" % _team_hp_text())
    if is_instance_valid(mana_zone): mana_zone.set_text("MANA\n%s" % _mana_text())
    if is_instance_valid(coin_zone): coin_zone.set_text("COIN\n%s" % GameManager.gold)
    if is_instance_valid(gem_zone): gem_zone.set_text("GEM\n%s" % GameManager.gems)

func _on_gems_changed(_v: int) -> void:
    _refresh_stats()
func _on_castle_changed(_cur: int, _max_hp: int) -> void:
    _refresh_stats()

func _on_settings() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_settings()
func _on_team() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_collection() if GameManager.has_chosen_starter else SceneManager.go_starter_select()
func _on_shop() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_shop() if GameManager.has_chosen_starter else SceneManager.go_starter_select()
func _on_battle() -> void:
    AudioManager.play_sfx("button")
    if not GameManager.has_chosen_starter:
        SceneManager.go_starter_select()
        return
    if GameManager.player_team.is_empty() and not GameManager.owned_monsters.is_empty():
        GameManager.player_team = []
        for i in range(mini(3, GameManager.owned_monsters.size())):
            GameManager.player_team.append(GameManager.owned_monsters[i].duplicate(true))
        GameManager.recalculate_base_hp_from_team()
        SaveManager.save_game()
    if GameManager.player_team.is_empty():
        _coming_soon("Open TEAM and choose at least one monster first.")
        return
    GameManager.set_mode(GameManager.GameMode.DEFENSE)
    GameManager.difficulty = "Normal"
    GameManager.recalculate_base_hp_from_team()
    SceneManager.go_combat()

func _build_coming_soon_overlay() -> void:
    coming_panel = Control.new()
    coming_panel.visible = false
    coming_panel.z_index = 100
    coming_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(coming_panel)
    var shade := ColorRect.new()
    shade.color = Color(0.02, 0.015, 0.01, 0.74)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    coming_panel.add_child(shade)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(500, 220)
    card.add_theme_stylebox_override("panel", UITheme.flat(TAN, STONE_DARK, 0, 5))
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.add_child(card)
    coming_panel.add_child(center)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    card.add_child(v)
    var title := _label("COMING SOON", 28)
    v.add_child(title)
    coming_label = _label("", 15)
    coming_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    coming_label.custom_minimum_size = Vector2(430, 78)
    v.add_child(coming_label)
    var ok := ShapeButton.new()
    ok.shape = ShapeButton.Shape.QUAD
    ok.set_text("OK")
    ok.font_size = 16
    ok.fill_color = TAN
    ok.stone_dark = STONE_DARK
    ok.stone_mid = STONE_MID
    ok.stone_light = STONE_LIGHT
    ok.custom_minimum_size = Vector2(140, 48)
    ok.size = Vector2(140, 48)
    ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    ok.pressed.connect(func(): coming_panel.visible = false)
    v.add_child(ok)

func _coming_soon(feature_name: String) -> void:
    AudioManager.play_sfx("button")
    if is_instance_valid(coming_label):
        coming_label.text = str(feature_name) + "\nThis feature is planned for a later update."
    if is_instance_valid(coming_panel):
        coming_panel.visible = true
