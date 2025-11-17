extends CharacterBody2D

@export var player_reference : CharacterBody2D
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@export var enemy : Enemy  # Référence à la ressource Enemy

var is_moving : bool = true  # Permet de contrôler si l'ennemi peut se déplacer

var speed : float = 75
var attack_cooldown : float = 1.0  # Délai entre les attaques
var attack_timer : float = 0.0  # Timer pour gérer le cooldown des attaques

# Variables pour l'ennemi
var health : float
var damage : float
var role : Enemy.Role  # Référence l'énumération Role, cette fois via Enemy

# Quand on définit le type d'ennemi
var type : Enemy:
	set(value):
		type = value
		$AnimatedSprite2D.sprite_frames = value.sprite_frames
		health = value.health  # Récupère la santé depuis la ressource
		damage = value.damage  # Récupère les dégâts depuis la ressource
		role = value.role  # Récupère le rôle depuis la ressource Enemy

func _ready() -> void:
	# Initialisation si nécessaire pour s'assurer que health, damage et role sont bien définis
	health = type.health
	damage = type.damage
	role = type.role  # Récupère le rôle depuis la ressource Enemy

func _physics_process(delta: float) -> void:
	# Vérifie la distance du joueur
	var distance_to_player = position.distance_to(player_reference.position)
	var direction : Vector2 = Vector2.ZERO  # Initialisation par défaut

	# Si l'ennemi est de type "ranged" (attaque à distance) et le joueur est à la bonne distance, on arrête l'ennemi
	if role == Enemy.Role.RANGED:
		# Si le joueur est trop loin (plus de 50), l'ennemi se rapproche
		if distance_to_player > 50:
			is_moving = true
			direction = (player_reference.position - position).normalized()  # Dirige vers le joueur
		# Si le joueur est dans la portée optimale (entre 20 et 50), l'ennemi s'arrête
		elif distance_to_player >= 20 and distance_to_player <= 50:
			is_moving = false
		# Si trop proche du joueur (moins de 20), l'ennemi ne fait rien et reste immobile
		elif distance_to_player < 20:
			is_moving = false
	# Pour les ennemis "melee", ils continuent de se déplacer jusqu'à la portée de l'attaque
	elif role == Enemy.Role.MELEE:
		# Si l'ennemi est trop loin (plus de 50), il se rapproche
		if distance_to_player > 50:
			is_moving = true
			direction = (player_reference.position - position).normalized()
		# Si l'ennemi est à portée de mêlée (50 ou moins), il peut attaquer
		elif distance_to_player <= 50:
			is_moving = false

	# Si l'ennemi peut se déplacer, il se déplace
	if is_moving:
		velocity = direction * speed
		move_and_collide(velocity * delta)

	# Comportement basé sur le rôle
	match role:
		Enemy.Role.MELEE:
			_melee_behavior(delta)
		Enemy.Role.RANGED:
			_ranged_behavior(delta)
		Enemy.Role.HEALER:
			_healer_behavior()

	# Animation
	_handle_animation(direction)

func _handle_animation(direction: Vector2) -> void:
	if direction.length() > 0.1:
		if not sprite.is_playing():
			sprite.play("Walking")
	else:
		sprite.play("Idle")

	# Orientation gauche / droite
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

# Comportement Melee : Attaque en corps à corps
func _melee_behavior(delta: float):
	if position.distance_to(player_reference.position) < 50:  # Portée de l'attaque
		attack_timer += delta  # Incrémente le timer du cooldown
		if attack_timer >= attack_cooldown:  # Vérifie si le cooldown est écoulé
			_attack_melee()
			attack_timer = 0.0  # Réinitialise le timer après l'attaque

# Attaque de mêlée
func _attack_melee():
	print("Melee attack on player")
	player_reference.health -= damage  # Inflige les dégâts au joueur

# Comportement Ranged : Attaque à distance
func _ranged_behavior(delta: float):
	# Si le joueur est dans la portée optimale (entre 20 et 50 unités), on peut attaquer
	var distance_to_player = position.distance_to(player_reference.position)
	if distance_to_player >= 20 and distance_to_player <= 50:
		attack_timer += delta  # Incrémente le timer du cooldown
		if attack_timer >= attack_cooldown:  # Vérifie si le cooldown est écoulé
			_attack_ranged()
			attack_timer = 0.0  # Réinitialise le timer après l'attaque


# Attaque à distance
func _attack_ranged():
	print("Ranged attack on player")
	player_reference.health -= damage  # Inflige les dégâts au joueur

# Comportement Healer : Soigner les alliés proches
func _healer_behavior():
	# Vérifie si un ennemi allié est à portée pour être soigné
	for ally in get_tree().get_nodes_in_group("allied_enemies"):
		if position.distance_to(ally.position) < 100:  # Portée de soin
			_heal_ally(ally)

# Soigne un allié
func _heal_ally(ally: CharacterBody2D):
	print("Healing ally")
	ally.health += damage  # On utilise la variable "damage" comme montant de soin ici
