extends RefCounted
class_name UITheme
## Shared pixel UI style matching shop sample: tan panel, green header, green BUY buttons.
## Assets: Kenney Pixel UI (CC0) + Kenney RPG UI bars (CC0)

const PANEL_TAN := "res://assets/sprites/ui/theme/panels/panel_tan.png"
const PANEL_BROWN := "res://assets/sprites/ui/theme/panels/panel_brown.png"
const PANEL_INSET := "res://assets/sprites/ui/theme/panels/panelInset_beige.png"
const BTN_GREEN := "res://assets/sprites/ui/theme/buttons/btn_green.png"
const BTN_GREEN_P := "res://assets/sprites/ui/theme/buttons/btn_green_pressed.png"
const BTN_BLUE := "res://assets/sprites/ui/theme/buttons/btn_blue.png"
const BTN_BLUE_P := "res://assets/sprites/ui/theme/buttons/btn_blue_pressed.png"
const BTN_RED := "res://assets/sprites/ui/theme/buttons/btn_red.png"
const BTN_RED_P := "res://assets/sprites/ui/theme/buttons/btn_red_pressed.png"
const BTN_YELLOW := "res://assets/sprites/ui/theme/buttons/btn_yellow.png"
const BTN_YELLOW_P := "res://assets/sprites/ui/theme/buttons/btn_yellow_pressed.png"
const BTN_GREY := "res://assets/sprites/ui/theme/buttons/btn_grey.png"
const BTN_GREY_P := "res://assets/sprites/ui/theme/buttons/btn_grey_pressed.png"
const BTN_LONG_BEIGE := "res://assets/sprites/ui/theme/buttons/buttonLong_beige.png"
const BTN_LONG_BEIGE_P := "res://assets/sprites/ui/theme/buttons/buttonLong_beige_pressed.png"
const ICON_COIN := "res://assets/sprites/ui/theme/icons/icon_coin.png"
const ICON_GEM := "res://assets/sprites/ui/theme/icons/icon_gem.png"
const ICON_HP := "res://assets/sprites/ui/theme/icons/icon_hp.png"
const ICON_MP := "res://assets/sprites/ui/theme/icons/icon_mp.png"
const ICON_SETTINGS := "res://assets/sprites/ui/theme/icons/icon_settings.png"
const ICON_BATTLE := "res://assets/sprites/ui/theme/icons/icon_battle.png"

static func tex_style(path: String, margin := 8) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	if ResourceLoader.exists(path):
		sb.texture = load(path)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	return sb

static func panel_tan(margin := 10) -> StyleBoxTexture:
	return tex_style(PANEL_TAN if ResourceLoader.exists(PANEL_TAN) else PANEL_BROWN, margin)

static func panel_header_green() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("6fad7b")
	box.border_color = Color("3d6b45")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

static func flat_fallback(bg: Color, border: Color, radius := 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

static func buy_button(min_size: Vector2 = Vector2(72, 32)) -> Button:
	var b := Button.new()
	b.text = "BUY"
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	if ResourceLoader.exists(BTN_GREEN):
		b.add_theme_stylebox_override("normal", tex_style(BTN_GREEN, 6))
		b.add_theme_stylebox_override("hover", tex_style(BTN_GREEN, 6))
		b.add_theme_stylebox_override("pressed", tex_style(BTN_GREEN_P if ResourceLoader.exists(BTN_GREEN_P) else BTN_GREEN, 6))
	else:
		b.add_theme_stylebox_override("normal", flat_fallback(Color("5a9e66"), Color("2d5a35")))
	return b

static func themed_button(text: String, color_key: String = "green", min_size: Vector2 = Vector2(100, 40), font_size := 15) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	var npath := BTN_GREEN
	var ppath := BTN_GREEN_P
	match color_key:
		"blue":
			npath = BTN_BLUE; ppath = BTN_BLUE_P
		"red":
			npath = BTN_RED; ppath = BTN_RED_P
		"yellow":
			npath = BTN_YELLOW; ppath = BTN_YELLOW_P
		"grey":
			npath = BTN_GREY; ppath = BTN_GREY_P
		"beige":
			npath = BTN_LONG_BEIGE; ppath = BTN_LONG_BEIGE_P
	if ResourceLoader.exists(npath):
		b.add_theme_stylebox_override("normal", tex_style(npath, 8))
		b.add_theme_stylebox_override("hover", tex_style(npath, 8))
		b.add_theme_stylebox_override("pressed", tex_style(ppath if ResourceLoader.exists(ppath) else npath, 8))
	else:
		b.add_theme_stylebox_override("normal", flat_fallback(Color("5a9e66"), Color("2d5a35")))
	return b

static func icon_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

static func make_icon(path: String, size: Vector2 = Vector2(28, 28)) -> TextureRect:
	var t := TextureRect.new()
	t.custom_minimum_size = size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex = icon_texture(path)
	if tex:
		t.texture = tex
	return t

static func hp_bar_styles() -> Array:
	## Returns [bg StyleBoxFlat, fill StyleBoxFlat] for ProgressBar
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.12, 0.12, 0.9)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.25, 0.28)
	fill.set_corner_radius_all(3)
	return [bg, fill]

static func mp_bar_styles() -> Array:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.12, 0.2, 0.9)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 0.45, 0.95)
	fill.set_corner_radius_all(3)
	return [bg, fill]
