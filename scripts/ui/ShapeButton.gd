extends Button
class_name ShapeButton
## Geometric UI button matching the 14-zone hub layout.
## The fill stays in the Tan palette; the outline is drawn as a thick stone-like edge.

enum Shape { RECT, LEFT_SLOPE, RIGHT_SLOPE, QUAD, BATTLE }

@export var shape: Shape = Shape.QUAD
@export var fill_color := Color("#B89567")
@export var border_color := Color("#6F563B")
@export var highlight_color := Color("#C7A879")
@export var pressed_color := Color("#96764F")
@export var slant := 22.0

func _ready() -> void:
    flat = true
    add_theme_color_override("font_color", Color.WHITE)
    add_theme_color_override("font_hover_color", Color.WHITE)
    add_theme_color_override("font_pressed_color", Color.WHITE)
    add_theme_color_override("font_disabled_color", Color.WHITE)
    add_theme_color_override("font_focus_color", Color.WHITE)
    add_theme_constant_override("outline_size", 0)
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    alignment = HORIZONTAL_ALIGNMENT_CENTER
    vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED or what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
        queue_redraw()

func _points() -> PackedVector2Array:
    var s := size
    var inset := 3.0
    var k := clampf(slant, 8.0, minf(s.y * 0.42, s.x * 0.18))
    var pts := PackedVector2Array()
    match shape:
        Shape.RECT:
            pts = PackedVector2Array([
                Vector2(inset, inset), Vector2(s.x - inset, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
            ])
        Shape.LEFT_SLOPE:
            pts = PackedVector2Array([
                Vector2(k, inset), Vector2(s.x - inset, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset + 1.0, s.y - inset)
            ])
        Shape.RIGHT_SLOPE:
            pts = PackedVector2Array([
                Vector2(inset, inset), Vector2(s.x - k, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
            ])
        Shape.BATTLE:
            var top := minf(s.x * 0.20, 42.0)
            var side := minf(s.x * 0.06, 20.0)
            pts = PackedVector2Array([
                Vector2(top, inset), Vector2(s.x - top, inset),
                Vector2(s.x - side, s.y * 0.46),
                Vector2(s.x * 0.73, s.y - inset),
                Vector2(s.x * 0.27, s.y - inset),
                Vector2(side, s.y * 0.46)
            ])
        _:
            pts = PackedVector2Array([
                Vector2(k, inset), Vector2(s.x - k, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
            ])
    return pts

func _draw() -> void:
    var pts := _points()
    if pts.size() < 4:
        return
    var c := pressed_color if button_pressed else fill_color
    if is_hovered() and not disabled:
        c = c.lightened(0.06)
    if disabled:
        c = c.darkened(0.03)
    draw_colored_polygon(pts, c)

    # Thick outer edge + a few short facets gives the requested stone-border feel
    # without introducing another UI colour family.
    var closed := PackedVector2Array(pts)
    closed.append(pts[0])
    draw_polyline(closed, border_color, 5.0, true)
    var inner := PackedVector2Array()
    for p in pts:
        inner.append(p + Vector2(0, 1))
    inner.append(inner[0])
    draw_polyline(inner, highlight_color, 1.5, true)

    # Pixel-like stone facet breaks on the long edges.
    for i in range(pts.size()):
        var a: Vector2 = pts[i]
        var b: Vector2 = pts[(i + 1) % pts.size()]
        var d := b - a
        var len := d.length()
        if len < 70.0:
            continue
        var n := Vector2(-d.y, d.x).normalized()
        var p := a.lerp(b, 0.38)
        var q := a.lerp(b, 0.62)
        draw_line(p + n * 1.5, p + n * 5.5, highlight_color, 2.0, true)
        draw_line(q + n * 1.5, q + n * 4.0, border_color, 2.0, true)
