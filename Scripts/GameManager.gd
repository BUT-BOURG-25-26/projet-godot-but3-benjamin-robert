extends Node
signal score_updated(new_total)

var total_score : float = 0

func add_score(amount: float) -> void:
	total_score += amount
	score_updated.emit(total_score)
	print("Score actuel : ", total_score)

func reset_score() -> void:
	total_score = 0
	score_updated.emit(total_score)
