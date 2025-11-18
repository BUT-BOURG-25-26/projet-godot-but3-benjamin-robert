extends Node2D

const CHUNK_SIZE := 4096.0  # taille d’un chunk en pixels

@onready var player: CharacterBody2D = $player

@onready var maps: Array[TileMap] = [
	$map,   # tu peux changer l’ordre si tu veux
	$map2,
	$map3,
	$map4,
	$map5,
	$map6,
	$map7,
	$map8,
	$map9,
]

# Offsets des 9 maps en coordonnées de chunk (3x3 autour du joueur)
#  map   map2  map3
#  map4  map5  map6
#  map7  map8  map9
var relative_offsets: Array[Vector2i] = [
	Vector2i(-1, -1), # map
	Vector2i(0, -1),  # map2
	Vector2i(1, -1),  # map3
	Vector2i(-1, 0),  # map4
	Vector2i(0, 0),   # map5 (centre)
	Vector2i(1, 0),   # map6
	Vector2i(-1, 1),  # map7
	Vector2i(0, 1),   # map8
	Vector2i(1, 1),   # map9
]

var center_chunk: Vector2i = Vector2i.ZERO


func _ready() -> void:
	center_chunk = _get_chunk_coord(player.global_position)
	_update_maps_positions()


func _process(_delta: float) -> void:
	var player_chunk: Vector2i = _get_chunk_coord(player.global_position)
	if player_chunk != center_chunk:
		center_chunk = player_chunk
		_update_maps_positions()


func _get_chunk_coord(pos: Vector2) -> Vector2i:
	# floor() important pour les coordonnées négatives
	var cx: int = int(floor(pos.x / CHUNK_SIZE))
	var cy: int = int(floor(pos.y / CHUNK_SIZE))
	return Vector2i(cx, cy)


func _update_maps_positions() -> void:
	for i in range(maps.size()):
		var tilemap: TileMap = maps[i]
		if tilemap == null:
			continue

		var offset: Vector2i = relative_offsets[i]
		var chunk_coord: Vector2i = center_chunk + offset

		tilemap.global_position = Vector2(
			float(chunk_coord.x) * CHUNK_SIZE,
			float(chunk_coord.y) * CHUNK_SIZE
		)
