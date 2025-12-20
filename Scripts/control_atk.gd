extends Control

@export var max_radius := 80.0
@export var center_attack_radius := 20.0 

@onready var bg: Control = $Background
@onready var handle: Control = $Handle
@onready var player := get_tree().get_first_node_in_group("player")

var input_vector: Vector2 = Vector2.ZERO
var dragging := false
var finger_id := -1
var did_melee_attack := false

func _process(delta: float) -> void:
	if dragging and player:
		var dist_from_center = handle.position.distance_to(bg.size / 2 - handle.size / 2)
		
		if dist_from_center > center_attack_radius:
			player.ranged_attack(input_vector.normalized())


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			did_melee_attack = false
			_update_joystick(event.position)
		else:
			_release()

	elif event is InputEventMouseMotion and dragging:
		_update_joystick(event.position)

	elif event is InputEventScreenTouch:
		if event.pressed and finger_id == -1:
			finger_id = event.index
			did_melee_attack = false
			_update_joystick(event.position)
		elif not event.pressed and event.index == finger_id:
			_release()

	elif event is InputEventScreenDrag and event.index == finger_id:
		_update_joystick(event.position)


func _update_joystick(local_pos: Vector2):
	var center := bg.size / 2
	var offset := local_pos - center
	var distance := offset.length()

	# --- ZONE CENTRALE : MELEE ---
	if distance <= center_attack_radius:
		input_vector = Vector2.ZERO
		handle.position = center - handle.size / 2
		
		if not did_melee_attack and player and not player.is_attacking:
			player.attack()
			did_melee_attack = true
		return

	offset = offset.limit_length(max_radius)
	input_vector = offset / max_radius
	handle.position = center + offset - handle.size / 2
	


func _release():
	dragging = false
	finger_id = -1
	did_melee_attack = false
	input_vector = Vector2.ZERO
	handle.position = bg.size / 2 - handle.size / 2
