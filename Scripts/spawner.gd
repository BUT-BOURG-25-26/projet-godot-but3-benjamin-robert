extends Node2D

@export var player : CharacterBody2D

# --- Variables pour l'Ennemi Normal (Vagues) ---
@export var regular_enemy_scene : PackedScene # Scène pour les ennemis standards (Enemy.tscn)
@export var regular_enemy_types : Array[Enemy] # Liste des ennemis de vague

# --- Variables pour le Boss ---
@export var boss_scene : PackedScene # Scène pour le Boss (Boss.tscn)
@export var boss_data_list : Array[Enemy] # Liste des différents Boss

# --- VARIABLES D'ÉTAT (Gèrent la progression du Boss) ---
var _current_boss_index: int = 0   # L'index du Boss à faire apparaître pour cette occurrence du timer
var _current_spawn_amount: int = 1 # Le nombre de fois que ce Boss doit apparaître à chaque timeout

var distance : float = 400 # distance d'apparition

var minute : int:
	set(value):
		minute = value
		if has_node("%Minute"):
			%Minute.text = str(value)
		
var second : int:
	set(value):
		second = value
		if second >= 10: # valeur de test
			second -= 10 # valeur de test
			minute += 1
		if has_node("%Second"):
			%Second.text = str(second).lpad(2,'0')

# --- Fonctions de Spawn ---

# Apparition d'un ENNEMI NORMAL
func spawn(pos: Vector2):
	# Vérification de sécurité
	if regular_enemy_scene == null:
		push_error("ERREUR: 'regular_enemy_scene' n'est pas assignée dans l'Inspector.")
		return
	if regular_enemy_types.is_empty():
		push_error("ERREUR: 'regular_enemy_types' est vide.")
		return
		
	var enemy_instance = regular_enemy_scene.instantiate()
	
	# Assigne la ressource de données basée sur la vague (minute)
	enemy_instance.type = regular_enemy_types[min(minute, regular_enemy_types.size()-1)]
	
	enemy_instance.position = pos
	enemy_instance.player_reference = player
	
	get_tree().current_scene.add_child(enemy_instance)

# Apparition d'un BOSS SPÉCIFIQUE (Prend la ressource Boss directement)
func spawn_specific_boss(pos: Vector2, boss_data: Enemy):
	# Vérifications
	if boss_scene == null:
		push_error("ERREUR: 'boss_scene' n'est pas assignée dans l'Inspector.")
		return
		
	# Instancier la scène spécifique au Boss
	var boss_instance = boss_scene.instantiate()
	
	# Assigner les propriétés
	boss_instance.type = boss_data 
	boss_instance.position = pos
	boss_instance.player_reference = player
	
	get_tree().current_scene.add_child(boss_instance)

# Position aléatoire calculé à partir de celle du joueur (inchangé)
func get_random_position() -> Vector2:
	return player.position + distance * Vector2.RIGHT.rotated(randf_range(0, 2 * PI))
	
# Apparaitre de plusieurs ennemis en meme temps (ennemis normaux) (inchangé)
func amount(number : int = 1):
	for i in range(number):
		spawn(get_random_position())	

# --- Logique des Timers ---

# Timer pour l'apparition des ennemis normaux et la progression du temps
func _on_timer_timeout() -> void:
	second += 1
	amount(second % 2) # valeur temporaire

# Logique de spawn du Boss (MODIFIÉE)
func _on_timer_boss_timeout() -> void:
	if boss_data_list.is_empty():
		push_error("ERREUR: 'boss_data_list' est vide. Impossible de faire apparaître un Boss.")
		return
	
	# Récupérer la ressource Boss à l'index actuel
	var boss_data_to_spawn: Enemy = boss_data_list[_current_boss_index]

	# Spawner le Boss, et ce, _current_spawn_amount de fois.
	print("BOSS ALERT! Spawning Boss (Index: ", _current_boss_index, " | Amount: ", _current_spawn_amount, ")")
	for i in range(_current_spawn_amount):
		spawn_specific_boss(get_random_position(), boss_data_to_spawn)
	
	# Mettre à jour l'état pour la prochaine apparition
	_current_boss_index += 1
	
	# Vérifier si on a fini le cycle complet de la liste
	if _current_boss_index >= boss_data_list.size():
		# Fin du cycle atteint : réinitialiser l'index et augmenter la quantité
		
		# Annoncer le début d'un nouveau cycle
		print("--- FIN DU CYCLE DE BOSS. Quantité augmentée à ", _current_spawn_amount + 1, " ---")
		
		_current_boss_index = 0 # Retour au premier Boss (Index 0)
		_current_spawn_amount += 1 # Augmente le nombre de Boss pour chaque prochaine apparition
