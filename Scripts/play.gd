extends TextureButton

@export var hover_scale := Vector2(1.08, 1.08)
@export var pulse_scale := Vector2(1.12, 1.12)
@export var tween_duration := 0.12
@export var pulse_duration := 0.08

var tween: Tween

func _ready():
	# Attendre 1 frame pour que la taille de l’image soit connue
	await get_tree().process_frame
	pivot_offset = size / 2  # centre le pivot = zoom homogène

	connect("mouse_entered", _on_hover_in)
	connect("mouse_exited", _on_hover_out)


func _on_hover_in():
	_start_pulse()


func _on_hover_out():
	_start_return()


func _start_pulse():
	if tween: tween.kill()
	tween = create_tween()

	# 1) zoom principal
	tween.tween_property(self, "scale", hover_scale, tween_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2) mini sur-zoom rapide (pulse)
	tween.tween_property(self, "scale", pulse_scale, pulse_duration)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# 3) retour à la scale hover
	tween.tween_property(self, "scale", hover_scale, pulse_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 4) légère augmentation de luminosité de l’image
	tween.parallel().tween_property(self, "modulate", Color(1.15, 1.15, 1.15), tween_duration)


func _start_return():
	if tween: tween.kill()
	tween = create_tween()

	# Retour à la normal
	tween.tween_property(self, "scale", Vector2.ONE, tween_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Retour de la luminosité normale
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1), tween_duration)
