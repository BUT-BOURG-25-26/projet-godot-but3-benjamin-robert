extends CanvasLayer

const MENU_SCENE_PATH = "res://scenes/mainmenu.tscn"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func set_data(score: float, time_str: String):
	%ScoreLabel.text = "Score Final : " + str(int(score))
	%TimeLabel.text = "Temps Survécu : " + time_str

func _on_replay_button_pressed():
	$OnClick.play()
	await $OnClick.finished
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	$OnClick.play()
	await $OnClick.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE_PATH)
