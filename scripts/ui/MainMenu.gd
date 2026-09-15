extends Control
## Main hub layout (zones 1–14). TD (Battle) is the primary mode.
## 1 Settings · 2 TEAM · 3 Shop · 4 BATTLE · 5 Index · 6 Evolution · 7 Enchant
## 8 Farm · 9 Mana · 10 Team HP · 11 Coin · 12 Gem · 13 Hunter · 14 Dungeon

const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"
const BTN_BLUE := "res://assets/sprites/ui/kenney/btn_blue.png"
const BTN_GREEN := "res://assets/sprites/ui/kenney/btn_green.png"
const BTN_YELLOW := "res://assets/sprites/ui/kenney/btn_yellow.png"
const BTN_RED := "res://assets/sprites/ui/kenney/btn_red.png"
const BTN_GREY := "res://assets/sprites/ui/kenney/btn_grey.png"
const STOCK_N := "res://assets/sprites/ui/stock/button_stock1.png"
const STOCK_H := "res://assets/sprites/ui/stock/button_stock1h.png"
const STOCK_D := "res://assets/sprites/ui/stock/button_stock1d.png"

var coin_label: Label
var gem_label: Label
var hp_label: Label
var mana_label: Label
var coming_panel: PanelContainer
var coming_label: Label

func _ready() -> void:
	_build_ui()
	_refresh_top_stats()
	if not GameManager.gold_changed.is_connected(_on_gold):
		GameManager.gold_changed.connect(_on_gold)
	if GameManager.has_signal("gems_changed") and not GameManager.gems_changed.is_connected(_on_gems):
		GameManager.gems_changed.connect(_on_gems)
	AudioManager.play_bgm("menu")
	if not GameManager.has_chosen_starter:
		# Force starter pick first time
		await get_tree().create_timer(0.15).timeout
		SceneManager.go_starter_select()

func _tex_style(path: String, margins := 10) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	if ResourceLoader.exists(path):
		sb.texture = load(path)
	sb.texture_margin_left = margins
	sb.texture_margin_right = margins
	sb.texture_margin_top = margins
	sb.texture_margin_bottom = margins
	return sb

