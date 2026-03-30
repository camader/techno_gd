extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var obstacle_container: Node2D = $Obstacles

var spawn_timer := 0.0
const SPAWN_INTERVAL := 2.8

var lives := 3
var found_cheese := false
var game_over := false
var trunks_visited := {}
var time_remaining := 160.0

# Platform data: [start_x, end_x, start_y, end_y]
var platforms := [
	[50, 1230, 690, 670],     # Platform 0 - bottom, unchanged
	[50, 1100, 560, 580],     # Platform 1 - right end shortened (downhill=right)
	[180, 1230, 430, 410],    # Platform 2 - left end shortened (downhill=left)
	[50, 1100, 300, 320],     # Platform 3 - right end shortened (downhill=right)
	[180, 1230, 170, 150],    # Platform 4 - left end shortened (downhill=left)
]

# Tree trunk positions [x, top_y, bottom_y] - connecting platforms
var trunks := [
	[150, 560, 670],    # Left side, level 1->2
	[1100, 410, 560],   # Right side, level 2->3
	[200, 300, 410],    # Left side, level 3->4
	[1050, 150, 300],   # Right side, level 4->5
]

var stars := []

func _ready() -> void:
	GameState.reset()
	_build_starfield()
	_build_platforms()
	_build_trunks()
	_build_goal()
	_build_enemy()
	_build_ground_fog()
	_build_lives_display()
	_build_timer_display()
	_build_score_display()

func _physics_process(delta: float) -> void:
	if game_over:
		return

	# Timer countdown
	time_remaining -= delta
	_update_timer_display()
	if time_remaining <= 0:
		time_remaining = 160.0
		lives -= 1
		GameState.add_score(-50)
		_update_lives_display()
		_update_score_display()
		if lives <= 0:
			_game_over()
		else:
			player._respawn()
		return

	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_spawn_obstacle()

func _build_starfield() -> void:
	var star_container := Node2D.new()
	star_container.name = "Stars"
	star_container.z_index = -10
	add_child(star_container)
	for i in 60:
		var star := Polygon2D.new()
		var sx := randf_range(0, 1280)
		var sy := randf_range(0, 720)
		var sr := randf_range(1.0, 3.0)
		star.polygon = PackedVector2Array([
			Vector2(sx, sy - sr), Vector2(sx + sr * 0.5, sy),
			Vector2(sx, sy + sr), Vector2(sx - sr * 0.5, sy),
		])
		var brightness := randf_range(0.3, 1.0)
		star.color = Color(brightness, brightness, brightness * 0.9, randf_range(0.4, 0.9))
		star_container.add_child(star)

