extends Control

@onready var container: VBoxContainer = $Scroll/VBox
@onready var back_btn: Button = $BackBtn

func _ready() -> void:
	back_btn.pressed.connect(func(): SceneManager.go_mode_select())
	_build_islands()

func _build_islands() -> void:
	for id in DataManager.islands:
		var island = DataManager.islands[id]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(400, 80)
		btn.text = "%s\nMonsters: %s" % [island.name, ", ".join(island.monsters)]
		btn.add_theme_font_size_override("font_size", 20)
		var style = StyleBoxFlat.new()
		style.bg_color = island.bg_color
		style.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("normal", style)
		btn.pressed.connect(_on_select.bind(id))
		container.add_child(btn)

func _on_select(island_id: String) -> void:
	GameManager.selected_island = island_id
	SceneManager.go_combat()
