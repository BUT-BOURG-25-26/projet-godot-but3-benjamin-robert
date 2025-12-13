extends CharacterBody2D

# --- RÉFÉRENCES ---
var player_reference : Node2D = null
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area : Area2D = $InteractionArea

# --- RESSOURCE ET STATS ---
@export var type : Resource:
	set(value):
		type = value
		if is_inside_tree(): _apply_stats()

var health : float
var max_health : float
var damage : float
var speed : float
var role : int # 0=Melee, 1=Ranged, 2=Healer

# --- LOGIQUE ---
var attack_cooldown : float = 1.0
var attack_timer : float = 0.0
# Liste pour le Healer
var allies_in_range : Array = [] 
var is_player_in_area : bool = false # Pour le Ranger
var is_attacking : bool = false
var is_hurt : bool = false
var knockback_force : float = 200.0 # Force du recul subi par l'ennemi

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("allied_enemies")
	
	sprite.animation_finished.connect(_on_animation_finished)
	
	if type: _apply_stats()
	
	# Trouver le joueur
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_reference = players[0]
	
	# Connexion des signaux
	if not interaction_area.body_entered.is_connected(_on_interaction_area_entered):
		interaction_area.body_entered.connect(_on_interaction_area_entered)
	if not interaction_area.body_exited.is_connected(_on_interaction_area_exited):
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _apply_stats() -> void:
	if not type: return
	$AnimatedSprite2D.sprite_frames = type.sprite_frames
	health = type.health
	max_health = type.health
	damage = type.damage
	role = type.role
	speed = type.speed

func _physics_process(delta: float) -> void:
	if is_hurt:
		velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		if velocity.length() < 10.0:
			is_hurt = false
			velocity = Vector2.ZERO
		return
	if not is_instance_valid(player_reference):
		return

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	# --- 1. DÉPLACEMENT ---
	var should_move = true
	var dist_to_player = global_position.distance_to(player_reference.global_position)
	
	if role == 1: # RANGED
		if is_player_in_area: should_move = false
	elif role == 0: # MELEE
		if dist_to_player < 10.0: should_move = false

	if should_move:
		var direction = (player_reference.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		_handle_animation(direction)
	else:
		velocity = Vector2.ZERO
		_handle_animation(Vector2.ZERO)

	# --- 2. ACTIONS ---
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		_try_action()

func take_damage(amount: float, source_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	
	_show_damage_popup(amount)
	
	sprite.modulate = Color(1, 0, 0)
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func(): sprite.modulate = Color(1, 1, 1))
	
	if source_position != Vector2.ZERO:
		var knockback_dir = (global_position - source_position).normalized()
		velocity = knockback_dir * knockback_force
		is_hurt = true

	if health <= 0:
		_die()
		
func _show_damage_popup(amount: float) -> void:
	var label = Label.new()
	label.text = str(int(amount))
	label.z_index = 20
	
	# --- STYLE ---
	var settings = LabelSettings.new()
	settings.font_size = 24
	settings.font_color = Color.WHITE
	settings.outline_size = 6
	settings.outline_color = Color(0.8, 0, 0)
	settings.shadow_size = 4
	settings.shadow_color = Color(0, 0, 0, 0.5)
	settings.shadow_offset = Vector2(2, 2)
	label.label_settings = settings
	
	# --- POSITION ---
	var random_offset = Vector2(randf_range(-20, 20), randf_range(-10, 10))
	# Important : On ajoute le label à la scène principale
	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector2(0, -40) + random_offset
	label.pivot_offset = Vector2(20, 10)
	
	var tween = get_tree().create_tween() 
	
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	
	# Animation Scale
	label.scale = Vector2.ZERO
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.set_parallel(true)
	
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.4)
	
	# Nettoyage
	tween.chain().tween_callback(label.queue_free)
		
func _die() -> void:
	print(name + " est mort.")
	queue_free() # Supprime l'ennemi

func _try_action():
	match role:
		0: # MELEE
			if global_position.distance_to(player_reference.global_position) < 30.0:
				_attack_player("Melee")
		1: # RANGED
			if is_player_in_area:
				_attack_player("Ranged")
		2: # HEALER
			_healer_behavior()

func _attack_player(attack_type: String):
	is_attacking = true
	sprite.play("Attack")
	print(attack_type + " attack!")
	if player_reference.has_method("take_damage"):
		player_reference.take_damage(damage, global_position)
	attack_timer = 0.0

# --- COMPORTEMENT HEALER ---
func _healer_behavior():
	# Si personne autour, on reset le timer quand même pour ne pas spammer le CPU
	if allies_in_range.is_empty(): 
		attack_timer = 0.0
		return
	
	print("--- HEALER PULSE ---")
	print("J'ai ", allies_in_range.size(), " alliés potentiels.")

	var healed_someone = false
	
	for ally in allies_in_range:
		if not is_instance_valid(ally): continue
		
		print(" -> Check : ", ally.name, " | HP: ", ally.health, "/", ally.max_health)

		if ally.has_method("heal"):
			if ally.health < ally.max_health:
				print("    !!! SOIN LANCÉ !!!")
				ally.heal(damage)
				healed_someone = true
			else:
				print("    ... PV Max.")
		else:
			print("    ERREUR: Pas de fonction heal().")
	
	if healed_someone:
		print(">> Soin effectué.")
		is_attacking = true
		sprite.play("Attack")
	else:
		print(">> Rien à soigner pour ce cycle.")
	
	# Le Healer a "joué son tour", il doit attendre le cooldown
	attack_timer = 0.0 
	print("-------------------")

# --- GESTION AREA 2D ---
func _on_interaction_area_entered(body):
	# RANGER
	if role == 1 and body == player_reference:
		is_player_in_area = true
		
	# HEALER
	if role == 2 and body != self:
		print("ZONE ENTREE: ", body.name)
		if body.is_in_group("allied_enemies"):
			print(" -> Allié ajouté.")
			allies_in_range.append(body)
		else:
			print(" -> Ignoré (Pas un allié).")

func _on_interaction_area_exited(body):
	# RANGER
	if role == 1 and body == player_reference:
		is_player_in_area = false
		
	# HEALER
	if role == 2 and body in allies_in_range:
		print("ZONE SORTIE: ", body.name)
		allies_in_range.erase(body)

# --- ANIMATION & RECEPTION SOIN ---
func _handle_animation(direction: Vector2) -> void:
	if is_attacking:
		return
	if direction.length() > 0:
		if sprite.animation != "Walking": sprite.play("Walking")
		if direction.x != 0: sprite.flip_h = direction.x < 0
	else:
		if sprite.animation != "Idle": sprite.play("Idle")
		
func _on_animation_finished() -> void:
	if sprite.animation == "Attack":
		is_attacking = false
		sprite.play("Idle")

func heal(amount: float) -> void:
	health += amount
	if health > max_health: health = max_health
	print(">>> ", name, " REÇOIT SOIN. PV: ", health)
