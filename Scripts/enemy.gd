# enemy.gd
extends CharacterBody2D

@export var player_reference : CharacterBody2D
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

var speed : float = 75

var type : Enemy:
	set(value):
		type = value
		$AnimatedSprite2D.sprite_frames = value.sprite_frames

func _physics_process(delta: float) -> void:
	var direction = (player_reference.position - position).normalized()
	velocity = direction * speed

	# Déplacement
	move_and_collide(velocity * delta)

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
