extends Control

@onready var container: HBoxContainer = $HBox
@onready var confirm_btn: Button = $ConfirmBtn
@onready var desc_label: Label = $DescLabel

var selected_id: String = ""
var starter_ids: Array = []

func _ready() -> void:
	starter_ids = DataManager.get_starters()
	confirm_btn.disabled = true
	confirm_btn.pressed.connect(_on_confirm)
	_build_cards()

func _build_cards() -> void:
	for child in container.get_children():
		child.queue_free()
	for id in starter_ids:
		var m = DataManager.monsters[id]
		var vbox = VBoxContainer.new()
		vbox.custom_minimum_size = Vector2(220, 300)
		# Icon
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(96, 96)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path = m.get("icon", m.get("sprite", ""))
		if icon_path and ResourceLoader.exists(icon_path):
			tex_rect.texture = load(icon_path)
		vbox.add_child(tex_rect)
		# Button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 120)
		btn.text = "%s\n%s | Rank %s\nHP %d  ATK %d  DEF %d  SPD %d" % [m.name, m.element, m.rank, m.base_hp, m.base_atk, m.base_def, m.base_spd]
		btn.add_theme_font_size_override("font_size", 16)
		var style = StyleBoxFlat.new()
		var col = m.color if m.color is Color else Color(0.3, 0.3, 0.35)
		style.bg_color = col.darkened(0.35)
		style.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("normal", style)
		btn.pressed.connect(_on_select.bind(id, m))
		vbox.add_child(btn)
		container.add_child(vbox)

func _on_select(id: String, m: Dictionary) -> void:
	selected_id = id
	confirm_btn.disabled = false
	var sk_names: Array = []
	for sid in m.get("skills", []):
		var sk = DataManager.get_skill(sid)
		sk_names.append(sk.get("name", sid) if sk else sid)
	desc_label.text = "%s\n\nHP %d · ATK %d · DEF %d · SPD %d\nSkills: %s" % [
		m.get("description", ""), m.base_hp, m.base_atk, m.base_def, m.base_spd, ", ".join(sk_names)
	]
	AudioManager.play_sfx("button")

func _on_confirm() -> void:
	if selected_id == "":
		return
	AudioManager.play_sfx("button")
	GameManager.set_starter(selected_id)
	SceneManager.go_main_menu()
