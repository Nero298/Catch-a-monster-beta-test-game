extends RefCounted
class_name UITheme
## Unified tan + white pixel UI. No color-coded button rainbow.

const TAN := Color("#B89567")
const TAN_DARK := Color("#96764F")
const TAN_LIGHT := Color("#C7A879")
const WHITE := Color.WHITE
const BG := Color("#15100B")

const PANEL_TAN := "res://assets/sprites/ui/theme/panels/panel_tan.png"
const ICON_COIN := "res://assets/sprites/ui/theme/icons/icon_coin.png"
const ICON_GEM := "res://assets/sprites/ui/theme/icons/icon_gem.png"
const ICON_HP := "res://assets/sprites/ui/theme/icons/icon_hp.png"
const ICON_MP := "res://assets/sprites/ui/theme/icons/icon_mp.png"

static func flat(bg: Color = TAN, border: Color = TAN, radius := 10, width := 2) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = border
    box.set_border_width_all(width)
    box.set_corner_radius_all(radius)
    box.content_margin_left = 10
    box.content_margin_right = 10
    box.content_margin_top = 8
    box.content_margin_bottom = 8
    return box

static func panel_tan(alpha := 0.96) -> StyleBoxFlat:
    return flat(Color(TAN.r, TAN.g, TAN.b, alpha), TAN, 10, 3)

static func button(text: String, min_size := Vector2(100, 44), font_size := 15) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.add_theme_font_size_override("font_size", font_size)
    b.add_theme_color_override("font_color", WHITE)
    b.add_theme_color_override("font_hover_color", WHITE)
    b.add_theme_color_override("font_pressed_color", WHITE)
    b.add_theme_stylebox_override("normal", flat(TAN, TAN, 8, 2))
    b.add_theme_stylebox_override("hover", flat(TAN_LIGHT, TAN, 8, 2))
    b.add_theme_stylebox_override("pressed", flat(TAN_DARK, TAN, 8, 2))
    return b

static func label(text: String, size := 15, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", WHITE)
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    return l

static func make_icon(path: String, size := Vector2(24, 24)) -> TextureRect:
    var t := TextureRect.new()
    t.custom_minimum_size = size
    t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if ResourceLoader.exists(path):
        t.texture = load(path)
    return t