func _build_platforms() -> void:
	for i in platforms.size():
		var p = platforms[i]
		var platform := StaticBody2D.new()
		platform.name = "Platform_%d" % i

		var collision := CollisionPolygon2D.new()
		var thickness := 30.0
		collision.polygon = PackedVector2Array([
			Vector2(p[0], p[2]),
			Vector2(p[1], p[3]),
			Vector2(p[1], p[3] + thickness),
			Vector2(p[0], p[2] + thickness),
		])
		collision.one_way_collision = true
		platform.add_child(collision)

		var shadow := Polygon2D.new()
		shadow.polygon = PackedVector2Array([
			Vector2(p[0] + 5, p[2] + thickness),
			Vector2(p[1] + 5, p[3] + thickness),
			Vector2(p[1] + 5, p[3] + thickness + 10),
			Vector2(p[0] + 5, p[2] + thickness + 10),
		])
		shadow.color = Color(0.0, 0.0, 0.0, 0.3)
		platform.add_child(shadow)

		var visual := Polygon2D.new()
		visual.polygon = collision.polygon
		visual.color = Color(0.08, 0.38, 0.12)
		platform.add_child(visual)

		var mid_edge := Polygon2D.new()
		mid_edge.polygon = PackedVector2Array([
			Vector2(p[0], p[2] - 4),
			Vector2(p[1], p[3] - 4),
			Vector2(p[1], p[3] + 6),
			Vector2(p[0], p[2] + 6),
		])
		mid_edge.color = Color(0.12, 0.52, 0.18)
		platform.add_child(mid_edge)

		var top_edge := Polygon2D.new()
		top_edge.polygon = PackedVector2Array([
			Vector2(p[0], p[2] - 10),
			Vector2(p[1], p[3] - 10),
			Vector2(p[1], p[3] - 2),
			Vector2(p[0], p[2] - 2),
		])
		top_edge.color = Color(0.18, 0.68, 0.25)
		platform.add_child(top_edge)

		var num_clusters := 18
		for j in num_clusters:
			var t := float(j) / (num_clusters - 1)
			var cx: float = lerp(float(p[0]), float(p[1]), t)
			var cy: float = lerp(float(p[2]), float(p[3]), t)
			var leaf := Polygon2D.new()
			var s := randf_range(10, 24)
			leaf.polygon = PackedVector2Array([
				Vector2(cx, cy - s - 6),
				Vector2(cx + s * 0.8, cy - 3),
				Vector2(cx, cy + 3),
				Vector2(cx - s * 0.8, cy - 3),
			])
			leaf.color = Color(
				randf_range(0.06, 0.22),
				randf_range(0.4, 0.75),
				randf_range(0.08, 0.28)
			)
			platform.add_child(leaf)

		for j in 8:
			var t := randf_range(0.05, 0.95)
			var cx: float = lerp(float(p[0]), float(p[1]), t)
			var cy: float = lerp(float(p[2]), float(p[3]), t)
			var highlight := Polygon2D.new()
			var hs := randf_range(4, 8)
			highlight.polygon = PackedVector2Array([
				Vector2(cx - hs, cy - 12),
				Vector2(cx + hs, cy - 12),
				Vector2(cx + hs, cy - 10),
				Vector2(cx - hs, cy - 10),
			])
			highlight.color = Color(0.3, 0.85, 0.35, 0.6)
			platform.add_child(highlight)

		add_child(platform)

func _build_trunks() -> void:
	for i in trunks.size():
		var t = trunks[i]
		var trunk_width := 30.0
		var half_w := trunk_width / 2.0

		var shadow := Polygon2D.new()
		shadow.polygon = PackedVector2Array([
			Vector2(t[0] - half_w + 4, t[1]),
			Vector2(t[0] + half_w + 4, t[1]),
			Vector2(t[0] + half_w + 4, t[2]),
			Vector2(t[0] - half_w + 4, t[2]),
		])
		shadow.color = Color(0.0, 0.0, 0.0, 0.25)
		shadow.z_index = -1
		add_child(shadow)

		var visual := Polygon2D.new()
		visual.polygon = PackedVector2Array([
			Vector2(t[0] - half_w, t[1]),
			Vector2(t[0] + half_w, t[1]),
			Vector2(t[0] + half_w, t[2]),
			Vector2(t[0] - half_w, t[2]),
		])
		visual.color = Color(0.45, 0.25, 0.1)
		add_child(visual)

		var center := Polygon2D.new()
		center.polygon = PackedVector2Array([
			Vector2(t[0] - 4, t[1]),
			Vector2(t[0] + 4, t[1]),
			Vector2(t[0] + 4, t[2]),
			Vector2(t[0] - 4, t[2]),
		])
		center.color = Color(0.55, 0.32, 0.15)
		add_child(center)

		var num_lines := 5
		for j in range(num_lines):
			var ly: float = lerp(float(t[1]), float(t[2]), float(j + 1) / float(num_lines + 1))
			var detail := Polygon2D.new()
			var indent := randf_range(3, 6)
			detail.polygon = PackedVector2Array([
				Vector2(t[0] - half_w + indent, ly - 1),
				Vector2(t[0] + half_w - indent, ly - 1),
				Vector2(t[0] + half_w - indent, ly + 1),
				Vector2(t[0] - half_w + indent, ly + 1),
			])
			detail.color = Color(0.35, 0.18, 0.07)
			add_child(detail)

		for j in 3:
			var vy: float = lerp(float(t[1]), float(t[2]), randf_range(0.1, 0.9))
			var side := -1 if j % 2 == 0 else 1
			var vine := Polygon2D.new()
			vine.polygon = PackedVector2Array([
				Vector2(t[0] + side * half_w, vy),
				Vector2(t[0] + side * (half_w + 6), vy + 8),
				Vector2(t[0] + side * (half_w + 3), vy + 14),
				Vector2(t[0] + side * half_w, vy + 10),
			])
			vine.color = Color(0.15, 0.55, 0.2, 0.7)
			add_child(vine)

		var climb_area := Area2D.new()
		climb_area.name = "Trunk_%d" % i
		climb_area.collision_layer = 0
		climb_area.collision_mask = 0
		climb_area.set_collision_layer_value(3, true)
		climb_area.set_collision_mask_value(3, true)
		climb_area.monitoring = true
		climb_area.monitorable = true

		var climb_col := CollisionShape2D.new()
		var climb_shape := RectangleShape2D.new()
		climb_shape.size = Vector2(trunk_width + 20, abs(t[2] - t[1]) + 60)
		climb_col.shape = climb_shape
		climb_col.position = Vector2(t[0], (t[1] + t[2]) / 2.0)
		climb_area.add_child(climb_col)

		climb_area.area_entered.connect(player._on_climb_zone_entered)
		climb_area.area_exited.connect(player._on_climb_zone_exited)
		climb_area.area_entered.connect(_on_trunk_entered.bind(i))

		add_child(climb_area)

