extends Control
## Shop uses the same tan + visible-stone language as the main hub.

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

func _build() -> void:
    for c in get_children(): c.queue_free()
    var bg := TextureRect.new()
    bg.texture = load(BG_TEXTURE) if ResourceLoader.exists(BG_TEXTURE) else null
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var shade := ColorRect.new()
    shade.color = Color(0.03, 0.02, 0.01, 0.22)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(1020, 610)
    card.add_theme_stylebox_override("panel", UITheme.flat(UITheme.TAN, UITheme.STONE, 0, 5))
    center.add_child(card)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    card.add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 60
    root.add_child(header)
    var title := UITheme.label("SHOP", 28)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    var back := _shape_button("BACK", ShapeButton.Shape.LEFT_SLOPE, Vector2(130, 48), 15)
    back.pressed.connect(_on_back)
    header.add_child(back)

    var money := HBoxContainer.new()
    money.alignment = BoxContainer.ALIGNMENT_CENTER
    money.add_theme_constant_override("separation", 40)
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
        cell.custom_minimum_size = Vector2(310, 205)
        cell.add_theme_stylebox_override("panel", UITheme.flat(Color("#B89567"), UITheme.STONE, 0, 3))
        grid.add_child(cell)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        cell.add_child(v)

        var name := UITheme.label(str(it.name), 16)
        name.custom_minimum_size.y = 28
        v.add_child(name)

        var icon_box := CenterContainer.new()
        icon_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
        v.add_child(icon_box)
        if str(it.icon) != "" and ResourceLoader.exists(it.icon):
            var tex := TextureRect.new()
            tex.custom_minimum_size = Vector2(86, 86)
            tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            tex.texture = load(it.icon)
            icon_box.add_child(tex)
        else:
            var placeholder := Label.new()
            placeholder.text = ""
            placeholder.custom_minimum_size = Vector2(86, 86)
            icon_box.add_child(placeholder)

        var price := UITheme.label("%d COIN" % int(it.price), 13)
        v.add_child(price)
        var buy := _shape_button("BUY", ShapeButton.Shape.QUAD, Vector2(150, 48), 16)
        buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        buy.pressed.connect(_on_buy.bind(it))
        v.add_child(buy)

    status_label = UITheme.label("", 13)
    status_label.custom_minimum_size.y = 28
    root.add_child(status_label)

func _shape_button(value: String, shape_value: ShapeButton.Shape, min_size: Vector2, fsize: int) -> ShapeButton:
    var b := ShapeButton.new()
    b.shape = shape_value
    b.set_text(value)
    b.font_size = fsize
    b.custom_minimum_size = min_size
    b.size = min_size
    b.fill_color = UITheme.TAN
    b.stone_dark = UITheme.STONE
    b.stone_mid = Color("#806446")
    b.stone_light = Color("#D2B486")
    return b

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
    if is_instance_valid(coin_label): coin_label.text = "COIN %d" % GameManager.gold
    if is_instance_valid(gem_label): gem_label.text = "GEM %d" % GameManager.gems

func _on_money_changed(_v: int) -> void:
    _refresh_money()

func _on_back() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_main_menu()
