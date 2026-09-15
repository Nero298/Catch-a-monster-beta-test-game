extends Control
class_name ShapeButton
## Custom polygon button with a deliberately thick, unmistakable stone frame.

signal pressed
signal mouse_entered_shape
signal mouse_exited_shape

enum Shape { RECT, LEFT_SLOPE, RIGHT_SLOPE, QUAD, BATTLE }

@export var shape: Shape = Shape.QUAD
@export var text: String = "BUTTON"
@export var fill_color := Color("#B89567")
@export var stone_dark := Color("#4B3827")
@export var stone_mid := Color("#735638")
@export var stone_light := Color("#D9C19A")
@export var hover_fill := Color("#C9A978")
@export var pressed_fill := Color("#96754D")
@export var font_size: int = 16
@export var slant: float = 28.0
@export var disabled := false

var _hovered := false
var _down := false
var _label: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    focus_mode = Control.FOCUS_NONE
    _label = Label.new()
    _label.text = text
    _label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _apply_label()
    add_child(_label)
    queue_redraw()

func _apply_label() -> void:
    if not is_instance_valid(_label):
        return
    _label.text = text
    _label.add_theme_font_size_override("font_size", font_size)
    _label.add_theme_color_override("font_color", Color.WHITE)
    _label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.72))
    _label.add_theme_constant_override("outline_size", 4)
    _label.modulate = Color(1, 1, 1, 0.45) if disabled else Color.WHITE

func set_text(value: String) -> void:
    text = value
    _apply_label()
    queue_redraw()

func set_disabled(value: bool) -> void:
    disabled = value
    _apply_label()
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if disabled:
        if event is InputEventMouseButton and not event.pressed:
            _down = false
        return
    if event is InputEventMouseMotion:
        var inside := _point_inside_polygon(event.position)
        if inside and not _hovered:
            _hovered = true
            mouse_entered_shape.emit()
        elif not inside and _hovered:
            _hovered = false
            mouse_exited_shape.emit()
        queue_redraw()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if _point_inside_polygon(event.position):
                _down = true
                queue_redraw()
                accept_event()
        else:
            var fire := _down and _point_inside_polygon(event.position)
            _down = false
            queue_redraw()
            if fire:
                pressed.emit()
                accept_event()

func _points(margin: float = 0.0) -> PackedVector2Array:
    var s := size
    var inset := margin
    if s.x <= 2.0 or s.y <= 2.0:
        return PackedVector2Array()
    var k := clampf(slant, 10.0, minf(s.y * 0.40, s.x * 0.22))
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
            # Wide top, narrower bottom: the exact inverted-trapezoid silhouette.
            var top_w := s.x * 0.13
            var bottom_w := s.x * 0.055
            return PackedVector2Array([
                Vector2(top_w, inset), Vector2(s.x - top_w, inset),
                Vector2(s.x - bottom_w, s.y - inset), Vector2(bottom_w, s.y - inset)
            ])
        Shape.QUAD:
            return PackedVector2Array([
                Vector2(k + inset, inset), Vector2(s.x - k - inset, inset),
                Vector2(s.x - inset, s.y - inset), Vector2(inset, s.y - inset)
            ])
    return PackedVector2Array()

func _centroid(points: PackedVector2Array) -> Vector2:
    if points.is_empty():
        return Vector2.ZERO
    var c := Vector2.ZERO
    for p in points:
        c += p
    return c / float(points.size())

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
        var a := pts[i]
        var b := pts[j]
        if ((a.y > p.y) != (b.y > p.y)):
            var x_at_y := (b.x - a.x) * (p.y - a.y) / maxf(0.0001, b.y - a.y) + a.x
            if p.x < x_at_y:
                inside = not inside
        j = i
    return inside

func _draw() -> void:
    if size.x <= 2.0 or size.y <= 2.0:
        return
    var outer := _points(2.0)
    var inner := _scaled_points(outer, 0.86)
    var core := _scaled_points(outer, 0.74)
    var fill := pressed_fill if _down else (hover_fill if _hovered else fill_color)

    # Thick stone mass.
    draw_colored_polygon(outer, stone_dark)
    draw_colored_polygon(inner, stone_mid)
    draw_colored_polygon(core, fill)

    # Bevel highlights/shadows on every edge.
    for i in range(outer.size()):
        var a := outer[i]
        var b := outer[(i + 1) % outer.size()]
        var edge := b - a
        var normal := Vector2(-edge.y, edge.x).normalized()
        var hi_a := a.lerp(b, 0.08) + normal * 1.5
        var hi_b := a.lerp(b, 0.74) + normal * 2.0
        var lo_a := a.lerp(b, 0.30) - normal * 2.0
        var lo_b := a.lerp(b, 0.92) - normal * 2.5
        draw_line(hi_a, hi_b, stone_light, 3.0, true)
        draw_line(lo_a, lo_b, stone_dark, 3.0, true)

    # Corner chips / cracks: makes the border read as carved stone rather than a flat UI outline.
    var c := _centroid(outer)
    for i in range(outer.size()):
        var p := outer[i]
        var dir := (p - c).normalized()
        var tangent := Vector2(-dir.y, dir.x)
        var q := p - dir * 7.0
        draw_line(q, q - dir * 9.0 + tangent * 4.0, stone_light, 2.0, true)
        draw_line(q + tangent * 2.0, q + tangent * 7.0, stone_dark, 2.0, true)
