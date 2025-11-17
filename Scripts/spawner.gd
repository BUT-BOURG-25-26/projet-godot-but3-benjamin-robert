extends Node2D

@export var player : CharacterBody2D
@export var enemy : PackedScene

var distance : float = 400 # distance d'apparition

@export var enemy_types : Array[Enemy]

var minute : int: 
	set(value):
		minute = value
		%Minute.text = str(value)
		
var second : int:
	set(value):
		second = value
		if second >= 60:
			second -= 60
			minute += 1
		%Second.text = str(second).lpad(2,'0')
	
# Apparition des ennemis
func spawn(pos: Vector2):
	var enemy_instance = enemy.instantiate()
	
	enemy_instance.type = enemy_types[min(minute, enemy_types.size()-1)] # chaque minute une vague différente d'ennemi
	enemy_instance.position = pos
	enemy_instance.player_reference = player
	
	get_tree().current_scene.add_child(enemy_instance)

# Position aléatoire calculé à partir de celle du joueur
func get_random_position() -> Vector2:
	return player.position + distance * Vector2.RIGHT.rotated(randf_range(0, 2 * PI))
	
# Apparaitre de plusieurs ennemis en meme temps
func amount(number : int = 1):
	for i in range(number):
		spawn(get_random_position())	

func _on_timer_timeout() -> void:
	second += 1
	amount(second % 10)
