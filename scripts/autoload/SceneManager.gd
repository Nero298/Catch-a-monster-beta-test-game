extends Node
## Scene transitions

func change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

func go_main_menu() -> void:
	change_scene("res://scenes/menus/MainMenu.tscn")

func go_starter_select() -> void:
	change_scene("res://scenes/menus/StarterSelect.tscn")

func go_mode_select() -> void:
	change_scene("res://scenes/menus/ModeSelect.tscn")

func go_combat() -> void:
	change_scene("res://scenes/combat/CombatScene.tscn")

func go_collection() -> void:
	change_scene("res://scenes/ui/Collection.tscn")

func go_hunt_select() -> void:
	change_scene("res://scenes/menus/HuntSelect.tscn")

func go_shop() -> void:
	change_scene("res://scenes/ui/Shop.tscn")

func go_dungeon_select() -> void:
	change_scene("res://scenes/menus/DungeonSelect.tscn")

func go_settings() -> void:
	change_scene("res://scenes/ui/Settings.tscn")