func _flat(bg: Color, border: Color = Color.TRANSPARENT, radius := 12, bw := 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(bw)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

func _label(text: String, size: int, align := HORIZONTAL_ALIGNMENT_CENTER, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _pixel_btn(text: String, path: String, font_size := 16) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if ResourceLoader.exists(path):
		var n := _tex_style(path, 10)
		var h := _tex_style(path, 10)
		h.modulate_color = Color(1.12, 1.12, 1.18)
		var p := _tex_style(path, 10)
		p.modulate_color = Color(0.85, 0.85, 0.9)
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", h)
		b.add_theme_stylebox_override("pressed", p)
	else:
		b.add_theme_stylebox_override("normal", _flat(Color("#1a2a40"), Color("#4a7ab0"), 12, 2))
	return b

func _stock_btn(text: String, font_size := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if ResourceLoader.exists(STOCK_N):
		b.add_theme_stylebox_override("normal", _tex_style(STOCK_N, 22))
		b.add_theme_stylebox_override("hover", _tex_style(STOCK_H if ResourceLoader.exists(STOCK_H) else STOCK_N, 22))
		b.add_theme_stylebox_override("pressed", _tex_style(STOCK_D if ResourceLoader.exists(STOCK_D) else STOCK_N, 22))
	else:
		b.add_theme_stylebox_override("normal", _flat(Color("#2a5a3a"), Color("#7dff9a"), 16, 2))
	return b

func _build_ui() -> void:
	# Background
	var bg := TextureRect.new()
	if ResourceLoader.exists(BG_TEXTURE):
		bg.texture = load(BG_TEXTURE)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.72, 0.85, 0.75, 1.0)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.1, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 10)
	root.add_theme_constant_override("margin_right", 10)
	root.add_theme_constant_override("margin_top", 8)
	root.add_theme_constant_override("margin_bottom", 8)
	add_child(root)

	var main_v := VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 6)
	root.add_child(main_v)

	# ========== TOP BAR: 10 | 11 | 12 | 13 | 14 ==========
	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 64
	top.add_theme_constant_override("separation", 6)
	main_v.add_child(top)

	# 10 Team HP
	var z10 := PanelContainer.new()
	z10.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	z10.add_theme_stylebox_override("panel", _flat(Color(0.12, 0.08, 0.1, 0.92), Color("#c45c5c"), 10, 2))
	top.add_child(z10)
	var z10v := VBoxContainer.new()
	z10.add_child(z10v)
	z10v.add_child(_label("TEAM HP", 11, HORIZONTAL_ALIGNMENT_CENTER, Color("#ffb0b0")))
	hp_label = _label("0 / 0", 16, HORIZONTAL_ALIGNMENT_CENTER, Color("#ffe0e0"))
	z10v.add_child(hp_label)

	# 11 Coin
	var z11 := PanelContainer.new()
	z11.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	z11.add_theme_stylebox_override("panel", _flat(Color(0.12, 0.1, 0.05, 0.92), Color("#d4a017"), 10, 2))
	top.add_child(z11)
	var z11v := VBoxContainer.new()
	z11.add_child(z11v)
	z11v.add_child(_label("COIN", 11, HORIZONTAL_ALIGNMENT_CENTER, Color("#ffe08a")))
	coin_label = _label("0", 18, HORIZONTAL_ALIGNMENT_CENTER, Color("#fff3c0"))
	z11v.add_child(coin_label)

	# 12 Gem
	var z12 := PanelContainer.new()
	z12.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	z12.add_theme_stylebox_override("panel", _flat(Color(0.08, 0.1, 0.14, 0.92), Color("#6ec8ff"), 10, 2))
	top.add_child(z12)
	var z12v := VBoxContainer.new()
	z12.add_child(z12v)
	z12v.add_child(_label("GEM", 11, HORIZONTAL_ALIGNMENT_CENTER, Color("#a8e0ff")))
	gem_label = _label("0", 18, HORIZONTAL_ALIGNMENT_CENTER, Color("#e0f6ff"))
	z12v.add_child(gem_label)

	# 13 Hunter
	var z13 := _pixel_btn("🏹 HUNTER", BTN_BLUE, 15)
	z13.custom_minimum_size = Vector2(140, 0)
	z13.pressed.connect(func(): _coming_soon("Hunter"))
	top.add_child(z13)

	# 14 Dungeon
	var z14 := _pixel_btn("🕳 DUNGEON", BTN_RED, 15)
	z14.custom_minimum_size = Vector2(140, 0)
	z14.pressed.connect(func(): _coming_soon("Dungeon"))
	top.add_child(z14)

	# ========== MID: left rail (9) + center (8+7) ==========
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 8)
	main_v.add_child(mid)

	# Left column: 9 Mana + stage area
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size.x = 160
	left_col.add_theme_constant_override("separation", 8)
	mid.add_child(left_col)

	# 9 Mana — combat resource for skills (regen in battle; skill needs CD + MP)
	var z9 := PanelContainer.new()
	z9.custom_minimum_size.y = 90
	z9.add_theme_stylebox_override("panel", _flat(Color(0.06, 0.1, 0.18, 0.92), Color("#5a8fd4"), 10, 2))
	left_col.add_child(z9)
	var z9v := VBoxContainer.new()
	z9.add_child(z9v)
	z9v.add_child(_label("MANA", 12, HORIZONTAL_ALIGNMENT_CENTER, Color("#9ec8ff")))
	mana_label = _label("Skills use MP", 13, HORIZONTAL_ALIGNMENT_CENTER, Color("#d0e8ff"))
	z9v.add_child(mana_label)
	z9v.add_child(_label("CD ready + MP full = cast", 10, HORIZONTAL_ALIGNMENT_CENTER, Color("#8ab0c8")))

	# 8 Farm
	var z8 := _pixel_btn("🌾\nFARM", BTN_GREEN, 18)
	z8.custom_minimum_size = Vector2(0, 120)
	z8.size_flags_vertical = Control.SIZE_EXPAND_FILL
	z8.pressed.connect(func(): _coming_soon("Farm"))
	left_col.add_child(z8)

	# Center stage (7 Enchant overlay area + title)
	var center := PanelContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_stylebox_override("panel", _flat(Color(0.04, 0.08, 0.12, 0.55), Color("#3a5773"), 14, 2))
	mid.add_child(center)
	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(cv)
	cv.add_child(_label("CATCH A MONSTER", 36, HORIZONTAL_ALIGNMENT_CENTER, Color("#e8fbff")))
	cv.add_child(_label("Tower Defense is the main mode", 14, HORIZONTAL_ALIGNMENT_CENTER, Color("#9fc6dc")))
	cv.add_child(_label("Pick TEAM (max 3) → press BATTLE", 13, HORIZONTAL_ALIGNMENT_CENTER, Color("#7a9bb0")))
	# Team preview chips
	var team_row := HBoxContainer.new()
	team_row.alignment = BoxContainer.ALIGNMENT_CENTER
	team_row.add_theme_constant_override("separation", 10)
	cv.add_child(team_row)
	_fill_team_preview(team_row)
	# 7 Enchant
	var z7 := _pixel_btn("✨ ENCHANT", BTN_YELLOW, 16)
	z7.custom_minimum_size = Vector2(220, 48)
	z7.pressed.connect(func(): _coming_soon("Enchant"))
	cv.add_child(z7)

	# ========== BOTTOM BAR: 1 2 3 | 4 | 5 6 ==========
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 88
	bottom.add_theme_constant_override("separation", 6)
	main_v.add_child(bottom)

	# 1 Settings
	var z1 := _pixel_btn("⚙\nSETTINGS", BTN_GREY, 13)
	z1.custom_minimum_size = Vector2(110, 0)
	z1.pressed.connect(_on_settings)
	bottom.add_child(z1)

	# 2 TEAM
	var z2 := _pixel_btn("👥\nTEAM", BTN_BLUE, 14)
	z2.custom_minimum_size = Vector2(120, 0)
	z2.pressed.connect(_on_team)
	bottom.add_child(z2)

	# 3 Shop
	var z3 := _pixel_btn("🛒\nSHOP", BTN_YELLOW, 14)
	z3.custom_minimum_size = Vector2(110, 0)
	z3.pressed.connect(_on_shop)
	bottom.add_child(z3)

	# 4 BATTLE (main CTA)
	var z4 := _stock_btn("⚔  BATTLE", 24)
	z4.custom_minimum_size = Vector2(280, 0)
	z4.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	z4.pressed.connect(_on_battle)
	bottom.add_child(z4)

	# 5 Index
	var z5 := _pixel_btn("📖\nINDEX", BTN_BLUE, 13)
	z5.custom_minimum_size = Vector2(110, 0)
	z5.pressed.connect(func(): _coming_soon("Index"))
	bottom.add_child(z5)

	# 6 Evolution
	var z6 := _pixel_btn("🧬\nEVOLVE", BTN_RED, 13)
	z6.custom_minimum_size = Vector2(110, 0)
	z6.pressed.connect(func(): _coming_soon("Evolution"))
	bottom.add_child(z6)

	_build_coming_soon_overlay()

