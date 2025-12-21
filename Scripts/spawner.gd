extends Node2D

@export var player : CharacterBody2D

# --- Variables pour l'Ennemi Normal (Vagues) ---
@export_group("Enemy Waves Data")
@export var regular_enemy_scene : PackedScene 
# IMPORTANT : Cette liste doit contenir un nombre PAIR d'ennemis pour fonctionner (2, 4, 6...)
# [Melee1, Ranged1, Melee2, Ranged2, ...]
# Le script suppose que les index PAIRS (0, 2, 4...) sont des Mêlées et les IMPAIRS (1, 3, 5...) des Rangers.
@export var regular_enemy_types : Array[Enemy] 

# --- NOUVEAU : Paramètres de Difficulté Progressive ---
@export_group("Difficulty Scaling")
# Le temps (en minutes) pour atteindre le palier d'ennemis le plus fort.
@export var time_to_max_tier_minutes : float = 5.0

# Nombre d'ennemis qui spawnent par seconde au tout début (temps 0).
@export var base_spawns_per_second : float = 0.5

# Combien d'ennemis SUPPLÉMENTAIRES par seconde sont ajoutés chaque minute.
@export var spawn_growth_per_minute : float = 0.5

# --- VARIABLE POUR LE RATIO ---
# Probabilité (de 0.0 à 1.0) que l'ennemi choisi soit le premier de la paire (type Mêlée).
# 0.65 signifie 65% de chance d'avoir un Mêlée, et donc 35% de chance d'avoir un Ranger.
@export_range(0.0, 1.0) var melee_spawn_ratio : float = 0.65

# --- MODIFICATION DES DISTANCES ---
@export var min_distance : float = 900 # Plus grand que la moitié de la largeur de l'écran
@export var max_distance : float = 1400 # Pour ne pas qu'ils spawnent trop loin non plus

# --- Variables pour le Boss ---
@export_group("Boss Data")
@export var boss_scene : PackedScene 
@export var boss_data_list : Array[Enemy] 

# --- VARIABLES D'ÉTAT BOSS ---
var _current_boss_index: int = 0 
var _current_spawn_amount: int = 1 

var distance : float = 400 

@onready var timer_container = $UI/HBoxContainer
@onready var warning_label = $UI/WarningLabel

# Variable pour suivre le temps total exact pour les calculs de difficulté
var total_seconds_elapsed : float = 0.0

var minute : int:
	set(value):
		if value != minute:
			minute = value
			if has_node("%Minute"):
				%Minute.text = str(value)
			_animate_new_minute()
		
var second : int:
	set(value):
		second = value
		if second >= 60:
			second -= 60
			minute += 1
		
		# Mise à jour du temps total
		total_seconds_elapsed = (minute * 60.0) + second
			
		if has_node("%Second"):
			%Second.text = str(second).lpad(2,'0')
			
		_animate_heartbeat()
		
func _ready() -> void:
	if warning_label:
		warning_label.visible = false
	
	# Petite sécurité pour vérifier les paires
	if regular_enemy_types.size() % 2 != 0:
		push_warning("ATTENTION Spawner : regular_enemy_types a un nombre impair. Le système par paire sera déséquilibré à la fin.")

