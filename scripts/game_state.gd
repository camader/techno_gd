extends Node

var player_name := "Player 1"
var selected_character := "rockman"
var score := 0

const HIGH_SCORES_PATH := "user://high_scores.json"
const SETTINGS_PATH := "user://settings.cfg"

var touch_controls := false

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		touch_controls = config.get_value("controls", "touch_controls", false)

func set_touch_controls(enabled: bool) -> void:
	touch_controls = enabled
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("controls", "touch_controls", enabled)
	config.save(SETTINGS_PATH)

# Secret cheat: typing the key sequence during a level adds CHEAT_POINTS. Only the
# SHA-256 of the space-joined key names (e.g. "up up down down a b") is stored, so the
# sequence itself is not readable from the published source.
const CHEAT_HASH := "72fbfd713558cdf558dd4805623c23d92e412b3631bff20d9cb4cc095d4d9ad8"
const CHEAT_LENGTH := 2
const CHEAT_POINTS := 1000
var _cheat_keys: Array[String] = []

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	_cheat_keys.append(OS.get_keycode_string(event.keycode).to_lower())
	if _cheat_keys.size() > CHEAT_LENGTH:
		_cheat_keys.pop_front()
	if _cheat_keys.size() == CHEAT_LENGTH \
			and " ".join(_cheat_keys).sha256_text() == CHEAT_HASH:
		_cheat_keys.clear()
		var level := get_tree().current_scene
		if level and level.has_method("add_score"):
			level.add_score(CHEAT_POINTS)

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