func _on_trunk_entered(_area: Area2D, trunk_index: int) -> void:
	if trunk_index == 1 and not trunks_visited.has(0):
		found_cheese = true
	elif trunk_index == 3 and not trunks_visited.has(2):
		found_cheese = true
	trunks_visited[trunk_index] = true

func _build_goal() -> void:
	var goal_area := Area2D.new()
	goal_area.name = "Goal"
	goal_area.collision_layer = 2
	goal_area.collision_mask = 1

	var goal_col := CollisionShape2D.new()
	var goal_shape := RectangleShape2D.new()
	goal_shape.size = Vector2(50, 60)
	goal_col.shape = goal_shape
	goal_col.position = Vector2(1050, 125)
	goal_area.add_child(goal_col)

	var glow := Polygon2D.new()
	var glow_pts := PackedVector2Array()
	for j in 20:
		var angle := j * TAU / 20
		glow_pts.append(Vector2(1060 + cos(angle) * 40, 125 + sin(angle) * 40))
	glow.polygon = glow_pts
	glow.color = Color(1.0, 0.85, 0.0, 0.12)
	goal_area.add_child(glow)

	var glow2 := Polygon2D.new()
	var glow2_pts := PackedVector2Array()
	for j in 20:
		var angle := j * TAU / 20
		glow2_pts.append(Vector2(1060 + cos(angle) * 55, 125 + sin(angle) * 55))
	glow2.polygon = glow2_pts
	glow2.color = Color(1.0, 0.85, 0.0, 0.05)
	goal_area.add_child(glow2)

	var pole := Polygon2D.new()
	pole.polygon = PackedVector2Array([
		Vector2(1048, 95), Vector2(1052, 95),
		Vector2(1052, 168), Vector2(1048, 168),
	])
	pole.color = Color(0.85, 0.85, 0.85)
	goal_area.add_child(pole)

	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(1040, 165), Vector2(1060, 165),
		Vector2(1060, 170), Vector2(1040, 170),
	])
	base.color = Color(0.7, 0.7, 0.7)
	goal_area.add_child(base)

	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([
		Vector2(1052, 95), Vector2(1095, 107),
		Vector2(1052, 119),
	])
	flag.color = Color(1.0, 0.85, 0.0)
	goal_area.add_child(flag)

	var flag_hi := Polygon2D.new()
	flag_hi.polygon = PackedVector2Array([
		Vector2(1052, 95), Vector2(1080, 102),
		Vector2(1052, 107),
	])
	flag_hi.color = Color(1.0, 0.95, 0.4)
	goal_area.add_child(flag_hi)

	var label := Label.new()
	label.text = "GOAL"
	label.position = Vector2(1025, 68)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	label.add_theme_font_size_override("font_size", 18)
	goal_area.add_child(label)

	goal_area.body_entered.connect(_on_goal_reached)
	add_child(goal_area)

