extends Label

func _ready() -> void:
	text = "Score: 0"
	
	GameManager.score_updated.connect(_on_score_updated)

func _on_score_updated(new_total: float) -> void:
	text = "Score: " + str(int(new_total))
	
	var tween = create_tween()
	scale = Vector2(1.5, 1.5)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BOUNCE) # On revient normal
