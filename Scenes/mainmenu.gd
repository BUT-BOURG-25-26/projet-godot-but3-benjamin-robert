extends Node2D


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(str("res://Scenes/MainScene.tscn"))
	#TODO écran de chargement ?

func _ready() -> void:
	$MainMenu.play()

func _on_settings_pressed() -> void:
	$OnClick.play()
	$CenterContainer/MainButtons.visible = false
	$CenterContainer/SettingsMenu.visible = true
	#TODO Menu setting et visible false sur tous les boutons


func _on_quit_pressed() -> void:
	$OnClick.play()
	await $OnClick.finished
	get_tree().quit()

func _on_credit_pressed() -> void:
	$OnClick.play()
	await $OnClick.finished
	# TODO 
