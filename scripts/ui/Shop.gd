extends Control
## Pixel shop UI — tan panel, green header, BUY buttons (style from sample)

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.62, 0.58, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 480)
	card.add_theme_stylebox_override("panel", UITheme.panel_tan(14))
	center.add_child(card)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	card.add_child(root)

	# Header SHOP
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UITheme.panel_header_green())
	root.add_child(header)
	var hh := HBoxContainer.new()
	header.add_child(hh)
	var title := Label.new()
	title.text = "SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	hh.add_child(title)
	var close_btn := UITheme.themed_button("X", "grey", Vector2(36, 32), 14)
	close_btn.pressed.connect(_on_back)
	hh.add_child(close_btn)

	# Items grid 2 rows x 3
	var items := [
		{"id": "basic", "name": "Basic Ball", "price": 25, "icon": "res://assets/sprites/ui/basic_ball.png", "kind": "ball"},
		{"id": "great", "name": "Great Ball", "price": 80, "icon": "res://assets/sprites/ui/great_ball.png", "kind": "ball"},
		{"id": "ultra", "name": "Ultra Ball", "price": 200, "icon": "res://assets/sprites/ui/ultra_ball.png", "kind": "ball"},
		{"id": "food", "name": "Food", "price": 40, "icon": "", "kind": "item"},
		{"id": "potion", "name": "Potion", "price": 60, "icon": "", "kind": "item"},
		{"id": "mana_drop", "name": "Mana Drop", "price": 50, "icon": "", "kind": "item"},
	]

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)

	for it in items:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(110, 120)
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		# icon box
		var icon_panel := PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(56, 56)
		icon_panel.add_theme_stylebox_override("panel", UITheme.flat_fallback(Color(0.95, 0.9, 0.75, 0.5), Color(0.6, 0.5, 0.3), 8))
		cell.add_child(icon_panel)
		var icon_box := CenterContainer.new()
		icon_panel.add_child(icon_box)
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(40, 40)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if str(it.icon) != "" and ResourceLoader.exists(it.icon):
			tex.texture = load(it.icon)
		icon_box.add_child(tex)
		# price
		var price_row := HBoxContainer.new()
		price_row.alignment = BoxContainer.ALIGNMENT_CENTER
		var coin := UITheme.make_icon(UITheme.ICON_COIN, Vector2(18, 18))
		price_row.add_child(coin)
		var pl := Label.new()
		pl.text = str(it.price)
		pl.add_theme_font_size_override("font_size", 14)
		pl.add_theme_color_override("font_color", Color(0.25, 0.2, 0.1))
		price_row.add_child(pl)
		cell.add_child(price_row)
		# BUY
		var buy := UITheme.buy_button(Vector2(80, 30))
		buy.pressed.connect(_on_buy.bind(it))
		cell.add_child(buy)
		grid.add_child(cell)

	# Footer currency
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 24)
	root.add_child(footer)
	var c_row := HBoxContainer.new()
	c_row.add_child(UITheme.make_icon(UITheme.ICON_COIN, Vector2(24, 24)))
	var cl := Label.new()
	cl.name = "CoinLabel"
	cl.text = str(GameManager.gold)
	cl.add_theme_font_size_override("font_size", 16)
	cl.add_theme_color_override("font_color", Color(0.2, 0.15, 0.05))
	c_row.add_child(cl)
	footer.add_child(c_row)
	var g_row := HBoxContainer.new()
	g_row.add_child(UITheme.make_icon(UITheme.ICON_GEM, Vector2(24, 24)))
	var gl := Label.new()
	gl.name = "GemLabel"
	gl.text = str(GameManager.gems)
	gl.add_theme_font_size_override("font_size", 16)
	gl.add_theme_color_override("font_color", Color(0.15, 0.25, 0.45))
	g_row.add_child(gl)
	footer.add_child(g_row)

	var back := UITheme.themed_button("BACK", "beige", Vector2(120, 40), 16)
	back.pressed.connect(_on_back)
	root.add_child(back)

func _refresh_money() -> void:
	var cl = find_child("CoinLabel", true, false)
	var gl = find_child("GemLabel", true, false)
	if cl:
		cl.text = str(GameManager.gold)
	if gl:
		gl.text = str(GameManager.gems)

func _on_buy(it: Dictionary) -> void:
	AudioManager.play_sfx("button")
	var price: int = int(it.price)
	if not GameManager.spend_gold(price):
		return
	match str(it.kind):
		"ball":
			GameManager.balls[it.id] = GameManager.balls.get(it.id, 0) + 1
		_:
			GameManager.add_item(str(it.id), 1)
	SaveManager.save_game()
	_refresh_money()

func _on_back() -> void:
	AudioManager.play_sfx("button")
	SceneManager.go_main_menu()
