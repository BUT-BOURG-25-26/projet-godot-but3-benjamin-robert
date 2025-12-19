class_name Player
extends CharacterBody2D

@export var speed: float = 400.0
@export var knockback_force: float = 600.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var tilemap: TileMap = get_parent().get_node("map")
@onready var healthbar = $Healthbar
@onready var hitbox: Area2D = $Hitbox
@onready var invincibility_timer: Timer = $InvincibilityTimer

# --- AUDIO XP ---
@onready var pitch_timer = $PitchResetTimer
var current_pitch: float = 1.0

# --- RANGED ATTACK ---
@export var projectile_scene : PackedScene
@export var projectile_data : Resource
@export var fire_rate : float = 1 #(0.2 = très vite, 1.0 = lent)
var current_fire_timer : float = 0.0

# -----------------------------
# INPUTS (JOYSTICKS)
# -----------------------------
var move_input: Vector2 = Vector2.ZERO      # joystick déplacement
var attack_input: Vector2 = Vector2.ZERO    # joystick attaque

# -----------------------------
# STATS
# -----------------------------
@export var max_health: float = 100.0
@export var damage: float = 10

var health: float
var is_dead := false
var is_attacking := false
var is_hurt := false
var is_invincible := false

# -----------------------------
# ANIMATION / DIRECTION
# -----------------------------
var current_animation := "Idle"
var last_direction: Vector2 = Vector2.RIGHT

# -----------------------------
# MAP LIMITS
# -----------------------------
var min_x: float
var max_x: float
var min_y: float
var max_y: float


func _ready() -> void:
	add_to_group("player")

	animated_sprite.animation_finished.connect(_on_animation_finished)
	invincibility_timer.timeout.connect(_on_invincibility_timeout)

	health = max_health
	healthbar.init_health(health, max_health)

	_setup_map_limits()
	pitch_timer.timeout.connect(_on_pitch_reset)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_hurt:
		velocity = velocity.move_toward(Vector2.ZERO, 1500 * delta)
		move_and_slide()
		return

	if is_invincible and not is_hurt:
		animated_sprite.modulate.a = 0.5 + 0.3 * sin(Time.get_ticks_msec() * 0.02)

	# -----------------------------
	# ATTAQUE CLAVIER (DEBUG)
	# -----------------------------
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		attack()

	# -----------------------------
	# MOUVEMENT (JOYSTICK + CLAVIER)
	# -----------------------------
	var input_vector := move_input

	if current_fire_timer > 0:
		current_fire_timer -= delta
	
	if input_vector == Vector2.ZERO:
		input_vector = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)

	if input_vector.length() > 0.0:
		last_direction = input_vector
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
		animated_sprite.flip_h = input_vector.x < 0.0 if input_vector.x != 0 else animated_sprite.flip_h
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_handle_animation()


# -----------------------------
# ANIMATIONS
# -----------------------------
func _handle_animation() -> void:
	if is_hurt:
		if current_animation != "Hurt":
			current_animation = "Hurt"
			animated_sprite.play("Hurt")
		return

	if is_attacking:
		if current_animation != "Walking_slash":
			current_animation = "Walking_slash"
			animated_sprite.play("Walking_slash")
		return

	if velocity.length() > 0.0:
		if current_animation != "Walking":
			current_animation = "Walking"
			animated_sprite.play("Walking")
	else:
		if current_animation != "Idle":
			current_animation = "Idle"
			animated_sprite.play("Idle")


# -----------------------------
# ATTAQUE CORPS À CORPS
# -----------------------------
func attack() -> void:
	if is_attacking:
		return

	is_attacking = true

	hitbox.position = Vector2.ZERO
	hitbox.rotation = 0
	hitbox.scale = Vector2.ONE

	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			hitbox.position = Vector2(20, 0)
			hitbox.rotation_degrees = 0
			animated_sprite.flip_h = false
		else:
			hitbox.position = Vector2(-20, 0)
			hitbox.rotation_degrees = 180
			animated_sprite.flip_h = true
	else:
		if last_direction.y > 0:
			hitbox.position = Vector2(0, 20)
			hitbox.rotation_degrees = 90
		else:
			hitbox.position = Vector2(0, -20)
			hitbox.rotation_degrees = -90

	animated_sprite.play("Walking_slash")
	current_animation = "Walking_slash"
	$MissSword.play()

	await get_tree().process_frame

	for body in hitbox.get_overlapping_bodies():
		if body != self and body.has_method("take_damage") and body.is_in_group("enemies"): # a touché un ennemi
			body.take_damage(damage, global_position)
			$HitSword.play()