func _fill_team_preview(row: HBoxContainer) -> void:
	for i in range(3):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(90, 110)
		panel.add_theme_stylebox_override("panel", _flat(Color(0.07, 0.12, 0.19, 0.9), Color("#2d455d"), 10, 1))
		row.add_child(panel)
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(box)
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(64, 64)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(tex)
		var nm := "—"
		if i < GameManager.player_team.size():
			var m: Dictionary = GameManager.player_team[i]
			var path := str(m.get("icon", m.get("sprite", "")))
			if path != "" and ResourceLoader.exists(path):
				tex.texture = load(path)
			nm = str(m.get("name", "?"))
		box.add_child(_label(nm, 11, HORIZONTAL_ALIGNMENT_CENTER, Color("#e8f4ff")))

func _team_hp_text() -> String:
	var cur := 0
	var mx := 0
	for m in GameManager.player_team:
		if typeof(m) == TYPE_DICTIONARY:
			mx += int(m.get("max_hp", m.get("hp", 0)))
			cur += int(m.get("hp", m.get("max_hp", 0)))
	if mx <= 0:
		return "No team"
	return "%d / %d" % [cur, mx]

func _refresh_top_stats() -> void:
	if is_instance_valid(coin_label):
		coin_label.text = str(GameManager.gold)
	if is_instance_valid(gem_label):
		gem_label.text = str(GameManager.gems)
	if is_instance_valid(hp_label):
		hp_label.text = _team_hp_text()
	if is_instance_valid(mana_label):
		var total_mp := 0
		for m in GameManager.player_team:
			if typeof(m) == TYPE_DICTIONARY:
				var lv = int(m.get("level", 1))
				var spd = int(m.get("spd", 10))
				total_mp += int(40 + lv * 6 + spd * 1.5)
		if total_mp > 0:
			mana_label.text = "Team MP ~%d" % total_mp
		else:
			mana_label.text = "Skills use MP"

