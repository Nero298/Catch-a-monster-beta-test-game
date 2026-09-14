extends Control
## Choose dungeon difficulty then start combat

func _ready() -> void:
	pass

func _on_easy() -> void:
	_start("Easy")

func _on_normal() -> void:
	_start("Normal")

func _on_hard() -> void:
	_start("Hard")

func _on_nightmare() -> void:
	_start("Nightmare")

func _start(diff: String) -> void:
	GameManager.difficulty = diff
	GameManager.set_mode(GameManager.GameMode.DUNGEON)
	AudioManager.play_sfx("button")
	SceneManager.go_combat()

func _on_back() -> void:
	SceneManager.go_mode_select()
