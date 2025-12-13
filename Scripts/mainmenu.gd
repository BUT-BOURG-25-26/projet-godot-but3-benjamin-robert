extends Node2D


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(str("res://Scenes/MainScene.tscn"))


func _on_settings_pressed() -> void:
	$CenterContainer/MainButtons.visible = false
	$CenterContainer/SettingsMenu.visible = true
