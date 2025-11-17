extends Resource
class_name Enemy

@export var title : String
@export var sprite_frames : SpriteFrames
@export var health : float
@export var damage : float
@export var role : Role

enum Role {
	MELEE,
	RANGED,
	#BOSS,
	#TANK,
	#SUMMONER,
	HEALER
}
