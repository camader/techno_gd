extends CanvasLayer

# On-screen buttons for players without a keyboard. Each button fires the same input
# action as its key, so the player and pause menu need no special handling. Works with
# touch directly and with a mouse through touch emulation.

const BUTTON_SIZE := 84
const DPAD_CENTER := Vector2(150, 590)
const DPAD_STEP := 88.0

const BUTTONS := [
	{"action": "ui_left", "icon": "left", "pos": DPAD_CENTER + Vector2(-DPAD_STEP, 0)},
	{"action": "ui_right", "icon": "right", "pos": DPAD_CENTER + Vector2(DPAD_STEP, 0)},
	{"action": "ui_up", "icon": "up", "pos": DPAD_CENTER + Vector2(0, -DPAD_STEP)},
	{"action": "ui_down", "icon": "down", "pos": DPAD_CENTER + Vector2(0, DPAD_STEP)},
	{"action": "ui_accept", "icon": "none", "text": "JUMP", "pos": Vector2(1170, 620), "size": 120},
	{"action": "ui_cancel", "icon": "pause", "pos": Vector2(880, 40), "size": 56},
]

var _rects: Array[Rect2] = []
var _had_touch_emulation := false

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("touch_controls")
	_had_touch_emulation = Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse = true
	for cfg in BUTTONS:
		_add_button(cfg)

func _exit_tree() -> void:
	Input.emulate_touch_from_mouse = _had_touch_emulation

# True when screen_pos lands on a button, so a click there is not also a shot.
func covers(screen_pos: Vector2) -> bool:
	return _rects.any(func(r: Rect2): return r.has_point(screen_pos))

func _add_button(cfg: Dictionary) -> void:
	var size: int = cfg.get("size", BUTTON_SIZE)
	var button := TouchScreenButton.new()
	button.action = cfg["action"]
	button.texture_normal = _make_texture(size, cfg["icon"], 0.3)
	button.texture_pressed = _make_texture(size, cfg["icon"], 0.65)
	button.position = cfg["pos"] - Vector2(size, size) / 2.0
	add_child(button)
	_rects.append(Rect2(button.position, Vector2(size, size)))

	if cfg.has("text"):
		var label := Label.new()
		label.text = cfg["text"]
		label.size = Vector2(size, size)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 26)
		button.add_child(label)

func _make_texture(size: int, icon: String, fill_alpha: float) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	var radius := size / 2.0 - 1.0
	var glyph := _glyph_triangle(icon, center, size * 0.22)
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var dist := p.distance_to(center)
			if dist > radius:
				continue
			var color := Color(1, 1, 1, fill_alpha)
			if dist > radius - 3.0:
				color = Color(1, 1, 1, 0.8)
			elif _in_glyph(p, icon, glyph, center, size):
				color = Color(1, 1, 1, 0.9)
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)

func _glyph_triangle(icon: String, c: Vector2, r: float) -> PackedVector2Array:
	match icon:
		"left":
			return PackedVector2Array([c + Vector2(-r, 0), c + Vector2(r, -r), c + Vector2(r, r)])
		"right":
			return PackedVector2Array([c + Vector2(r, 0), c + Vector2(-r, -r), c + Vector2(-r, r)])
		"up":
			return PackedVector2Array([c + Vector2(0, -r), c + Vector2(-r, r), c + Vector2(r, r)])
		"down":
			return PackedVector2Array([c + Vector2(0, r), c + Vector2(-r, -r), c + Vector2(r, -r)])
	return PackedVector2Array()

func _in_glyph(p: Vector2, icon: String, tri: PackedVector2Array, c: Vector2, size: int) -> bool:
	if tri.size() == 3:
		return Geometry2D.point_is_inside_triangle(p, tri[0], tri[1], tri[2])
	if icon == "pause":
		var bar_h := size * 0.22
		var in_rows := absf(p.y - c.y) < bar_h
		return in_rows and absf(absf(p.x - c.x) - size * 0.1) < size * 0.05
	return false
