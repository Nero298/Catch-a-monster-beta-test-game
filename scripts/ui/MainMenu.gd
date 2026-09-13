extends Control

@onready var play_btn: Button = $VBox/PlayBtn
@onready var collection_btn: Button = $VBox/CollectionBtn
@onready var shop_btn: Button = $VBox/ShopBtn
@onready var settings_btn: Button = $VBox/SettingsBtn
@onready var title: Label = $Title
@onready var gold_label: Label = $GoldLabel

func _ready() -> void:
	if play_btn:
		play_btn.pressed.connect(_on_play)
	if collection_btn:
		collection_btn.pressed.connect(_on_collection)
	if shop_btn:
		shop_btn.pressed.connect(_on_shop)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	_update_gold()
	GameManager.gold_changed.connect(func(_g): _update_gold())
	if not GameManager.has_chosen_starter and play_btn:
		play_btn.text = "Start Adventure"
	AudioManager.play_bgm("menu")

func _update_gold() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % GameManager.gold

func _on_play() -> void:
	AudioManager.play_sfx("button")
	if not GameManager.has_chosen_starter:
		SceneManager.go_starter_select()
	else:
		SceneManager.go_mode_select()

func _on_collection() -> void:
	AudioManager.play_sfx("button")
	if GameManager.has_chosen_starter:
		SceneManager.go_collection()

func _on_shop() -> void:
	AudioManager.play_sfx("button")
	if GameManager.has_chosen_starter:
		SceneManager.go_shop()

func _on_settings() -> void:
	AudioManager.play_sfx("button")
	SceneManager.go_settings()
