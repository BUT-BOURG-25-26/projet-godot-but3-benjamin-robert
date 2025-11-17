# player.gd
class_name Player
extends CharacterBody2D

@export var speed: float = 100
@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var tilemap = get_parent().get_node("map") # TileMap est dans le même parent

# Variables pour la santé et les dégâts
@export var health: float = 100  # Définition de la santé
@export var damage: float = 10   # Définition des dégâts

# Animation actuelle
var current_animation: String = "Idle"

# Limites de la map
var min_x: float
var max_x: float
var min_y: float
var max_y: float

func _ready():
	# Calcul des limites de la TileMap
	var used_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size

	min_x = used_rect.position.x * tile_size.x
	min_y = used_rect.position.y * tile_size.y
	max_x = (used_rect.position.x + used_rect.size.x) * tile_size.x
	max_y = (used_rect.position.y + used_rect.size.y) * tile_size.y

	# Limites de la caméra
	camera.limit_left = min_x
	camera.limit_top = min_y
	camera.limit_right = max_x
	camera.limit_bottom = max_y

func _process(delta: float) -> void:
	# Entrées
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	# Normalisation du vecteur de mouvement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()

	# Calcul de la vitesse
	velocity = input_vector * speed

	# Animation
	if velocity.length() > 0:
		if current_animation != "Walking":
			current_animation = "Walking"
			animated_sprite.play("Walking")

		# Orientation horizontale
		if velocity.x > 0:
			animated_sprite.flip_h = false
		elif velocity.x < 0:
			animated_sprite.flip_h = true
	else:
		if current_animation != "Idle":
			current_animation = "Idle"
			animated_sprite.play("Idle")

	# Déplacement
	move_and_slide()

	# Bloquer le joueur aux limites de la map
	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.y = clamp(global_position.y, min_y, max_y)



# Fonction pour recevoir des dégâts
func take_damage(amount: float) -> void:
	health -= amount
	print("Player health: ", health)
	if health <= 0:
		_die()

# Fonction pour gérer la mort du joueur
func _die() -> void:
	pass