func _on_gold(_v: int) -> void:
	_refresh_top_stats()

func _on_gems(_v: int) -> void:
	_refresh_top_stats()

func _on_settings() -> void:
	AudioManager.play_sfx("button")
	SceneManager.go_settings()

func _on_team() -> void:
	AudioManager.play_sfx("button")
	if not GameManager.has_chosen_starter:
		SceneManager.go_starter_select()
		return
	# Collection = team select (cannot change team in battle)
	SceneManager.go_collection()

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
		_coming_soon("Need a team first — open TEAM and add up to 3 monsters.")
		return
	# TD main mode — base HP = sum of team max_hp
	GameManager.set_mode(GameManager.GameMode.DEFENSE)
	GameManager.difficulty = "Normal"
	GameManager.recalculate_base_hp_from_team()
	SceneManager.go_combat()

func _build_coming_soon_overlay() -> void:
	coming_panel = PanelContainer.new()
	coming_panel.visible = false
	coming_panel.z_index = 50
	coming_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coming_panel.add_theme_stylebox_override("panel", _flat(Color(0.02, 0.04, 0.08, 0.75), Color.TRANSPARENT, 0, 0))
	add_child(coming_panel)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coming_panel.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 200)
	card.add_theme_stylebox_override("panel", _flat(Color(0.08, 0.12, 0.18, 0.98), Color("#5a8ab0"), 16, 2))
	center.add_child(card)
	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 12)
	card.add_child(vv)
	vv.add_child(_label("COMING SOON", 26, HORIZONTAL_ALIGNMENT_CENTER, Color("#e8fbff")))
	coming_label = _label("This feature is not ready yet.", 15, HORIZONTAL_ALIGNMENT_CENTER, Color("#b0c8d8"))
	coming_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vv.add_child(coming_label)
	var ok := _pixel_btn("OK", BTN_BLUE, 16)
	ok.custom_minimum_size = Vector2(120, 44)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func(): coming_panel.visible = false)
	vv.add_child(ok)

func _coming_soon(feature_name: String) -> void:
	AudioManager.play_sfx("button")
	if is_instance_valid(coming_label):
		coming_label.text = "%s — coming soon.\nFocus: Tower Defense (BATTLE) first." % feature_name
	if is_instance_valid(coming_panel):
		coming_panel.visible = true
