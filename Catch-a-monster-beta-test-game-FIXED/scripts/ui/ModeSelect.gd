extends Control

@onready var defense_btn: Button = $VBox/DefenseBtn
@onready var hunt_btn: Button = $VBox/HuntBtn
@onready var dungeon_btn: Button = $VBox/DungeonBtn
@onready var collection_btn: Button = $VBox/CollectionBtn
@onready var shop_btn: Button = $VBox/ShopBtn
@onready var back_btn: Button = $BackBtn

func _ready() -> void:
	if defense_btn:
		defense_btn.pressed.connect(_on_defense)
	if hunt_btn:
		hunt_btn.pressed.connect(_on_hunt)
	if dungeon_btn:
		dungeon_btn.pressed.connect(_on_dungeon)
	if collection_btn:
		collection_btn.pressed.connect(func(): SceneManager.go_collection())
	if shop_btn:
		shop_btn.pressed.connect(func(): SceneManager.go_shop())
	if back_btn:
		back_btn.pressed.connect(func(): SceneManager.go_main_menu())

func _on_defense() -> void:
	GameManager.set_mode(GameManager.GameMode.DEFENSE)
	GameManager.difficulty = "Normal"
	AudioManager.play_sfx("button")
	SceneManager.go_combat()

func _on_hunt() -> void:
	GameManager.set_mode(GameManager.GameMode.HUNT)
	AudioManager.play_sfx("button")
	SceneManager.go_hunt_select()

func _on_dungeon() -> void:
	AudioManager.play_sfx("button")
	SceneManager.go_dungeon_select()