# --- ANIMATIONS DU TIMER ---
func _animate_heartbeat() -> void:
	if not timer_container: return
	timer_container.pivot_offset = Vector2(timer_container.size.x / 2, timer_container.size.y) 
	var tween = create_tween() 
	tween.tween_property(timer_container, "scale", Vector2(1.05, 1.05), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(timer_container, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if second > 54:
		timer_container.modulate = Color(1, 0.5, 0.5) 
	else:
		timer_container.modulate = Color.WHITE

func _animate_new_minute() -> void:
	if not timer_container: return
	var tween = create_tween()
	tween.tween_property(timer_container, "modulate", Color(1, 0, 0), 0.2) 
	tween.parallel().tween_property(timer_container, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(timer_container, "modulate", Color.WHITE, 0.5)
	tween.parallel().tween_property(timer_container, "scale", Vector2(1.0, 1.0), 0.3)

# --- Logique des Timers ---

# Timer principal : Exécuté chaque seconde
func _on_timer_timeout() -> void:
	second += 1
	GameManager.update_time(minute, second)
	
	# --- LOGIQUE D'APPARITION PROGRESSIVE ---
	_spawn_progressive_wave()


# --- FONCTIONS DE SPAWN ---

func _spawn_progressive_wave() -> void:
	if regular_enemy_types.is_empty() or not regular_enemy_scene: return

	# CALCUL DE LA DENSITÉ (Combien d'ennemis ?)
	var minutes_float = total_seconds_elapsed / 60.0
	var target_spawn_count = base_spawns_per_second + (minutes_float * spawn_growth_per_minute)
	
	# Gestion des nombres à virgule pour la quantité
	var count_int = int(target_spawn_count) 
	var count_fraction = target_spawn_count - count_int 
	
	if randf() < count_fraction:
		count_int += 1
	
	# BOUCLE DE SPAWN
	for i in range(count_int):
		# Pour chaque ennemi, on choisit son type selon la probabilité temporelle
		var selected_index = _get_probabilistic_enemy_index()
		spawn_enemy_by_index(get_random_position(), selected_index)


# C'est le cœur du système de probabilité par paliers
func _get_probabilistic_enemy_index() -> int:
	# Nombre de paires (tiers) disponibles. Ex: 6 ennemis = 3 paires (indices 0, 1 et 2)
	var max_tier_index = (regular_enemy_types.size() / 2) - 1
	if max_tier_index < 0: return 0 # Sécurité
	
	# Temps cible en secondes
	var time_to_max_seconds = time_to_max_tier_minutes * 60.0
	
	# On calcule notre progression actuelle sur une échelle de 0 à max_tier_index
	var current_tier_float = remap(total_seconds_elapsed, 0.0, time_to_max_seconds, 0.0, float(max_tier_index))
	
	# On bloque pour ne pas dépasser le dernier tiers
	current_tier_float = clamp(current_tier_float, 0.0, float(max_tier_index))
	
	# On détermine les deux tiers entre lesquels on se trouve
	var tier_low = floor(current_tier_float) # Le palier inférieur
	var tier_high = ceil(current_tier_float) # Le palier supérieur
	
	# La partie décimale détermine la chance de choisir le palier supérieur
	var chance_for_high = current_tier_float - tier_low
	
	var final_tier = tier_low
	if randf() < chance_for_high:
		final_tier = tier_high
		
	# Maintenant qu'on a le palier (ex: Palier 1), on convertit en index de liste (ex: index 2 ou 3)
	# Palier 0 -> index base 0. Palier 1 -> index base 2.
	var base_index = int(final_tier) * 2
	
	# --- MODIFICATION ICI : Utilisation du ratio ---
	# On utilise la variable melee_spawn_ratio au lieu de 0.5
	# Si randf() (entre 0 et 1) est inférieur à 0.65, on prend le premier de la paire (Mêlée)
	if randf() < melee_spawn_ratio:
		return base_index
	else:
		# Sinon on prend le deuxième (Ranger)
		return min(base_index + 1, regular_enemy_types.size() - 1)


# Nouvelle fonction utilitaire pour spawner un index précis
func spawn_enemy_by_index(pos: Vector2, idx: int):
	var enemy_instance = regular_enemy_scene.instantiate()
	enemy_instance.type = regular_enemy_types[idx] # On utilise l'index choisi
	enemy_instance.position = pos
	enemy_instance.player_reference = player
	get_tree().current_scene.add_child(enemy_instance)

# --- Fonctions Utilitaires ---
func get_random_position() -> Vector2:
	var angle = randf() * 2 * PI
	var random_dist = randf_range(min_distance, max_distance)
	
	return player.global_position + Vector2(cos(angle), sin(angle)) * random_dist

# --- Logique de spawn du Boss ---
func spawn_specific_boss(pos: Vector2, boss_data: Enemy):
	if boss_scene == null:
		push_error("ERREUR: 'boss_scene' n'est pas assignée.")
		return
	var boss_instance = boss_scene.instantiate()
	boss_instance.type = boss_data 
	boss_instance.position = pos
	boss_instance.player_reference = player
	get_tree().current_scene.add_child(boss_instance)

func _on_timer_boss_timeout() -> void:
	if boss_data_list.is_empty(): return
	_trigger_warning_animation()
	var boss_data_to_spawn: Enemy = boss_data_list[_current_boss_index]
	print("BOSS ALERT! Spawning Boss (Index: ", _current_boss_index, " | Amount: ", _current_spawn_amount, ")")
	for i in range(_current_spawn_amount):
		spawn_specific_boss(get_random_position(), boss_data_to_spawn)
	_current_boss_index += 1
	if _current_boss_index >= boss_data_list.size():
		print("--- FIN DU CYCLE DE BOSS. Quantité augmentée ---")
		_current_boss_index = 0
		_current_spawn_amount += 1
		
# --- ANIMATION D'ALERTE ---
func _trigger_warning_animation() -> void:
	if not warning_label: return
	$Alarm.play()
	var max_opacity = 0.6
	warning_label.visible = true
	warning_label.modulate.a = 0.0 
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.pivot_offset = warning_label.size / 2
	var tween = create_tween()
	tween.parallel().tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.3).from(Vector2(2.0, 2.0)).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(warning_label, "modulate:a", max_opacity, 0.2)
	var yellow_transp = Color.YELLOW
	yellow_transp.a = max_opacity
	var red_transp = Color.RED
	red_transp.a = max_opacity
	for i in range(4): 
		tween.tween_property(warning_label, "modulate", yellow_transp, 0.2)
		tween.tween_property(warning_label, "modulate", red_transp, 0.2)
	tween.tween_property(warning_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(warning_label.hide)
