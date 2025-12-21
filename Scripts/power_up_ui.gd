extends Control

@onready var player := get_tree().get_first_node_in_group("player")
@onready var button_container := $CenterContainer/Panel/HBoxContainer

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

var rarity_colors = {
	Rarity.COMMON: Color.WHITE,
	Rarity.RARE: Color.CORNFLOWER_BLUE,
	Rarity.EPIC: Color(0.6, 0.2, 0.8),
	Rarity.LEGENDARY: Color.GOLD
}

var rarity_mult = { 
	Rarity.COMMON: 1.0, 
	Rarity.RARE: 1.5, 
	Rarity.EPIC: 2.0, 
	Rarity.LEGENDARY: 3.5
}

var pool = [] 

func _ready():
	add_to_group("powerup_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS 
	_init_pool()

func _init_pool():
	
	pool = [
		# --- DÉGÂTS ---
		{"id": "dmg_global", "text": "Puissance",        "val": 0.15, "desc": "Augmente tous les dégâts"},
		{"id": "dmg_melee",  "text": "Maître d'Armes",   "val": 0.20, "desc": "Dégâts au corps-à-corps"},
		{"id": "dmg_ranged", "text": "Tir Puissant",     "val": 0.20, "desc": "Dégâts des projectiles"},
		
		# --- VITESSE / SURVIE ---
		{"id": "speed",      "text": "Pied Léger",       "val": 0.08, "desc": "Vitesse de déplacement"},
		{"id": "max_hp",     "text": "Cœur de Titan",    "val": 0.15, "desc": "Santé maximum"},
		{"id": "heal_bonus", "text": "Bénédiction",      "val": 0.25, "desc": "Efficacité des soins"},
		
		# --- CADENCE ---
		# la cadence reste faible car c'est une stat très puissante
		{"id": "fire_rate",  "text": "Gâchette Folle",   "val": -0.05, "desc": "Vitesse de tir"}, 
		
		# --- SPÉCIAL (PIÈGES) ---
		{"id": "unlock_static", "text": "Débloquer : Mine", "val": 0.0,  "desc": "Pose des pièges au sol",      "unique": true},
		{"id": "static_rate",   "text": "Pose Rapide",      "val": -0.10, "desc": "Pose les pièges plus vite",   "req_static": true},
		{"id": "dmg_static",    "text": "Mine Explosive",   "val": 0.30,  "desc": "Dégâts énormes des pièges",   "req_static": true}
	]

func open():
	visible = true
	get_tree().paused = true
	_generate_options()

func _generate_options():
	# FILTRAGE
	var valid_options = []
	for option in pool:
		if option.get("unique", false) and player.static_attack_unlocked: continue
		if option.get("req_static", false) and not player.static_attack_unlocked: continue
		valid_options.append(option)
	
	valid_options.shuffle()
	
	# AFFICHAGE
	var buttons = button_container.get_children()
	var count = min(buttons.size(), valid_options.size())
	
	for i in range(count):
		var btn = buttons[i]
		var power_data = valid_options[i]
		
		var rarity = _roll_rarity()
		if power_data.get("unique", false): rarity = Rarity.LEGENDARY
			
		var multiplier = rarity_mult[rarity]
		var final_val = power_data["val"] * multiplier
		
		btn.modulate = rarity_colors[rarity]
		
		# GESTION DE L'AFFICHAGE TEXTE
		if final_val == 0:
			btn.text = "%s\n%s" % [power_data["text"], power_data["desc"]]
		elif power_data["id"] == "dmg_flat":
			# Affichage pour valeur fixe (+10 Dégâts)
			btn.text = "%s\n%s (+%d)" % [power_data["text"], power_data["desc"], int(final_val)]
		else:
			# Affichage pour pourcentage (+15%)
			var display_val = final_val * 100
			if power_data["id"] in ["fire_rate", "static_rate"]:
				btn.text = "%s\n%s (+%d%%)" % [power_data["text"], power_data["desc"], abs(display_val)]
			else:
				btn.text = "%s\n%s (+%d%%)" % [power_data["text"], power_data["desc"], display_val]
		
		if btn.pressed.is_connected(_apply_powerup):
			btn.pressed.disconnect(_apply_powerup)
		btn.pressed.connect(_apply_powerup.bind(power_data["id"], final_val))
	
	# Cache les boutons inutiles
	for i in range(count, buttons.size()): buttons[i].visible = false
	for i in range(count): buttons[i].visible = true

func _roll_rarity() -> Rarity:
	var r = randf()
	if r > 0.97: return Rarity.LEGENDARY 
	if r > 0.85: return Rarity.EPIC      
	if r > 0.60: return Rarity.RARE      
	return Rarity.COMMON                 

func _apply_powerup(id: String, value: float):
	if not player: 
		close()
		return

	match id:
		# --- LE BONUS HYBRIDE ---
		
		"dmg_global": player.global_damage_mult += value
		"dmg_melee": player.melee_damage_mult += value
		"dmg_ranged": player.ranged_damage_mult += value
		
		"speed": player.speed *= (1.0 + value)
		
		"max_hp": 
			player.max_health *= (1.0 + value)
			player.healthbar.init_health(player.health, player.max_health)
			
		"heal_bonus": player.heart_recovery_mult += value
		
		"fire_rate": 
			player.fire_rate *= (1.0 + value) 
			if player.fire_rate < 0.1: player.fire_rate = 0.1
			
		"unlock_static": player.static_attack_unlocked = true
		
		"static_rate": 
			player.static_fire_rate *= (1.0 + value)
			if player.static_fire_rate < 0.5: player.static_fire_rate = 0.5
			
		"dmg_static": player.static_damage_mult += value
	
	close()

func close():
	visible = false
	get_tree().paused = false
