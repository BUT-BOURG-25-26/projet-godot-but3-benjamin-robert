class_name Player
extends CharacterBody2D

@export var speed: float = 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var tilemap: TileMap = get_parent().get_node("map") # le TileMap doit s’appeler "map"
@onready var healthbar = $Healthbar
@onready var hitbox: Area2D = $Hitbox

# Variables pour la santé et les dégâts
@export var max_health: float = 100.0 
var health: float 
@export var damage: float = 10 
var is_dead: bool = false
var is_attacking: bool = false
var is_hurt: bool = false

# Animation actuelle
var current_animation: String = "Idle"

var min_x: float
var max_x: float
var min_y: float
var max_y: float
var has_map_limits: bool = false

func _ready() -> void:
	
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# --- INIT HEALTH ---
	health = max_health
	healthbar.init_health(health, max_health)
	
	# --- MAP SETUP ---
	_setup_map_limits()

func _physics_process(delta: float) -> void:
	if is_dead: return
	
	if is_hurt:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# GESTION DE L'INPUT D'ATTAQUE
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		attack()
	
	# MOUVEMENT
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if input_vector.length() > 0.0:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
		
		# Gestion de la direction du sprite ET de la Hitbox
		if input_vector.x != 0:
			var look_left = input_vector.x < 0.0
			animated_sprite.flip_h = look_left
			
			# On inverse la position de la hitbox pour qu'elle soit du bon côté
			# Si la hitbox est à x = 20 par défaut
			if look_left:
				hitbox.scale.x = -1 # Ou hitbox.position.x = -20
			else:
				hitbox.scale.x = 1  # Ou hitbox.position.x = 20
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# 3. ANIMATIONS
	_handle_animation()

func _handle_animation() -> void:
	# Priorité au hurt
	if is_hurt:
		if current_animation != "Hurt":
			current_animation = "Hurt"
			animated_sprite.play("Hurt")
		return
	# Si on attaque, on force l'animation d'attaque et on ignore le reste
	if is_attacking:
		if current_animation != "Walking_slash":
			current_animation = "Walking_slash"
			animated_sprite.play("Walking_slash")
		return

	# Logique standard
	if velocity.length() > 0.0:
		if current_animation != "Walking":
			current_animation = "Walking"
			animated_sprite.play("Walking")
	else:
		if current_animation != "Idle":
			current_animation = "Idle"
			animated_sprite.play("Idle")

# --- NOUVELLES FONCTIONS D'ATTAQUE ---

func attack() -> void:
	is_attacking = true
	# On lance l'animation immédiatement
	animated_sprite.play("Walking_slash")
	current_animation = "Walking_slash"
	
	# GESTION DES DÉGÂTS
	# On récupère tous les corps qui sont dans la Hitbox (Area2D)
	var bodies = hitbox.get_overlapping_bodies()
	
	for body in bodies:
		# On vérifie si ce n'est pas le joueur lui-même et si l'objet a une fonction take_damage
		if body != self and body.has_method("take_damage"):
			# On vérifie si c'est un ennemi (optionnel, via les Groupes)
			if body.is_in_group("enemies"): 
				body.take_damage(damage)
				print("Coup porté sur : ", body.name)

func _on_animation_finished() -> void:
	# Cette fonction est appelée automatiquement par le signal animation_finished
	if animated_sprite.animation == "Walking_slash":
		is_attacking = false
	elif animated_sprite.animation == "Hurt":
		is_hurt = false
		# On repasse en Idle immédiatement pour éviter un "blink"
		current_animation = "Idle"
		animated_sprite.play("Idle")

# Fonction pour recevoir des dégâts
func take_damage(amount: float) -> void:
	if is_dead: return
	
	health -= amount
	print("Player health: ", health)
	
	if health <= 0:
		health = 0
		is_dead = true
		healthbar.health = 0
		_die()
	else:
		healthbar.health = health
		is_hurt = true
		animated_sprite.play("Hurt")
		current_animation = "Hurt"

func heal(amount: float) -> void:
	health += amount
	if health > max_health:
		health = max_health
	healthbar.health = health
	print("Player healed. Health: ", health)

func _die() -> void:
	print("Le joueur est mort")
	visible = false 
	set_physics_process(false)
	set_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	# écran de game over

func _setup_map_limits():
	if tilemap == null:
		push_error("TileMap 'map' introuvable dans le parent du Player.")
		return
	
	if tilemap.tile_set == null:
		push_warning("La TileMap n'a pas de TileSet.")
		return

	var used_rect: Rect2i = tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		push_warning("TileMap vide : limites désactivées.")
		return

	var tile_size: Vector2i = tilemap.tile_set.tile_size

	# Convertir Vector2i -> Vector2 manuellement
	var tile_size_v2 = Vector2(tile_size.x, tile_size.y)
	var used_pos_v2 = Vector2(used_rect.position.x, used_rect.position.y)
	var used_size_v2 = Vector2(used_rect.size.x, used_rect.size.y)

	var origin_local: Vector2 = used_pos_v2 * tile_size_v2
	var size_local: Vector2 = used_size_v2 * tile_size_v2

	# Convertir en global
	var origin_global: Vector2 = tilemap.to_global(origin_local)

	min_x = origin_global.x
	min_y = origin_global.y
	max_x = origin_global.x + size_local.x
	max_y = origin_global.y + size_local.y

	has_map_limits = true

	# Limites cam
	camera.limit_left = int(min_x)
	camera.limit_top = int(min_y)
	camera.limit_right = int(max_x)
	camera.limit_bottom = int(max_y)
