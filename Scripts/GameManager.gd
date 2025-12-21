extends Node

# --- SIGNAUX ---
signal score_updated(new_total)

# --- VARIABLES ---
var death_screen_scene = preload("res://Scenes/deathScreen.tscn")

var total_score : float = 0
var time_str : String = "00:00"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- GESTION DU SCORE ---
func add_score(amount: float) -> void:
	total_score += amount
	score_updated.emit(total_score) 

func reset_game_data() -> void:
	total_score = 0
	score_updated.emit(total_score)

# --- GESTION DU TEMPS ---
func update_time(minutes: int, seconds: int) -> void:
	time_str = "%02d:%02d" % [minutes, seconds]

# --- GAME OVER ---
func game_over() -> void:
	# Créer l'écran de mort
	var screen = death_screen_scene.instantiate()
	
	# L'ajouter à la scène
	get_tree().current_scene.add_child(screen)
	
	#  Lui envoyer les infos (Score et Temps)
	if screen.has_method("set_data"):
		screen.set_data(total_score, time_str)
	
	# Mettre le jeu en pause
	get_tree().paused = true
