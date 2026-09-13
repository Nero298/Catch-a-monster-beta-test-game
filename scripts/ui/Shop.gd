extends Control
## Shop: buy Balls, food, evolution stones. Upgrade Ball levels.

@onready var gold_label: Label = $VBox/GoldLabel
@onready var status_label: Label = $VBox/StatusLabel

func _ready() -> void:
	_refresh()
	GameManager.gold_changed.connect(func(_g): _refresh())

func _refresh() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % GameManager.gold
	_update_ball_buttons()

func _update_ball_buttons() -> void:
	for bid in ["basic", "great", "ultra"]:
		var path = "VBox/Balls/%sBtn" % bid.capitalize()
		if has_node(path):
			var btn = get_node(path)
			var data = DataManager.balls.get(bid, {})
			var cost = data.get("cost", 50)
			var count = GameManager.balls.get(bid, 0)
			var lvl = GameManager.ball_levels.get(bid, 1)
			btn.text = "%s x%d (Lv%d) - %dG" % [data.get("name", bid), count, lvl, cost]

func _on_buy_basic() -> void:
	_buy_ball("basic")

func _on_buy_great() -> void:
	_buy_ball("great")

func _on_buy_ultra() -> void:
	_buy_ball("ultra")

func _buy_ball(ball_id: String) -> void:
	var data = DataManager.balls.get(ball_id, {})
	var cost = data.get("cost", 50)
	if GameManager.spend_gold(cost):
		GameManager.balls[ball_id] = GameManager.balls.get(ball_id, 0) + 1
		status_label.text = "Bought 1 " + data.get("name", ball_id)
		AudioManager.play_sfx("button")
		SaveManager.save_game()
		_refresh()
	else:
		status_label.text = "Not enough Gold!"

func _on_upgrade_basic() -> void:
	_upgrade("basic")

func _on_upgrade_great() -> void:
	_upgrade("great")

func _on_upgrade_ultra() -> void:
	_upgrade("ultra")

func _upgrade(ball_id: String) -> void:
	var cost = GameManager.get_ball_upgrade_cost(ball_id)
	if GameManager.upgrade_ball(ball_id):
		status_label.text = "%s upgraded to Lv.%d!" % [ball_id.capitalize(), GameManager.ball_levels[ball_id]]
		AudioManager.play_sfx("level_up")
		_refresh()
	else:
		status_label.text = "Need %d Gold to upgrade" % cost

func _on_buy_meat() -> void:
	_buy_item("meat", 40)

func _on_buy_premium() -> void:
	_buy_item("premium_food", 120)

func _on_buy_fire_stone() -> void:
	_buy_item("fire_stone", 200)

func _on_buy_water_stone() -> void:
	_buy_item("water_stone", 200)

func _on_buy_leaf_stone() -> void:
	_buy_item("leaf_stone", 200)

func _buy_item(item_id: String, cost: int) -> void:
	if GameManager.spend_gold(cost):
		GameManager.add_item(item_id, 1)
		status_label.text = "Bought " + DataManager.items.get(item_id, {}).get("name", item_id)
		AudioManager.play_sfx("button")
		SaveManager.save_game()
		_refresh()
	else:
		status_label.text = "Not enough Gold!"

func _on_back() -> void:
	AudioManager.play_sfx("button")
	SceneManager.go_mode_select()
