extends Control

var name_popup: PanelContainer
var char_select_popup: PanelContainer
var selected_index := 0
var char_names := ["rockman", "volton"]
var char_labels := ["ROCKMAN", "VOLTON"]
var preview_sprites: Array[TextureRect] = []
var selection_border: ColorRect

func _ready() -> void:
	%NewGameButton.grab_focus()
	_build_player_sprite()
	_build_enemy_sprite()

func _on_new_game_button_pressed() -> void:
	_show_name_input()

func _on_high_scores_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/high_scores.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_info_button_pressed() -> void:
	%InfoPanel.visible = true
	%CloseButton.grab_focus()

func _on_close_info_button_pressed() -> void:
	%InfoPanel.visible = false
	%NewGameButton.grab_focus()

func _show_name_input() -> void:
	if name_popup:
		name_popup.queue_free()

	name_popup = PanelContainer.new()
	name_popup.set_anchors_preset(Control.PRESET_CENTER)
	name_popup.offset_left = -200
	name_popup.offset_top = -120
	name_popup.offset_right = 200
	name_popup.offset_bottom = 120
	name_popup.z_index = 100
	add_child(name_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	name_popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Enter Your Name"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var name_edit := LineEdit.new()
	name_edit.text = "Player 1"
	name_edit.max_length = 20
	name_edit.add_theme_font_size_override("font_size", 22)
	name_edit.select_all_on_focus = true
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_edit)

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	var next_btn := Button.new()
	next_btn.text = "Next"
	next_btn.custom_minimum_size = Vector2(120, 40)
	next_btn.add_theme_font_size_override("font_size", 20)
	next_btn.pressed.connect(func():
		var pname := name_edit.text.strip_edges()
		if pname.is_empty():
			pname = "Player 1"
		GameState.player_name = pname
		name_popup.queue_free()
		name_popup = null
		_show_character_select()
	)
	btn_container.add_child(next_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func():
		name_popup.queue_free()
		name_popup = null
		%NewGameButton.grab_focus()
	)
	btn_container.add_child(cancel_btn)

	name_edit.text_submitted.connect(func(_text):
		next_btn.pressed.emit()
	)

	name_edit.grab_focus()
	name_edit.select_all()

func _show_character_select() -> void:
	if char_select_popup:
		char_select_popup.queue_free()

	selected_index = 0
	preview_sprites.clear()

	char_select_popup = PanelContainer.new()
	char_select_popup.set_anchors_preset(Control.PRESET_CENTER)
	char_select_popup.offset_left = -350
	char_select_popup.offset_top = -220
	char_select_popup.offset_right = 350
	char_select_popup.offset_bottom = 220
	char_select_popup.z_index = 100
	add_child(char_select_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	char_select_popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Choose Your Character"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var chars_container := HBoxContainer.new()
	chars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	chars_container.add_theme_constant_override("separation", 30)
	vbox.add_child(chars_container)

	for i in char_names.size():
		var char_box := VBoxContainer.new()
		char_box.add_theme_constant_override("separation", 8)
		chars_container.add_child(char_box)

		# Border/highlight container
		var border := PanelContainer.new()
		border.custom_minimum_size = Vector2(160, 160)
		border.name = "Border_%d" % i

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2)
		style.border_color = Color(0.3, 0.3, 0.4)
		style.set_border_width_all(3)
		style.set_corner_radius_all(8)
		border.add_theme_stylebox_override("panel", style)
		char_box.add_child(border)

		# Preview image
		var preview := TextureRect.new()
		var tex := load("res://assets/characters/%s_preview.png" % char_names[i])
		preview.texture = tex
		preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.custom_minimum_size = Vector2(150, 150)
		border.add_child(preview)
		preview_sprites.append(preview)

		# Character name label
		var name_label := Label.new()
		name_label.text = char_labels[i]
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		char_box.add_child(name_label)

		# Click to select
		var click_idx := i
		border.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				selected_index = click_idx
				_update_selection_highlight()
		)

	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	var start_btn := Button.new()
	start_btn.text = "Start Game"
	start_btn.custom_minimum_size = Vector2(150, 45)
	start_btn.add_theme_font_size_override("font_size", 22)
	start_btn.pressed.connect(func():
		GameState.selected_character = char_names[selected_index]
		GameState.reset()
		get_tree().change_scene_to_file("res://scenes/level_1.tscn")
	)
	btn_container.add_child(start_btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 45)
	back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.pressed.connect(func():
		char_select_popup.queue_free()
		char_select_popup = null
		_show_name_input()
	)
	btn_container.add_child(back_btn)

	_update_selection_highlight()
	start_btn.grab_focus()

func _update_selection_highlight() -> void:
	if not char_select_popup:
		return
	for i in char_names.size():
		var border: PanelContainer = char_select_popup.find_child("Border_%d" % i, true, false)
		if border:
			var style: StyleBoxFlat = border.get_theme_stylebox("panel").duplicate()
			if i == selected_index:
				style.border_color = Color(1.0, 0.85, 0.0)
				style.set_border_width_all(4)
				style.bg_color = Color(0.2, 0.2, 0.1)
			else:
				style.border_color = Color(0.3, 0.3, 0.4)
				style.set_border_width_all(3)
				style.bg_color = Color(0.15, 0.15, 0.2)
			border.add_theme_stylebox_override("panel", style)

