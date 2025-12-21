extends Area2D

# Pas de class_name nécessaire ici, le fichier s'appelle Projectile.gd
# Pas de variables @export ici car tout vient du fichier de données (.tres)

var velocity : Vector2 = Vector2.ZERO
var damage : float
var target_group : String
var shooter : Node2D = null

func _ready() -> void:
	# On connecte le signal pour détecter quand on touche quelque chose
	body_entered.connect(_on_body_entered)

# Fonction de configuration (appelée par l'ennemi ou la tourelle au moment du tir)
func setup(data: ProjectileData, dir: Vector2, target: String, shooter_node: Node2D, custom_speed: float = -1.0) -> void:
	# 1. VISUEL
	$AnimatedSprite2D.sprite_frames = data.frames
	$AnimatedSprite2D.play(data.animation_name)
	
	# 2. STATS & CIBLE
	damage = data.damage
	target_group = target
	
	# 3. MOUVEMENT & PHYSIQUE
	var final_speed = data.speed
	if custom_speed > 0:
		final_speed = custom_speed
	velocity = dir * final_speed
	
	scale = Vector2(data.scale, data.scale)
	rotation = dir.angle() # Le projectile tourne pour regarder sa cible
	
	# 4. DURÉE DE VIE (Autodestruction)
	var timer = get_tree().create_timer(data.lifetime)
	timer.timeout.connect(queue_free)
	
	shooter = shooter_node

func _physics_process(delta: float) -> void:
	# Le projectile avance tout droit
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	
	if target_group != "" and body.is_in_group(target_group):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
			queue_free() # Destruction après impact
			
	# Si on touche un mur (TileMap)
	elif body is TileMap: 
		queue_free()
		
		
