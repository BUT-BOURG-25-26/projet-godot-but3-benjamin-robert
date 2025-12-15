extends CharacterBody2D

# --- RÉFÉRENCES ---
var player_reference : Node2D = null
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area : Area2D = $InteractionArea

# --- RESSOURCE ET STATS ---
@export var type : Resource:
	set(value):
		type = value
		if is_inside_tree(): _apply_stats()

var health : float
var max_health : float
var damage : float
var speed : float
var role : int # 0=Melee, 1=Ranged, 2=Healer

# --- LOGIQUE ---
var attack_cooldown : float = 1.0
var attack_timer : float = 0.0
# Liste pour le Healer
var allies_in_range : Array = [] 
var is_player_in_area : bool = false # Pour le Ranger

func _ready() -> void:
	add_to_group("allied_enemies")
	
	if type: _apply_stats()
	
	# Trouver le joueur
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_reference = players[0]
	
	# Connexion des signaux
	if not interaction_area.body_entered.is_connected(_on_interaction_area_entered):
		interaction_area.body_entered.connect(_on_interaction_area_entered)
	if not interaction_area.body_exited.is_connected(_on_interaction_area_exited):
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _apply_stats() -> void:
	if not type: return
	$AnimatedSprite2D.sprite_frames = type.sprite_frames
	health = type.health
	max_health = type.health
	damage = type.damage
	role = type.role
	speed = type.speed

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_reference):
		return

	# --- 1. DÉPLACEMENT ---
	var should_move = true
	var dist_to_player = global_position.distance_to(player_reference.global_position)
	
	if role == 1: # RANGED
		if is_player_in_area: should_move = false
	elif role == 0: # MELEE
		if dist_to_player < 10.0: should_move = false

	if should_move:
		var direction = (player_reference.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		_handle_animation(direction)
	else:
		velocity = Vector2.ZERO
		_handle_animation(Vector2.ZERO)

	# --- 2. ACTIONS ---
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		_try_action()

func _try_action():
	match role:
		0: # MELEE
			if global_position.distance_to(player_reference.global_position) < 30.0:
				_attack_player("Melee")
		1: # RANGED
			if is_player_in_area:
				_attack_player("Ranged")
		2: # HEALER
			_healer_behavior()

func _attack_player(attack_type: String):
	print(attack_type + " attack!")
	if player_reference.has_method("take_damage"):
		player_reference.take_damage(damage)
	attack_timer = 0.0

# --- COMPORTEMENT HEALER (RYTHMIQUE) ---
func _healer_behavior():
	# Si personne autour, on reset le timer quand même pour ne pas spammer le CPU
	if allies_in_range.is_empty(): 
		attack_timer = 0.0
		return
	
	print("--- HEALER PULSE ---")
	print("J'ai ", allies_in_range.size(), " alliés potentiels.")

	var healed_someone = false
	
	for ally in allies_in_range:
		if not is_instance_valid(ally): continue
		
		print(" -> Check : ", ally.name, " | HP: ", ally.health, "/", ally.max_health)

		if ally.has_method("heal"):
			if ally.health < ally.max_health:
				print("    !!! SOIN LANCÉ !!!")
				ally.heal(damage)
				healed_someone = true
			else:
				print("    ... PV Max.")
		else:
			print("    ERREUR: Pas de fonction heal().")
	
	if healed_someone:
		print(">> Soin effectué.")
	else:
		print(">> Rien à soigner pour ce cycle.")
	
	# Le Healer a "joué son tour", il doit attendre le cooldown
	attack_timer = 0.0 
	print("-------------------")

# --- GESTION AREA 2D ---
func _on_interaction_area_entered(body):
	# RANGER
	if role == 1 and body == player_reference:
		is_player_in_area = true
		
	# HEALER
	if role == 2 and body != self:
		print("ZONE ENTREE: ", body.name)
		if body.is_in_group("allied_enemies"):
			print(" -> Allié ajouté.")
			allies_in_range.append(body)
		else:
			print(" -> Ignoré (Pas un allié).")

func _on_interaction_area_exited(body):
	# RANGER
	if role == 1 and body == player_reference:
		is_player_in_area = false
		
	# HEALER
	if role == 2 and body in allies_in_range:
		print("ZONE SORTIE: ", body.name)
		allies_in_range.erase(body)

# --- ANIMATION & RECEPTION SOIN ---
func _handle_animation(direction: Vector2) -> void:
	if direction.length() > 0:
		if sprite.animation != "Walking": sprite.play("Walking")
		if direction.x != 0: sprite.flip_h = direction.x < 0
	else:
		if sprite.animation != "Idle": sprite.play("Idle")

func heal(amount: float) -> void:
	health += amount
	if health > max_health: health = max_health
	print(">>> ", name, " REÇOIT SOIN. PV: ", health)
