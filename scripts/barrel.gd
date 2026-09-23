extends RigidBody2D

# Techno's barrel. Drops to the ground and rolls toward the player (leftward).
# Hitting the player triggers a death; shooting it awards points.

var roll_speed := 260.0
var points := 25
var dead := false

func _ready() -> void:
	add_to_group("barrels")
	gravity_scale = 1.6
	mass = 1.5
	contact_monitor = true
	max_contacts_reported = 4
	# Layer 1 = collide with platforms + player; layer 5 = detectable by bullets.
	collision_layer = 1
	set_collision_layer_value(5, true)
	collision_mask = 1
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.15
	physics_material_override.friction = 0.4

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)

	_build_visual()

	body_entered.connect(_on_body_entered)
	linear_velocity = Vector2(-roll_speed, 0)
	angular_velocity = -roll_speed / 16.0
	get_tree().create_timer(60.0).timeout.connect(queue_free)

func _physics_process(_delta: float) -> void:
	if position.y > 900 or position.x < -80:
		queue_free()
		return
	# Keep it rolling toward the player even after bumps.
	if not dead and linear_velocity.x > -roll_speed * 0.6:
		linear_velocity.x = -roll_speed

func _on_body_entered(body: Node) -> void:
	if dead:
		return
	if body.name == "Player":
		dead = true
		var level := get_tree().current_scene
		if level.has_method("player_hit_by_obstacle"):
			level.player_hit_by_obstacle()
		queue_free()

func hit_by_bullet() -> void:
	if dead:
		return
	dead = true
	var level := get_tree().current_scene
	if level.has_method("add_score"):
		level.add_score(points)
	if level.has_method("spawn_hit_effect"):
		level.spawn_hit_effect(global_position)
	queue_free()

func _build_visual() -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-13, -16), Vector2(13, -16),
		Vector2(16, 0), Vector2(13, 16),
		Vector2(-13, 16), Vector2(-16, 0),
	])
	body.color = Color(0.55, 0.32, 0.13)
	add_child(body)

	# Vertical staves
	for sx in [-8, 0, 8]:
		var stave := Polygon2D.new()
		stave.polygon = PackedVector2Array([
			Vector2(sx - 1, -15), Vector2(sx + 1, -15),
			Vector2(sx + 1, 15), Vector2(sx - 1, 15),
		])
		stave.color = Color(0.42, 0.24, 0.09)
		add_child(stave)

	# Metal bands
	for by in [-9, 9]:
		var band := Polygon2D.new()
		band.polygon = PackedVector2Array([
			Vector2(-15, by - 2), Vector2(15, by - 2),
			Vector2(15, by + 2), Vector2(-15, by + 2),
		])
		band.color = Color(0.3, 0.3, 0.33)
		add_child(band)

	var hi := Polygon2D.new()
	hi.polygon = PackedVector2Array([
		Vector2(-6, -13), Vector2(-3, -13),
		Vector2(-3, 13), Vector2(-6, 13),
	])
	hi.color = Color(0.66, 0.42, 0.2)
	add_child(hi)
