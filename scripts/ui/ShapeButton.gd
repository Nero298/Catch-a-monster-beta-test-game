extends Control
class_name ShapeButton
## Custom clickable geometric button used by the hub/shop.
## It deliberately avoids the default Button theme so the polygon and stone edge are always visible.

signal pressed
signal mouse_entered_shape
signal mouse_exited_shape

enum Shape { RECT, LEFT_SLOPE, RIGHT_SLOPE, QUAD, BATTLE }

@export var shape: Shape = Shape.QUAD
@export var text: String = "BUTTON"
@export var fill_color := Color("#B89567")
@export var stone_dark := Color("#5F4933")
@export var stone_mid := Color("#806446")
@export var stone_light := Color("#D2B486")
@export var hover_fill := Color("#C7A879")
@export var pressed_fill := Color("#96764F")
@export var font_size: int = 16
@export var slant: float = 24.0

var _hovered := false
var _down := false
var _label: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    custom_minimum_size = Vector2(60, 40)
    _label = Label.new()
    _label.text = text
    _label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _label.add_theme_font_size_override("font_size", font_size)
    _label.add_theme_color_override("font_color", Color.WHITE)
    _label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
    _label.add_theme_constant_override("outline_size", 3)
    add_child(_label)
    queue_redraw()

func set_text(value: String) -> void:
    text = value
    if is_instance_valid(_label):
        _label.text = value
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _hovered = _point_inside_polygon(get_local_mouse_position())
        queue_redraw()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and _point_inside_polygon(event.position):
            _down = true
            queue_redraw()
            accept_event()
        elif not event.pressed:
            var fire := _down and _point_inside_polygon(event.position)
            _down = false
            queue_redraw()
            if fire and not disabled:
                pressed.emit()
                accept_event()

var disabled: bool = false:

func _on_mouse_enter() -> void:
    _hovered = true
    mouse_entered_shape.emit()
    queue_redraw()

func _on_mouse_exit() -> void:
    _hovered = false
    _down = false
    mouse_exited_shape.emit()
    queue_redraw()

func _mouse_inside(_event: InputEvent) -> void:
    pass

func _points(margin: float = 0.0) -> PackedVector2Array:
    var s := size
    var inset := margin
    var k := clampf(slant, 8.0, minf(s.y * 0.42, s.x * 0.20))
    match shape:
        Shape.RECT:
            return PackedVector2Array([
                Vector2(inset, inset), Vector2(s.x - inset, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
            ])
        Shape.LEFT_SLOPE:
            return PackedVector2Array([
                Vector2(k + inset, inset), Vector2(s.x - inset, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
            ])
        Shape.RIGHT_SLOPE:
            return PackedVector2Array([
                Vector2(inset, inset), Vector2(s.x - k - inset, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
            ])
        Shape.BATTLE:
            # Inverted trapezoid / pentagon, matching the supplied blueprint.
            var top_w := s.x * 0.20
            var lower_w := s.x * 0.08
            return PackedVector2Array([
                Vector2(top_w, inset), Vector2(s.x - top_w, inset),
                Vector2(s.x - lower_w, s.y - inset), Vector2(lower_w, s.y - inset)
            ])
        Shape.QUAD:
            return PackedVector2Array([
                Vector2(k + inset, inset), Vector2(s.x - k - inset, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
            ])
    return PackedVector2Array()

func _centroid(points: PackedVector2Array) -> Vector2:
    var c := Vector2.ZERO
    for p in points:
        c += p
    return c / max(1, points.size())

func _scaled_points(points: PackedVector2Array, factor: float) -> PackedVector2Array:
    var center := _centroid(points)
    var out := PackedVector2Array()
    for p in points:
        out.append(center.lerp(p, factor))
    return out

func _point_inside_polygon(p: Vector2) -> bool:
    var pts := _points(0.0)
    if pts.size() < 3:
        return false
    var inside := false
    var j := pts.size() - 1
    for i in range(pts.size()):
        var pi := pts[i]
        var pj := pts[j]
        if ((pi.y > p.y) != (pj.y > p.y)) and (p.x < (pj.x - pi.x) * (p.y - pi.y) / maxf(0.0001, pj.y - pi.y) + pi.x):
            inside = not inside
        j = i
    return inside

func _draw() -> void:
    if size.x <= 2.0 or size.y <= 2.0:
        return
    var outer := _points(1.5)
    var inner := _scaled_points(outer, 0.88)
    var core := _scaled_points(outer, 0.81)
    var fill := pressed_fill if _down else (hover_fill if _hovered else fill_color)

    # Large visible stone silhouette.
    draw_colored_polygon(outer, stone_dark)
    draw_colored_polygon(inner, stone_mid)
    draw_colored_polygon(core, fill)

    # Uneven inner highlight and dark facets to make the border visibly read as stone.
    var c := _centroid(outer)
    for i in range(outer.size()):
        var a := outer[i]
        var b := outer[(i + 1) % outer.size()]
        var q1 := a.lerp(b, 0.14)
        var q2 := a.lerp(b, 0.30)
        var q3 := a.lerp(b, 0.68)
        var q4 := a.lerp(b, 0.84)
        var normal := Vector2(-(b - a).y, (b - a).x).normalized()
        var lit := stone_light if i % 2 == 0 else stone_dark
        draw_line(q1 + normal * 1.0, q2 + normal * 2.8, lit, 2.0, true)
        draw_line(q3 + normal * 1.0, q4 + normal * 2.2, stone_dark, 2.0, true)

    # Small broken-stone chips at corners.
    for i in range(outer.size()):
        var p := outer[i]
        var dir := (p - c).normalized()
        var t := p - dir * 5.0
        draw_line(t, t - dir * 6.0 + Vector2(-dir.y, dir.x) * 3.0, stone_light, 2.0, true)
