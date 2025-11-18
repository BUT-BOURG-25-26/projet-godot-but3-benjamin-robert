extends Resource
class_name Enemy

@export var title : String
@export var sprite_frames : SpriteFrames
@export var health : float
@export var damage : float
@export var role : Role
@export var speed : float

enum Role {
	MELEE,
	RANGED,
	#SUMMONER,
	HEALER
}
