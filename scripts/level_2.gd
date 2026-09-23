extends Node2D

# Level 2 - side-scroller. Techno stands on a ledge at the far right and hurls
# barrels (Donkey-Kong style) that roll left toward the player. The player runs
# right toward the goal while left-clicking to shoot the barrels for points.

@onready var player: CharacterBody2D = $Player
@onready var barrels: Node2D = $Barrels
@onready var ui_layer: CanvasLayer = $UILayer

const LEVEL_WIDTH := 4200.0
const GROUND_TOP := 640.0
const SPAWN := Vector2(120, 560)
const LEDGE_LEFT := LEVEL_WIDTH - 300.0
const LEDGE_TOP := 470.0
const TECHNO_X := LEVEL_WIDTH - 150.0
const GOAL_X := LEVEL_WIDTH - 420.0

const SKY := "res://assets/pixel_packs/high_forest/Background/Background.png"
const TREES := "res://assets/pixel_packs/high_forest/Trees/Background.png"

var spawn_timer := 0.0
const SPAWN_INTERVAL := 2.2

var lives := 5
var game_over := false
var won := false
var time_remaining := 120.0
var techno_sprite: Sprite2D

func _ready() -> void:
	GameState.reset()
	_setup_player()
	_build_background()
	_build_ground()
	_build_decor()
	_build_techno()
	_build_goal()
	_build_hud()

func _setup_player() -> void:
	player.position = SPAWN
	player.spawn_point = SPAWN
	player.max_x = LEVEL_WIDTH
	player.can_shoot = true

	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(LEVEL_WIDTH)
	cam.limit_bottom = 720
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	cam.make_current()

func _physics_process(delta: float) -> void:
	if game_over or won:
		return

	time_remaining -= delta
	_update_timer_display()
	if time_remaining <= 0:
		lives -= 1
		time_remaining = 60.0
		_update_lives_display()
		if lives <= 0:
			_do_game_over()
		else:
			player._respawn()
		return

	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_throw_barrel()

# ---------------- world building ----------------

func _build_background() -> void:
	var pbg := ParallaxBackground.new()
	add_child(pbg)

	# Sky
	var sky_layer := ParallaxLayer.new()
	sky_layer.motion_scale = Vector2(0.15, 0)
	pbg.add_child(sky_layer)
	var sky := Sprite2D.new()
	sky.texture = load(SKY)
	sky.centered = false
	var sky_s := 720.0 / 272.0
	sky.scale = Vector2(sky_s, sky_s)
	sky_layer.motion_mirroring = Vector2(480.0 * sky_s, 0)
	sky_layer.add_child(sky)

	# Tree-line silhouette, two layers so the gaps between tree clumps are filled
	# by the layer behind (also adds depth).
	var tree_s := 1.7
	var mirror := 896.0 * tree_s
	# Back layer: darker, slower, offset by half so it sits behind the gaps.
	_add_tree_layer(pbg, 0.32, GROUND_TOP - 256.0 * tree_s + 90, tree_s,
			Color(0.35, 0.45, 0.42, 1.0), mirror * 0.5)
	# Front layer.
	_add_tree_layer(pbg, 0.5, GROUND_TOP - 256.0 * tree_s + 40, tree_s,
			Color(1, 1, 1, 0.95), 0.0)

func _add_tree_layer(pbg: ParallaxBackground, motion: float, y: float, scale: float, tint: Color, x_off: float) -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(motion, 0)
	layer.motion_mirroring = Vector2(896.0 * scale, 0)
	pbg.add_child(layer)
	var trees := Sprite2D.new()
	trees.texture = load(TREES)
	trees.centered = false
	trees.scale = Vector2(scale, scale)
	trees.position = Vector2(x_off, y)
	trees.modulate = tint
	layer.add_child(trees)

func _make_platform(x: float, y: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape = shape
	col.position = Vector2(x + w / 2.0, y + h / 2.0)
	body.add_child(col)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y),
		Vector2(x + w, y + h), Vector2(x, y + h),
	])
	visual.color = Color(0.08, 0.38, 0.12)
	body.add_child(visual)

	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y),
		Vector2(x + w, y + 8), Vector2(x, y + 8),
	])
	top.color = Color(0.18, 0.68, 0.25)
	body.add_child(top)

	add_child(body)

