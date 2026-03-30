extends RigidBody2D

enum LogType { NORMAL, GREEN, GOLD }

var log_type: int = LogType.NORMAL
var hits_received := 0
var scored := false
var jumped_over := false
var hit_cooldown := 0.0
var lifetime := 90.0
var was_falling := false
var land_count := 0

const BOUNCE_VELOCITY := -280.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if position.y > 800 or position.x < -100 or position.x > 1400:
		queue_free()
		return

	if hit_cooldown > 0:
		hit_cooldown -= delta

	# Dampen horizontal velocity while falling to keep logs on platforms
	if abs(linear_velocity.y) > 80:
		linear_velocity.x *= 0.94
		was_falling = true
	elif was_falling:
		# Just landed - flip direction with 90% magnitude for downhill roll
		# Skip the first landing (spawn drop onto top platform)
		land_count += 1
		if land_count > 1:
			linear_velocity.x = -linear_velocity.x * 0.9
		was_falling = false

	# Jump-over detection
	if not jumped_over and not scored:
		var player_node = get_tree().current_scene.get_node_or_null("Player")
		if player_node:
			var radius := 14.0
			if abs(position.x - player_node.position.x) < 30:
				if player_node.position.y < position.y - radius and player_node.position.y > position.y - 80:
					if not player_node.is_on_floor():
						jumped_over = true
						var level = get_tree().current_scene
						if level.has_method("add_score"):
							var points := 20 if log_type == LogType.GOLD else 10
							level.add_score(points)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player" or scored or hit_cooldown > 0:
		return

	var radius := 14.0
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col_shape and col_shape.shape is CircleShape2D:
		radius = col_shape.shape.radius

	# Top 20% of hitbox check
	if body.global_position.y < global_position.y - radius * 0.6:
		# Top hit - bounce the player
		body.velocity.y = BOUNCE_VELOCITY
		hit_cooldown = 0.3
		hits_received += 1

		if hits_received >= 1:
			scored = true
			var level = get_tree().current_scene
			if level.has_method("add_score"):
				var points := 20
				if log_type == LogType.GOLD:
					points = 40
				level.add_score(points)
			_despawn()
		return

	# Side hit - damage player
	var level = get_tree().current_scene
	if level.has_method("player_hit_by_obstacle"):
		level.player_hit_by_obstacle()

func _despawn() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
