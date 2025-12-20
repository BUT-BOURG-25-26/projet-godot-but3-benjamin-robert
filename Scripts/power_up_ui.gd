extends Control

@onready var player := get_tree().get_first_node_in_group("player")

func _ready():
	add_to_group("powerup_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# 🔥 CRITIQUE : boutons actifs pendant la pause
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
	print("ATTAQUE CLICK")
	if player:
		player.damage += 5
	close()


func _on_vitesse_pressed():
	print("VITESSE CLICK")
	if player:
		player.speed += 40
	close()


func _on_portee_pressed():
	print("PORTEE CLICK")
	if player:
		player.hitbox.scale *= 1.25
	close()
