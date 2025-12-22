extends ProgressBar

@onready var level_label = $levelLabel

func _ready():
	add_to_group("xp_bar")
	value = 0
	_setup_visuals()
	
	level_label.text = "Niveau 1"

func _setup_visuals():
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.15, 0.15, 0.15)
	style_bg.set_corner_radius_all(8)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.0, 0.5, 1.0)
	style_fill.set_corner_radius_all(8)
	
	add_theme_stylebox_override("background", style_bg)
	add_theme_stylebox_override("fill", style_fill)
	show_percentage = false

func update_bar(current: float, max_val: float):
	max_value = max_val
	var tween = create_tween()
	tween.tween_property(self, "value", current, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func reset_bar():
	value = 0

func update_level_display(new_level: int):
	if level_label:
		level_label.text = "Niveau " + str(new_level)