func _build_ground() -> void:
	# One flat continuous lane so barrels roll the whole way to the player.
	_make_platform(0, GROUND_TOP, LEVEL_WIDTH, 80)
	# Techno's raised throne-ledge on the far right (too tall to climb - barrels
	# spawn up here, drop off its edge, then roll toward the player).
	_make_platform(LEDGE_LEFT, LEDGE_TOP, LEVEL_WIDTH - LEDGE_LEFT, GROUND_TOP - LEDGE_TOP)

func _build_decor() -> void:
	# Simple foreground bushes for depth (kept off the barrel lane's collision).
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260923
	for i in 26:
		var bx := rng.randf_range(60, LEDGE_LEFT - 80)
		var bush := Polygon2D.new()
		var s := rng.randf_range(14, 30)
		bush.polygon = PackedVector2Array([
			Vector2(bx - s, GROUND_TOP),
			Vector2(bx - s * 0.5, GROUND_TOP - s),
			Vector2(bx, GROUND_TOP - s * 1.3),
			Vector2(bx + s * 0.5, GROUND_TOP - s),
			Vector2(bx + s, GROUND_TOP),
		])
		bush.color = Color(rng.randf_range(0.08, 0.2), rng.randf_range(0.4, 0.7), rng.randf_range(0.1, 0.25))
		bush.z_index = -1
		add_child(bush)

func _build_techno() -> void:
	techno_sprite = Sprite2D.new()
	techno_sprite.texture = load("res://assets/characters/techno/Techno_base.png")
	techno_sprite.position = Vector2(TECHNO_X, LEDGE_TOP - 70)
	techno_sprite.scale = Vector2(0.32, 0.32)
	techno_sprite.flip_h = true  # face the player (left)
	add_child(techno_sprite)

	var label := Label.new()
	label.text = "TECHNO"
	label.position = Vector2(TECHNO_X - 45, LEDGE_TOP - 160)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

func _build_goal() -> void:
	var goal := Area2D.new()
	goal.collision_layer = 2
	goal.collision_mask = 1
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50, 70)
	col.shape = shape
	col.position = Vector2(GOAL_X, GROUND_TOP - 35)
	goal.add_child(col)

	var pole := Polygon2D.new()
	pole.polygon = PackedVector2Array([
		Vector2(GOAL_X - 2, GROUND_TOP - 90), Vector2(GOAL_X + 2, GROUND_TOP - 90),
		Vector2(GOAL_X + 2, GROUND_TOP), Vector2(GOAL_X - 2, GROUND_TOP),
	])
	pole.color = Color(0.85, 0.85, 0.85)
	goal.add_child(pole)
	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([
		Vector2(GOAL_X + 2, GROUND_TOP - 90), Vector2(GOAL_X + 40, GROUND_TOP - 78),
		Vector2(GOAL_X + 2, GROUND_TOP - 66),
	])
	flag.color = Color(1.0, 0.85, 0.0)
	goal.add_child(flag)

	goal.body_entered.connect(_on_goal_reached)
	add_child(goal)

func _throw_barrel() -> void:
	var barrel := RigidBody2D.new()
	barrel.set_script(load("res://scripts/barrel.gd"))
	barrel.position = Vector2(TECHNO_X - 40, LEDGE_TOP - 40)
	barrels.add_child(barrel)
	# little throw pulse
	if techno_sprite:
		var tw := create_tween()
		tw.tween_property(techno_sprite, "scale", Vector2(0.36, 0.28), 0.1)
		tw.tween_property(techno_sprite, "scale", Vector2(0.32, 0.32), 0.15)

# ---------------- scoring / effects ----------------

func add_score(points: int) -> void:
	GameState.add_score(points)
	_update_score_display()

