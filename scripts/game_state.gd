extends Node

var player_name := "Player 1"
var selected_character := "rockman"
var score := 0

const HIGH_SCORES_PATH := "user://high_scores.json"

func reset() -> void:
	score = 0

func add_score(points: int) -> void:
	score = max(0, score + points)

func save_high_score() -> void:
	var scores := load_high_scores()
	scores.append({"name": player_name, "score": score, "character": selected_character})
	scores.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if scores.size() > 10:
		scores.resize(10)
	var file := FileAccess.open(HIGH_SCORES_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(scores))
		file.close()

func load_high_scores() -> Array:
	if not FileAccess.file_exists(HIGH_SCORES_PATH):
		return []
	var file := FileAccess.open(HIGH_SCORES_PATH, FileAccess.READ)
	if not file:
		return []
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		return []
	return json.data if json.data is Array else []
