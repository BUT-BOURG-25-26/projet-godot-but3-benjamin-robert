extends Control

@export var max_radius := 80.0
@export var deadzone := 10.0

@onready var bg: Control = $Background
@onready var handle: Control = $Handle

var input_vector: Vector2 = Vector2.ZERO
var dragging := false
var finger_id := -1

@onready var player := get_tree().get_first_node_in_group("player")


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	handle.position = bg.size / 2 - handle.size / 2


func _gui_input(event):
	# --- SOURIS ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			_update_joystick(event.position)
		else:
			_reset_joystick()

	elif event is InputEventMouseMotion and dragging:
		_update_joystick(event.position)

	# --- TACTILE ---
	elif event is InputEventScreenTouch:
		if event.pressed and finger_id == -1:
			finger_id = event.index
			_update_joystick(event.position)
		elif not event.pressed and event.index == finger_id:
			_reset_joystick()

	elif event is InputEventScreenDrag and event.index == finger_id:
		_update_joystick(event.position)


func _update_joystick(local_pos: Vector2):
	var center := bg.size / 2
	var offset := local_pos - center
	var distance := offset.length()

	if distance < deadzone:
		input_vector = Vector2.ZERO
	else:
		offset = offset.limit_length(max_radius)
		input_vector = offset / max_radius

	handle.position = center + offset - handle.size / 2


func _reset_joystick():
	dragging = false
	finger_id = -1
	input_vector = Vector2.ZERO
	handle.position = bg.size / 2 - handle.size / 2


func _process(_delta):
	if player:
		player.move_input = input_vector
