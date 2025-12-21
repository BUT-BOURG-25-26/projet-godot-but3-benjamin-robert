extends Control

@onready var player := get_tree().get_first_node_in_group("player")

func _ready():
	add_to_group("powerup_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	for btn in $CenterContainer/Panel/HBoxContainer.get_children():
		if btn is Button:
			btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func open():
	print("[PowerUpUI] OPEN paused before:", get_tree().paused)
	visible = true
	get_tree().paused = true
	print("[PowerUpUI] OPEN paused after:", get_tree().paused)


func close():
	print("[PowerUpUI] CLOSE paused before:", get_tree().paused)
	visible = false
	get_tree().call_deferred("set", "paused", false)

	await get_tree().process_frame
	print("[PowerUpUI] CLOSE paused after:", get_tree().paused)

func _on_attaque_pressed():
	# +25% de Dégâts
	if player:
		player.damage *= 1.25
		print("Dégâts actuels : ", player.damage)
	close()

func _on_vitesse_pressed():
	# +10% de Vitesse
	if player:
		player.speed *= 1.10
		print("Vitesse actuelle : ", player.speed)
	close()

func _on_portee_pressed():
	# +20% de taille de Hitbox
	if player:
		player.hitbox.scale *= 1.20
		print("Portée actuelle : ", player.hitbox.scale)
	close()
