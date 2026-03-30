extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.08)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	add_child(bg)

	# Decorative border
	var border := ColorRect.new()
	border.color = Color(1.0, 0.85, 0.0, 0.15)
	border.position = Vector2(300, 20)
	border.size = Vector2(680, 680)
	add_child(border)

	var inner := ColorRect.new()
	inner.color = Color(0.02, 0.02, 0.08)
	inner.position = Vector2(304, 24)
	inner.size = Vector2(672, 672)
	add_child(inner)

	# Title
	var title := Label.new()
	title.text = "HIGH SCORES"
	title.position = Vector2(440, 35)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	add_child(title)

	# Title underline
	var underline := ColorRect.new()
	underline.color = Color(1.0, 0.85, 0.0, 0.6)
	underline.position = Vector2(380, 95)
	underline.size = Vector2(520, 2)
	add_child(underline)

	# Column headers
	var header_name := Label.new()
	header_name.text = "PLAYER"
	header_name.position = Vector2(380, 110)
	header_name.add_theme_font_size_override("font_size", 16)
	header_name.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(header_name)

	var header_score := Label.new()
	header_score.text = "SCORE"
	header_score.position = Vector2(820, 110)
	header_score.add_theme_font_size_override("font_size", 16)
	header_score.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(header_score)

	# Header separator
	var header_sep := ColorRect.new()
	header_sep.color = Color(0.4, 0.4, 0.4, 0.5)
	header_sep.position = Vector2(360, 135)
	header_sep.size = Vector2(560, 1)
	add_child(header_sep)

	# Load scores
	var scores: Array = []
	if GameState:
		scores = GameState.load_high_scores()

	# Score rows
	var y_start := 148
	var row_height := 38
	for i in 10:
		var y_pos: float = y_start + i * row_height

		# Alternating row background
		if i % 2 == 0:
			var row_bg := ColorRect.new()
			row_bg.color = Color(1.0, 1.0, 1.0, 0.03)
			row_bg.position = Vector2(360, y_pos - 2)
			row_bg.size = Vector2(560, row_height)
			add_child(row_bg)

		# Rank number
		var rank := Label.new()
		rank.text = "%d." % (i + 1)
		rank.position = Vector2(370, y_pos)
		rank.add_theme_font_size_override("font_size", 22)

		# Name label
		var name_label := Label.new()
		name_label.position = Vector2(420, y_pos)
		name_label.add_theme_font_size_override("font_size", 22)

		# Dots
		var dots := Label.new()
		dots.position = Vector2(600, y_pos)
		dots.add_theme_font_size_override("font_size", 22)

		# Score label
		var score_label := Label.new()
		score_label.position = Vector2(820, y_pos)
		score_label.add_theme_font_size_override("font_size", 22)

		if i < scores.size() and scores[i] is Dictionary:
			var entry_name := str(scores[i].get("name", "???"))
			var entry_score := str(int(scores[i].get("score", 0)))

			# Gold highlight for #1
			if i == 0:
				rank.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
				name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
				dots.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 0.4))
				score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			elif i == 1:
				rank.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
				name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
				dots.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.4))
				score_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
			elif i == 2:
				rank.add_theme_color_override("font_color", Color(0.8, 0.55, 0.3))
				name_label.add_theme_color_override("font_color", Color(0.8, 0.55, 0.3))
				dots.add_theme_color_override("font_color", Color(0.8, 0.55, 0.3, 0.4))
				score_label.add_theme_color_override("font_color", Color(0.8, 0.55, 0.3))
			else:
				rank.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
				name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
				dots.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.4))
				score_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

			name_label.text = entry_name
			var dots_count: int = max(3, 30 - entry_name.length() - entry_score.length())
			dots.text = ".".repeat(dots_count)
			score_label.text = entry_score
		else:
			rank.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
			name_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
			dots.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 0.3))
			score_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
			name_label.text = "---"
			dots.text = "......................."
			score_label.text = "---"

		add_child(rank)
		add_child(name_label)
		add_child(dots)
		add_child(score_label)

	# Bottom separator
	var bottom_sep := ColorRect.new()
	bottom_sep.color = Color(0.4, 0.4, 0.4, 0.5)
	bottom_sep.position = Vector2(360, y_start + 10 * row_height + 5)
	bottom_sep.size = Vector2(560, 1)
	add_child(bottom_sep)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.position = Vector2(540, y_start + 10 * row_height + 20)
	close_btn.custom_minimum_size = Vector2(200, 50)
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
	add_child(close_btn)

	close_btn.grab_focus()
