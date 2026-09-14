extends PanelContainer
class_name TeamSlot

signal swap_requested(from_index: int, to_index: int)
signal pressed_slot(index: int)

var slot_index: int = -1
var monster: Dictionary = {}
var icon_rect: TextureRect
var title_label: Label
var sub_label: Label

func _ready() -> void:
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _build_contents()

func setup(index: int, data: Dictionary) -> void:
    slot_index = index
    monster = data.duplicate(true)
    if is_node_ready():
        _build_contents()
        _refresh()

func _build_contents() -> void:
    for child in get_children():
        child.queue_free()
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    add_child(box)
    icon_rect = TextureRect.new()
    icon_rect.custom_minimum_size = Vector2(86, 86)
    icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    box.add_child(icon_rect)
    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 13)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(title_label)
    sub_label = Label.new()
    sub_label.add_theme_font_size_override("font_size", 10)
    sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(sub_label)
    _refresh()

func _refresh() -> void:
    if not is_instance_valid(title_label):
        return
    if monster.is_empty():
        title_label.text = "EMPTY SLOT"
        sub_label.text = "Drop here"
        icon_rect.texture = null
    else:
        title_label.text = monster.get("name", "Monster")
        sub_label.text = "Lv.%d • %s" % [monster.get("level", 1), monster.get("rank", "E")]
        var path: String = monster.get("icon", "")
        icon_rect.texture = load(path) if ResourceLoader.exists(path) else null

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        pressed_slot.emit(slot_index)

func _get_drag_data(_at_position: Vector2) -> Variant:
    if monster.is_empty() or slot_index < 0:
        return null
    var preview := Label.new()
    preview.text = monster.get("name", "Monster")
    preview.add_theme_font_size_override("font_size", 14)
    preview.modulate = Color("#dffcff")
    set_drag_preview(preview)
    return {"kind": "team_slot", "from": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return typeof(data) == TYPE_DICTIONARY and data.get("kind", "") == "team_slot" and int(data.get("from", -1)) != slot_index

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    swap_requested.emit(int(data.get("from", -1)), slot_index)
