extends Control
## Tan pixel shop on the same forest background as the game hub.

const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"
const ITEMS := [
    {"id":"basic","name":"Basic Ball","price":25,"icon":"res://assets/sprites/ui/basic_ball.png","kind":"ball"},
    {"id":"great","name":"Great Ball","price":80,"icon":"res://assets/sprites/ui/great_ball.png","kind":"ball"},
    {"id":"ultra","name":"Ultra Ball","price":200,"icon":"res://assets/sprites/ui/ultra_ball.png","kind":"ball"},
    {"id":"meat","name":"Monster Meat","price":40,"icon":"","kind":"item"},
    {"id":"premium_food","name":"Premium Food","price":120,"icon":"","kind":"item"},
    {"id":"fire_stone","name":"Fire Stone","price":200,"icon":"","kind":"item"},
]

var coin_label: Label
var gem_label: Label
var status_label: Label

func _ready() -> void:
    _build()
    if not GameManager.gold_changed.is_connected(_on_money_changed):
        GameManager.gold_changed.connect(_on_money_changed)
    if GameManager.has_signal("gems_changed") and not GameManager.gems_changed.is_connected(_on_money_changed):
        GameManager.gems_changed.connect(_on_money_changed)

func _bg() -> void:
    var bg := TextureRect.new()
    bg.texture = load(BG_TEXTURE) if ResourceLoader.exists(BG_TEXTURE) else null
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var shade := ColorRect.new()
    shade.color = Color(0.05, 0.035, 0.02, 0.45)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

func _build() -> void:
    for c in get_children(): c.queue_free()
    _bg()
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(980, 620)
    card.add_theme_stylebox_override("panel", UITheme.panel_tan(0.98))
    center.add_child(card)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    card.add_child(root)

    var header := PanelContainer.new()
    header.custom_minimum_size.y = 54
    header.add_theme_stylebox_override("panel", UITheme.flat(UITheme.TAN_DARK, UITheme.TAN, 6, 2))
    root.add_child(header)
    var hv := HBoxContainer.new()
    header.add_child(hv)
    var title := UITheme.label("SHOP", 24)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hv.add_child(title)
    var close := UITheme.button("BACK", Vector2(100, 38), 14)
    close.pressed.connect(_on_back)
    hv.add_child(close)

    var money := HBoxContainer.new()
    money.alignment = BoxContainer.ALIGNMENT_CENTER
    money.add_theme_constant_override("separation", 30)
    root.add_child(money)
    coin_label = UITheme.label("COIN %d" % GameManager.gold, 17)
    gem_label = UITheme.label("GEM %d" % GameManager.gems, 17)
    money.add_child(coin_label)
    money.add_child(gem_label)

    var grid := GridContainer.new()
    grid.columns = 3
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    root.add_child(grid)

    for it in ITEMS:
        var cell := PanelContainer.new()
        cell.custom_minimum_size = Vector2(300, 190)
        cell.add_theme_stylebox_override("panel", UITheme.flat(Color(UITheme.TAN.r, UITheme.TAN.g, UITheme.TAN.b, 0.75), UITheme.TAN, 6, 2))
        grid.add_child(cell)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        cell.add_child(v)
        var icon_box := CenterContainer.new()
        icon_box.custom_minimum_size.y = 72
        v.add_child(icon_box)
        if str(it.icon) != "" and ResourceLoader.exists(it.icon):
            var tex := TextureRect.new()
            tex.custom_minimum_size = Vector2(64, 64)
            tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            tex.texture = load(it.icon)
            icon_box.add_child(tex)
        var name := UITheme.label(str(it.name), 15)
        v.add_child(name)
        var price := UITheme.label("%d COIN" % int(it.price), 13)
        v.add_child(price)
        var buy := UITheme.button("BUY", Vector2(120, 40), 15)
        buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        buy.pressed.connect(_on_buy.bind(it))
        v.add_child(buy)

    status_label = UITheme.label("", 13)
    status_label.custom_minimum_size.y = 30
    root.add_child(status_label)

func _on_buy(it: Dictionary) -> void:
    AudioManager.play_sfx("button")
    var price := int(it.price)
    if not GameManager.spend_gold(price):
        status_label.text = "Not enough coin."
        return
    match str(it.kind):
        "ball":
            GameManager.balls[str(it.id)] = GameManager.balls.get(str(it.id), 0) + 1
        _:
            GameManager.add_item(str(it.id), 1)
    SaveManager.save_game()
    _refresh_money()
    status_label.text = "%s purchased." % it.name

func _refresh_money() -> void:
    coin_label.text = "COIN %d" % GameManager.gold
    gem_label.text = "GEM %d" % GameManager.gems
func _on_money_changed(_v: int) -> void: _refresh_money()
func _on_back() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_main_menu()
