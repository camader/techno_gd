extends Area2D

# Player projectile. Flies in a straight line toward where the player clicked and
# pops any barrel it touches. Built entirely in code (no scene file needed).

var velocity := Vector2.ZERO
var speed := 1100.0
const LIFETIME := 1.4

func _ready() -> void:
	# Only detect barrels (collision layer bit 5); ignore ground/player.
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(5, true)
	monitoring = true

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	col.shape = shape
	add_child(col)

	var glow := Polygon2D.new()
	glow.polygon = _circle(7.0, 10)
	glow.color = Color(1.0, 0.8, 0.2, 0.35)
	add_child(glow)

	var core := Polygon2D.new()
	core.polygon = _circle(3.0, 8)
	core.color = Color(1.0, 0.95, 0.6)
	add_child(core)

	body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("barrels") and body.has_method("hit_by_bullet"):
		body.hit_by_bullet()
		queue_free()

func _circle(r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := i * TAU / n
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts
