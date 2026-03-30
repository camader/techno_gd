extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -350.0
const CLIMB_SPEED := 150.0
const GRAVITY := 800.0

var is_climbing := false
var climb_areas: int = 0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready() -> void:
	_load_character_sprites()
	anim_sprite.play("idle")

func _load_character_sprites() -> void:
	var char_name: String = GameState.selected_character
	var base_path := "res://assets/characters/%s/" % char_name
	var sprite_frames := SpriteFrames.new()

	var animations := {
		"idle": {"path": base_path + "idle/idle_%03d.png", "count": 24, "fps": 12.0, "loop": true},
		"walk": {"path": base_path + "walk/walk_%03d.png", "count": 16, "fps": 12.0, "loop": true},
		"jump": {"path": base_path + "jump/jump_%03d.png", "count": 20, "fps": 15.0, "loop": false},
		"climb": {"path": base_path + "climb/climb_%03d.png", "count": 20, "fps": 10.0, "loop": true},
		"death": {"path": base_path + "death/death_%03d.png", "count": 30, "fps": 15.0, "loop": false},
	}

	# Remove the default animation
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	for anim_name in animations:
		var info: Dictionary = animations[anim_name]
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, info["fps"])
		sprite_frames.set_animation_loop(anim_name, info["loop"])
		for i in range(1, info["count"] + 1):
			var path: String = info["path"] % i
			var tex := load(path)
			if tex:
				sprite_frames.add_frame(anim_name, tex)

	anim_sprite.sprite_frames = sprite_frames

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("ui_left", "ui_right")
	var climb_input := Input.get_axis("ui_down", "ui_up")

	if is_climbing and climb_areas > 0:
		set_collision_mask_value(1, false)
		velocity.y = -climb_input * CLIMB_SPEED
		velocity.x = input_dir * SPEED * 0.5
		if climb_areas <= 0 or (is_on_floor() and climb_input == 0):
			is_climbing = false
			set_collision_mask_value(1, true)
	else:
		set_collision_mask_value(1, true)
		is_climbing = false
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		velocity.x = input_dir * SPEED

	move_and_slide()

	# Update animation
	_update_animation(input_dir)

	# Flip sprite based on direction
	if input_dir < 0:
		anim_sprite.flip_h = true
	elif input_dir > 0:
		anim_sprite.flip_h = false

	# Clamp to screen bounds
	position.x = clamp(position.x, 0, 1280)

	# Fell off screen - respawn
	if position.y > 800:
		_respawn()

func _update_animation(input_dir: float) -> void:
	if is_climbing and climb_areas > 0:
		_play_if_different("climb")
	elif not is_on_floor():
		_play_if_different("jump")
	elif abs(input_dir) > 0.1:
		_play_if_different("walk")
	else:
		_play_if_different("idle")

func _play_if_different(anim_name: String) -> void:
	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)

func _on_climb_zone_entered(_area: Area2D) -> void:
	climb_areas += 1

func _on_climb_zone_exited(_area: Area2D) -> void:
	climb_areas -= 1
	if climb_areas <= 0:
		climb_areas = 0
		is_climbing = false
		set_collision_mask_value(1, true)

func _on_input_event() -> void:
	var climb_input := Input.get_axis("ui_down", "ui_up")
	if climb_areas > 0 and climb_input != 0:
		is_climbing = true

func _input(event: InputEvent) -> void:
	if climb_areas > 0:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			is_climbing = true

func _respawn() -> void:
	position = Vector2(1100, 620)
	velocity = Vector2.ZERO

func play_death() -> void:
	anim_sprite.play("death")
