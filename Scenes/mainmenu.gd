extends Node2D


func _on_play_pressed() -> void:
	$OnClickStart.play()
	get_tree().change_scene_to_file(str("res://Scenes/MainScene.tscn"))

func _ready() -> void:
	$MainMenu.play()

func _on_settings_pressed() -> void:
	$OnClick.play()
	$CenterContainer/MainButtons.visible = false
	$CenterContainer/SettingsMenu.visible = true


func _on_quit_pressed() -> void:
	$OnClick.play()


func _on_credit_pressed() -> void:
	$OnClick.play()