func _build_enemy() -> void:
	var enemy := StaticBody2D.new()
	enemy.name = "Enemy"

	var sprite := AnimatedSprite2D.new()
	sprite.position = Vector2(1120, 140)
	sprite.scale = Vector2(0.5, 0.5)

	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 12.0)
	sprite_frames.set_animation_loop("idle", true)
	for i in range(1, 25):
		var tex := load("res://assets/characters/techno/idle/idle_%03d.png" % i)
		if tex:
			sprite_frames.add_frame("idle", tex)
	sprite.sprite_frames = sprite_frames
	sprite.play("idle")
	enemy.add_child(sprite)

	var label := Label.new()
	label.text = "TECHNO"
	label.position = Vector2(1085, 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	label.add_theme_font_size_override("font_size", 12)
	enemy.add_child(label)

	add_child(enemy)

func _build_ground_fog() -> void:
	var fog_container := Node2D.new()
	fog_container.name = "Fog"
	fog_container.z_index = 5
	add_child(fog_container)
	for i in 10:
		var fog := Polygon2D.new()
		var fx := randf_range(-50, 1280)
		var fw := randf_range(150, 350)
		var fh := randf_range(20, 50)
		var fy := randf_range(690, 730)
		fog.polygon = PackedVector2Array([
			Vector2(fx, fy),
			Vector2(fx + fw * 0.3, fy - fh),
			Vector2(fx + fw * 0.7, fy - fh),
			Vector2(fx + fw, fy),
		])
		fog.color = Color(0.2, 0.3, 0.2, randf_range(0.05, 0.12))
		fog_container.add_child(fog)

func _build_lives_display() -> void:
	var lives_label := Label.new()
	lives_label.name = "LivesLabel"
	lives_label.text = "Lives: %d" % lives
	lives_label.position = Vector2(20, 10)
	lives_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lives_label.add_theme_font_size_override("font_size", 22)
	lives_label.z_index = 20
	add_child(lives_label)

func _update_lives_display() -> void:
	var lives_label: Label = get_node_or_null("LivesLabel")
	if lives_label:
		lives_label.text = "Lives: %d" % lives

func _build_timer_display() -> void:
	var timer_label := Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "Time: %d" % int(time_remaining)
	timer_label.position = Vector2(1100, 10)
	timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.z_index = 20
	add_child(timer_label)

func _update_timer_display() -> void:
	var timer_label: Label = get_node_or_null("TimerLabel")
	if timer_label:
		var t := int(max(0, time_remaining))
		timer_label.text = "Time: %d" % t
		if time_remaining <= 10:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _build_score_display() -> void:
	var score_label := Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.position = Vector2(20, 40)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.z_index = 20
	add_child(score_label)

func _update_score_display() -> void:
	var score_label: Label = get_node_or_null("ScoreLabel")
	if score_label:
		score_label.text = "Score: %d" % GameState.score

func add_score(points: int) -> void:
	GameState.add_score(points)
	_update_score_display()

func _spawn_obstacle() -> void:
	# Determine log type: 1/10 gold, 1/5 green, rest normal
	var roll := randi() % 10
	var type: int
	if roll == 0:
		type = 2  # GOLD
	elif roll <= 2:
		type = 1  # GREEN
	else:
		type = 0  # NORMAL

	var obstacle := RigidBody2D.new()
	obstacle.set_script(load("res://scripts/rolling_obstacle.gd"))
	obstacle.gravity_scale = 2.0
	obstacle.mass = 2.0
	obstacle.physics_material_override = PhysicsMaterial.new()
	obstacle.physics_material_override.bounce = 0.1
	obstacle.physics_material_override.friction = 0.3

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	obstacle.add_child(col)

	# Colors based on type
	var main_color: Color
	var inner_color: Color
	var center_color: Color
	match type:
		0:  # NORMAL - brown
			main_color = Color(0.55, 0.3, 0.1)
			inner_color = Color(0.65, 0.38, 0.15)
			center_color = Color(0.4, 0.2, 0.08)
		1:  # GREEN
			main_color = Color(0.15, 0.55, 0.15)
			inner_color = Color(0.25, 0.65, 0.25)
			center_color = Color(0.1, 0.4, 0.1)
		2:  # GOLD
			main_color = Color(0.85, 0.7, 0.1)
			inner_color = Color(0.95, 0.8, 0.2)
			center_color = Color(0.7, 0.55, 0.05)

	var visual := Polygon2D.new()
	var points := PackedVector2Array()
	for j in 16:
		var angle := j * TAU / 16
		points.append(Vector2(cos(angle) * 14, sin(angle) * 14))
	visual.polygon = points
	visual.color = main_color
	obstacle.add_child(visual)

	var inner := Polygon2D.new()
	var inner_pts := PackedVector2Array()
	for j in 12:
		var angle := j * TAU / 12
		inner_pts.append(Vector2(cos(angle) * 8, sin(angle) * 8))
	inner.polygon = inner_pts
	inner.color = inner_color
	obstacle.add_child(inner)

	var center := Polygon2D.new()
	var center_pts := PackedVector2Array()
	for j in 8:
		var angle := j * TAU / 8
		center_pts.append(Vector2(cos(angle) * 3, sin(angle) * 3))
	center.polygon = center_pts
	center.color = center_color
	obstacle.add_child(center)

	obstacle.position = Vector2(1120, 130)
	obstacle.linear_velocity = Vector2(-250, 0)
	obstacle.log_type = type
	obstacle.body_entered.connect(obstacle._on_body_entered)
	obstacle_container.add_child(obstacle)

func player_hit_by_obstacle() -> void:
	if game_over:
		return
	lives -= 1
	GameState.add_score(-50)
	_update_lives_display()
	_update_score_display()
	if lives <= 0:
		_game_over()
	else:
		time_remaining = 160.0
		player._respawn()

func _game_over() -> void:
	game_over = true
	GameState.save_high_score()
	set_physics_process(false)
	player.set_physics_process(false)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1280, 720)
	overlay.z_index = 50
	add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.z_index = 51
	vbox.position = Vector2(440, 180)
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

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

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var retry_btn := Button.new()
	retry_btn.text = "Try Again"
	retry_btn.custom_minimum_size = Vector2(250, 50)
	retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_btn.add_theme_font_size_override("font_size", 24)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	vbox.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.custom_minimum_size = Vector2(250, 50)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.add_theme_font_size_override("font_size", 24)
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
	vbox.add_child(menu_btn)

	retry_btn.grab_focus()

func _on_goal_reached(body: Node) -> void:
	if body == player:
		game_over = true
		set_physics_process(false)
		player.set_physics_process(false)

		GameState.add_score(100)
		GameState.save_high_score()
		_update_score_display()

		var label := Label.new()
		label.text = "LEVEL COMPLETE!"
		label.add_theme_font_size_override("font_size", 64)
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		label.position = Vector2(350, 250)
		label.z_index = 50
		add_child(label)

		var score_label := Label.new()
		score_label.text = "Score: %d" % GameState.score
		score_label.add_theme_font_size_override("font_size", 32)
		score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		score_label.position = Vector2(500, 330)
		score_label.z_index = 50
		add_child(score_label)

		if found_cheese:
			var cheese_label := Label.new()
			cheese_label.text = "You found the cheese!"
			cheese_label.add_theme_font_size_override("font_size", 32)
			cheese_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			cheese_label.position = Vector2(400, 380)
			cheese_label.z_index = 50
			add_child(cheese_label)

		get_tree().create_timer(3.0).timeout.connect(
			func(): get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		)