func spawn_hit_effect(pos: Vector2) -> void:
	var burst := Polygon2D.new()
	burst.position = pos
	burst.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(0, -10), Vector2(10, 0), Vector2(0, 10),
	])
	burst.color = Color(1.0, 0.8, 0.2, 0.9)
	add_child(burst)
	var tw := create_tween()
	tw.tween_property(burst, "scale", Vector2(2.2, 2.2), 0.2)
	tw.parallel().tween_property(burst, "modulate:a", 0.0, 0.2)
	tw.tween_callback(burst.queue_free)

	var label := Label.new()
	label.text = "+25"
	label.position = pos + Vector2(-12, -30)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	label.add_theme_font_size_override("font_size", 20)
	add_child(label)
	var lt := create_tween()
	lt.tween_property(label, "position", label.position + Vector2(0, -30), 0.5)
	lt.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	lt.tween_callback(label.queue_free)

func player_hit_by_obstacle() -> void:
	if game_over or won or player.is_dead:
		return
	player.play_death()
	await player.died
	if game_over or won:
		return
	lives -= 1
	GameState.add_score(-50)
	_update_lives_display()
	_update_score_display()
	if lives <= 0:
		_do_game_over()
	else:
		time_remaining = min(time_remaining + 20.0, 120.0)
		player._respawn()

# ---------------- HUD ----------------

func _hud_label(name: String, text: String, pos: Vector2, color: Color, size: int) -> Label:
	var l := Label.new()
	l.name = name
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	ui_layer.add_child(l)
	return l

func _build_hud() -> void:
	_hud_label("LivesLabel", "Lives: %d" % lives, Vector2(20, 10), Color(1, 1, 1), 22)
	_hud_label("ScoreLabel", "Score: 0", Vector2(20, 40), Color(1.0, 0.85, 0.0), 22)
	_hud_label("TimerLabel", "Time: %d" % int(time_remaining), Vector2(1100, 10), Color(1, 1, 1), 22)
	_hud_label("HintLabel", "Left-click to shoot the barrels!", Vector2(360, 10), Color(0.7, 0.9, 1.0), 20)

func _update_lives_display() -> void:
	var l: Label = ui_layer.get_node_or_null("LivesLabel")
	if l:
		l.text = "Lives: %d" % lives

func _update_score_display() -> void:
	var l: Label = ui_layer.get_node_or_null("ScoreLabel")
	if l:
		l.text = "Score: %d" % GameState.score

func _update_timer_display() -> void:
	var l: Label = ui_layer.get_node_or_null("TimerLabel")
	if l:
		l.text = "Time: %d" % int(max(0, time_remaining))
		l.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if time_remaining <= 30 else Color(1, 1, 1))

# ---------------- end states ----------------

func _on_goal_reached(body: Node) -> void:
	if body != player or won or game_over:
		return
	won = true
	player.set_physics_process(false)
	var bonus := int(time_remaining) * lives * 10
	GameState.add_score(200 + bonus)
	GameState.save_high_score()
	_update_score_display()
	_show_banner("YOU REACHED TECHNO!", Color(1.0, 0.85, 0.0))
	get_tree().create_timer(3.5).timeout.connect(
		func(): get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	)

func _do_game_over() -> void:
	game_over = true
	GameState.save_high_score()
	player.set_physics_process(false)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.size = Vector2(1280, 720)
	ui_layer.add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(440, 200)
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 20)
	ui_layer.add_child(vbox)

	var title := Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var score_label := Label.new()
	score_label.text = "Final Score: %d" % GameState.score
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_label)

	var retry := Button.new()
	retry.text = "Try Again"
	retry.custom_minimum_size = Vector2(250, 50)
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.add_theme_font_size_override("font_size", 24)
	retry.pressed.connect(func(): get_tree().reload_current_scene())
	vbox.add_child(retry)

	var menu := Button.new()
	menu.text = "Main Menu"
	menu.custom_minimum_size = Vector2(250, 50)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_theme_font_size_override("font_size", 24)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
	vbox.add_child(menu)

	retry.grab_focus()

func _show_banner(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", color)
	label.size = Vector2(1280, 80)
	label.position = Vector2(0, 300)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(label)