func _input(event: InputEvent) -> void:
	if not char_select_popup or not char_select_popup.is_inside_tree():
		return
	if event.is_action_pressed("ui_left"):
		selected_index = (selected_index - 1 + char_names.size()) % char_names.size()
		_update_selection_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		selected_index = (selected_index + 1) % char_names.size()
		_update_selection_highlight()
		get_viewport().set_input_as_handled()

func _build_player_sprite() -> void:
	var container := Node2D.new()
	container.position = Vector2(180, 400)
	var s := 4.0

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-10 * s, -15 * s), Vector2(10 * s, -15 * s),
		Vector2(10 * s, 15 * s), Vector2(-10 * s, 15 * s),
	])
	body.color = Color(0.2, 0.6, 1.0)
	container.add_child(body)

	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(-7 * s, -24 * s), Vector2(7 * s, -24 * s),
		Vector2(7 * s, -15 * s), Vector2(-7 * s, -15 * s),
	])
	head.color = Color(0.9, 0.75, 0.6)
	container.add_child(head)

	var eye_l := Polygon2D.new()
	eye_l.polygon = PackedVector2Array([
		Vector2(-5 * s, -22 * s), Vector2(-2 * s, -22 * s),
		Vector2(-2 * s, -19 * s), Vector2(-5 * s, -19 * s),
	])
	eye_l.color = Color(1, 1, 1)
	container.add_child(eye_l)

	var eye_r := Polygon2D.new()
	eye_r.polygon = PackedVector2Array([
		Vector2(2 * s, -22 * s), Vector2(5 * s, -22 * s),
		Vector2(5 * s, -19 * s), Vector2(2 * s, -19 * s),
	])
	eye_r.color = Color(1, 1, 1)
	container.add_child(eye_r)

	var label := Label.new()
	label.text = "PLAYER"
	label.position = Vector2(-36, 70)
	label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)

	add_child(container)

func _build_enemy_sprite() -> void:
	var container := Node2D.new()
	container.position = Vector2(1100, 400)
	var s := 3.0

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-20 * s, -22.5 * s), Vector2(20 * s, -22.5 * s),
		Vector2(25 * s, 22.5 * s), Vector2(-25 * s, 22.5 * s),
	])
	body.color = Color(0.75, 0.08, 0.08)
	container.add_child(body)

	var body_hi := Polygon2D.new()
	body_hi.polygon = PackedVector2Array([
		Vector2(-15 * s, -19 * s), Vector2(5 * s, -19 * s),
		Vector2(7 * s, 18 * s), Vector2(-22 * s, 18 * s),
	])
	body_hi.color = Color(0.85, 0.15, 0.12)
	container.add_child(body_hi)

	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(-12 * s, -44 * s), Vector2(12 * s, -44 * s),
		Vector2(15 * s, -22.5 * s), Vector2(-15 * s, -22.5 * s),
	])
	head.color = Color(0.9, 0.12, 0.08)
	container.add_child(head)

	var brow_l := Polygon2D.new()
	brow_l.polygon = PackedVector2Array([
		Vector2(-10 * s, -40 * s), Vector2(-1 * s, -38 * s),
		Vector2(-1 * s, -37 * s), Vector2(-10 * s, -38 * s),
	])
	brow_l.color = Color(0.3, 0.0, 0.0)
	container.add_child(brow_l)

	var brow_r := Polygon2D.new()
	brow_r.polygon = PackedVector2Array([
		Vector2(1 * s, -38 * s), Vector2(10 * s, -40 * s),
		Vector2(10 * s, -38 * s), Vector2(1 * s, -37 * s),
	])
	brow_r.color = Color(0.3, 0.0, 0.0)
	container.add_child(brow_r)

	var eye_l := Polygon2D.new()
	eye_l.polygon = PackedVector2Array([
		Vector2(-8 * s, -36 * s), Vector2(-2 * s, -36 * s),
		Vector2(-2 * s, -30 * s), Vector2(-8 * s, -30 * s),
	])
	eye_l.color = Color(1, 1, 1)
	container.add_child(eye_l)

	var eye_r := Polygon2D.new()
	eye_r.polygon = PackedVector2Array([
		Vector2(2 * s, -36 * s), Vector2(8 * s, -36 * s),
		Vector2(8 * s, -30 * s), Vector2(2 * s, -30 * s),
	])
	eye_r.color = Color(1, 1, 1)
	container.add_child(eye_r)

	var pupil_l := Polygon2D.new()
	pupil_l.polygon = PackedVector2Array([
		Vector2(-7 * s, -34 * s), Vector2(-4 * s, -34 * s),
		Vector2(-4 * s, -31 * s), Vector2(-7 * s, -31 * s),
	])
	pupil_l.color = Color(0.1, 0.0, 0.0)
	container.add_child(pupil_l)

	var pupil_r := Polygon2D.new()
	pupil_r.polygon = PackedVector2Array([
		Vector2(4 * s, -34 * s), Vector2(7 * s, -34 * s),
		Vector2(7 * s, -31 * s), Vector2(4 * s, -31 * s),
	])
	pupil_r.color = Color(0.1, 0.0, 0.0)
	container.add_child(pupil_r)

	var label := Label.new()
	label.text = "TECHNO"
	label.position = Vector2(-36, 75)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)

	add_child(container)
