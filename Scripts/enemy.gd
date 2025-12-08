extends CharacterBody2D

@export var player_reference : CharacterBody2D
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@export var enemy : Enemy  # Référence à la ressource Enemy

var is_moving : bool = true  # Permet de contrôler si l'ennemi peut se déplacer

# (Possibilité de les ajoutés dans la ressource pour une meilleure personnalisation)
var attack_cooldown : float = 1.0  # Délai entre les attaques
var attack_timer : float = 0.0  # Timer pour gérer le cooldown des attaques

# Variables pour l'ennemi
var health : float
var max_health : float
var damage : float
var speed : float
var role : Enemy.Role  # Référence l'énumération Role, cette fois via Enemy

# Quand on définit le type d'ennemi
var type : Enemy:
	set(value):
		type = value
		$AnimatedSprite2D.sprite_frames = value.sprite_frames
		health = value.health  # Récupère la santé depuis la ressource
		damage = value.damage  # Récupère les dégâts depuis la ressource
		role = value.role  # Récupère le rôle depuis la ressource Enemy
		speed = value.speed # Récupère la vitesse depuis la ressource

func _ready() -> void:
	# Initialisation si nécessaire pour s'assurer que health, damage et role sont bien définis
	health = type.health
	max_health = type.health
	damage = type.damage
	role = type.role  # Récupère le rôle depuis la ressource Enemy

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_reference):
		return
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
		elif distance_to_player <= 50:
			is_moving = false
	# Pour les ennemis "melee", ils continuent de se déplacer jusqu'à la portée de l'attaque
	elif role == Enemy.Role.MELEE:
		# Si l'ennemi est trop loin (plus de 2), il se rapproche
		if distance_to_player > 2:
			is_moving = true
			direction = (player_reference.position - position).normalized()
		# Si l'ennemi est à portée de mêlée (2 ou moins), il peut attaquer
		elif distance_to_player <= 2:
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
	if position.distance_to(player_reference.position) < 2:  # Portée de l'attaque
		attack_timer += delta  # Incrémente le timer du cooldown
		if attack_timer >= attack_cooldown:  # Vérifie si le cooldown est écoulé
			_attack_melee()
			attack_timer = 0.0  # Réinitialise le timer après l'attaque

# Attaque de mêlée
func _attack_melee():
	print("Melee attack on player")
	if player_reference.has_method("take_damage"):
		player_reference.take_damage(damage) # Inflige les dégâts au joueur

# Comportement Ranged : Attaque à distance
func _ranged_behavior(delta: float):
	# Si le joueur est dans la portée optimale, on peut attaquer
	var distance_to_player = position.distance_to(player_reference.position)
	if distance_to_player <= 80:
		attack_timer += delta  # Incrémente le timer du cooldown
		if attack_timer >= attack_cooldown:  # Vérifie si le cooldown est écoulé
			_attack_ranged()
			attack_timer = 0.0  # Réinitialise le timer après l'attaque


# Attaque à distance
func _attack_ranged():
	print("Ranged attack on player")
	if player_reference.has_method("take_damage"):
		player_reference.take_damage(damage)  # Inflige les dégâts au joueur

# Comportement Healer : Soigner les alliés proches
func _healer_behavior():
	for ally in get_tree().get_nodes_in_group("allied_enemies"):
		# il ne se soigne pas lui-même
		if ally == self: continue
		
		if position.distance_to(ally.position) < 100:
			_heal_ally(ally)

func _heal_ally(ally: CharacterBody2D):
	if ally.has_method("heal"):
		print("Healing ally")
		ally.heal(damage) # "damage" sert de puissance de soin ici

# Fonction pour recevoir du soin (appelée par un autre Healer)
func heal(amount: float) -> void:
	health += amount
	if health > max_health:
		health = max_health
	print("Enemy healed! Current HP: ", health)
