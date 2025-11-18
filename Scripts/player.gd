class_name Player
extends CharacterBody2D

@export var speed: float = 5000.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var tilemap: TileMap = get_parent().get_node("map") # le TileMap doit s’appeler "map"

# Variables pour la santé et les dégâts
@export var health: float = 100  # Définition de la santé
@export var damage: float = 10   # Définition des dégâts

# Animation actuelle
var current_animation: String = "Idle"

var min_x: float
var max_x: float
var min_y: float
var max_y: float
var has_map_limits: bool = false

func _ready() -> void:
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


func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input_vector.length() > 0.0:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
	else:
		velocity = Vector2.ZERO

	# Animation
	if velocity.length() > 0.0:
		if current_animation != "Walking":
			current_animation = "Walking"
			animated_sprite.play("Walking")

		animated_sprite.flip_h = velocity.x < 0.0
	else:
		if current_animation != "Idle":
			current_animation = "Idle"
			animated_sprite.play("Idle")

	move_and_slide()

# Fonction pour recevoir des dégâts
func take_damage(amount: float) -> void:
	health -= amount
	print("Player health: ", health)
	if health <= 0:
		_die()

# Fonction pour gérer la mort du joueur
func _die() -> void:
	pass
