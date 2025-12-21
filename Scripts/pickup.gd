extends Area2D

enum PickupType { XP, HEALTH }

@export var type : PickupType = PickupType.XP
@export var value : float = 10.0 # Combien d'XP ou de PV ça donne
@export var sprite_texture : Texture2D

func _ready():
	body_entered.connect(_on_body_entered)
	
	if sprite_texture:
		$Sprite2D.texture = sprite_texture

func _on_body_entered(body):
	if body.is_in_group("player"):
		match type:
			PickupType.XP:
				if body.has_method("gain_exp"):
					body.gain_exp(int(value))
				
			PickupType.HEALTH:
				if body.has_method("heal"):
					body.heal(value)
		
		queue_free()
