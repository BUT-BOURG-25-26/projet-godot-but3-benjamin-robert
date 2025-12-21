extends Resource
class_name Enemy

@export var title : String
@export var sprite_frames : SpriteFrames
@export var health : float
@export var damage : float
@export var role : Role
@export var speed : float
@export var projectile_data : ProjectileData
@export var projectile_speed_multiplier : float = 1.0
@export var exp_drop : float
@export var attack_range : float


enum Role {
	MELEE,
	RANGED,
	#SUMMONER,
	HEALER
}
