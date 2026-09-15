extends Button
class_name ShapeButton
## Simple single-color geometric button: quadrilateral or pentagon.

enum Shape { QUAD, BATTLE }
@export var shape: Shape = Shape.QUAD
@export var fill_color := Color("#B89567")
@export var border_color := Color("#B89567")
@export var pressed_color := Color("#96764F")
@export var slant := 18.0

func _ready() -> void:
    flat = true
    add_theme_color_override("font_color", Color.WHITE)
    add_theme_color_override("font_hover_color", Color.WHITE)
    add_theme_color_override("font_pressed_color", Color.WHITE)
    add_theme_color_override("font_disabled_color", Color("#FFFFFF"))
    add_theme_color_override("font_focus_color", Color.WHITE)
    add_theme_constant_override("outline_size", 0)
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
        queue_redraw()

func _draw() -> void:
    var s := size
    if s.x <= 2.0 or s.y <= 2.0:
        return
    var inset := 2.0
    var pts: PackedVector2Array
    if shape == Shape.BATTLE:
        var top_inset := min(34.0, s.x * 0.18)
        var notch := min(18.0, s.x * 0.10)
        pts = PackedVector2Array([
            Vector2(top_inset, inset),
            Vector2(s.x - top_inset, inset),
            Vector2(s.x - inset, s.y * 0.56),
            Vector2(s.x - notch, s.y - inset),
            Vector2(notch, s.y - inset),
            Vector2(inset, s.y * 0.56),
        ])
    else:
        var k := min(slant, s.y * 0.45, s.x * 0.12)
        pts = PackedVector2Array([
            Vector2(k, inset), Vector2(s.x - k, inset),
            Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
        ])
    var c := pressed_color if button_pressed else fill_color
    if is_hovered() and not disabled:
        c = c.lightened(0.07)
    if disabled:
        c = c.darkened(0.08)
    draw_colored_polygon(pts, c)
    draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), border_color, 3.0, true)
    if pts.size() > 4:
        draw_polyline(PackedVector2Array([pts[3], pts[4], pts[5], pts[0]]), border_color, 3.0, true)