# -----------------------------
# ATTAQUE À DISTANCE
# -----------------------------
func ranged_attack(direction: Vector2) -> void:
	if is_dead: return
	
	if current_fire_timer > 0:
		return

	if not projectile_scene or not projectile_data:
		return

	var p = projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	
	if p.has_method("setup"):
		p.setup(projectile_data, direction, "enemies", self)
		
	current_fire_timer = fire_rate

# -----------------------------
# CALLBACKS
# -----------------------------
func _on_animation_finished() -> void:
	if animated_sprite.animation == "Walking_slash":
		is_attacking = false
	elif animated_sprite.animation == "Hurt":
		is_hurt = false
		animated_sprite.modulate = Color.WHITE
		current_animation = "Idle"
		animated_sprite.play("Idle")


func take_damage(amount: float, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_invincible:
		return

	health -= amount
	$HurtSound.play()

	if health <= 0:
		health = 0
		is_dead = true
		healthbar.health = 0
		_die()
		$GameOver.play()
	else:
		healthbar.health = health
		is_hurt = true
		is_invincible = true

		if source_position != Vector2.ZERO:
			var knockback_direction = (global_position - source_position).normalized()
			velocity = knockback_direction * knockback_force

		animated_sprite.modulate = Color(1, 0, 0, 0.8)
		animated_sprite.play("Hurt")
		current_animation = "Hurt"
		invincibility_timer.start()


func _on_invincibility_timeout() -> void:
	is_invincible = false
	animated_sprite.modulate = Color.WHITE


func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	healthbar.health = health


func _die() -> void:
	visible = false
	set_physics_process(false)
	set_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

# -----------------------------
# XP / LEVEL
# -----------------------------
@export var base_exp_to_next_level: int = 100
@export var exp_growth_per_level: int = 50

var current_exp: int = 0
var level: int = 1
var exp_to_next_level: int = base_exp_to_next_level


func gain_exp(amount: int) -> void:
	current_exp += amount
	print("XP +", amount, " -> ", current_exp, "/", exp_to_next_level)

	if current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level += 1
		_update_exp_curve()
		_on_level_up()


func _update_exp_curve() -> void:
	# +50 XP par niveau
	exp_to_next_level = base_exp_to_next_level + (level - 1) * exp_growth_per_level


func _on_level_up() -> void:
	print("LEVEL UP ! Niveau :", level)
	print("Prochain niveau à :", exp_to_next_level, " XP")

	var ui = get_tree().get_first_node_in_group("powerup_ui")
	if ui:
		ui.open()
	else:
		print("❌ PowerUpUI introuvable (pas dans le groupe powerup_ui ?)")


# -----------------------------
# MAP LIMITS + CAMERA
# -----------------------------
func _setup_map_limits():
	if tilemap == null or tilemap.tile_set == null:
		return

	var used_rect := tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return

	var tile_size := Vector2(tilemap.tile_set.tile_size)
	var origin_local := Vector2(used_rect.position) * tile_size
	var size_local := Vector2(used_rect.size) * tile_size
	var origin_global := tilemap.to_global(origin_local)

	min_x = origin_global.x
	min_y = origin_global.y
	max_x = origin_global.x + size_local.x
	max_y = origin_global.y + size_local.y

	camera.limit_left = int(min_x)
	camera.limit_top = int(min_y)
	camera.limit_right = int(max_x)
	camera.limit_bottom = int(max_y)


# -----------------------------
# EXP (à revoir avec corentin)
# -----------------------------
func gain_xp(amount: float) -> void:
	# Sa logique d'XP existante
	# exp_drop += amount ext... 

	$CollectSound.pitch_scale = current_pitch
	$CollectSound.play()
	
	current_pitch += 0.1
	if current_pitch > 3:
		current_pitch = 3
		
	pitch_timer.start()
	
func _on_pitch_reset() -> void:
	current_pitch = 1.0

# -----------------------------
# DEBUG / TEST (A SUPPRIMER PLUS TARD)
# -----------------------------
func _input(event: InputEvent) -> void:
	# Si on appuie sur la touche "T" du clavier
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			print("Test XP Sound !")
			gain_xp(10)
