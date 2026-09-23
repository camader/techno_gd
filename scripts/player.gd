extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -350.0
const CLIMB_SPEED := 150.0
const GRAVITY := 800.0

var is_climbing := false
var climb_areas: int = 0
var descend_start_y := -1.0
var is_dead := false

# Level-configurable so the same controller works in the single-screen level 1
# and the wide side-scrolling level 2.
var max_x := 1280.0
var spawn_point := Vector2(1100, 620)
var can_shoot := false

const BULLET_SCRIPT := preload("res://scripts/bullet.gd")

signal died

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready() -> void:
	_load_character_sprites()
	anim_sprite.animation_finished.connect(_on_anim_finished)
	anim_sprite.play("idle")

# Characters backed by a prebuilt SpriteFrames resource (pixel-art sheets) instead of
# the 256px per-frame render pipeline. scale/offset align the smaller art to the
# collision box and ground.
const SPRITE_FRAME_OVERRIDES := {
	"volton": {
		"res": "res://assets/characters/volton/volton.tres",
		"scale": Vector2(1.4, 1.4),
		"offset": Vector2(0, -17),
	},
}

func _load_character_sprites() -> void:
	var char_name: String = GameState.selected_character
	if SPRITE_FRAME_OVERRIDES.has(char_name):
		var cfg: Dictionary = SPRITE_FRAME_OVERRIDES[char_name]
		anim_sprite.sprite_frames = load(cfg["res"])
		anim_sprite.scale = cfg["scale"]
		anim_sprite.offset = cfg["offset"]
		return
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
	if is_dead:
		return
	var input_dir := Input.get_axis("ui_left", "ui_right")
	var climb_input := Input.get_axis("ui_down", "ui_up")

	if is_climbing and climb_areas > 0:
		if climb_input < 0:  # descending
			if descend_start_y < 0:
				descend_start_y = position.y
			if position.y < descend_start_y + 35.0:
				set_collision_mask_value(1, false)  # pass through starting platform
			else:
				set_collision_mask_value(1, true)   # let lower platform catch player
		else:
			descend_start_y = -1.0
			set_collision_mask_value(1, false)  # pass through platforms when ascending
		velocity.y = -climb_input * CLIMB_SPEED
		velocity.x = input_dir * SPEED * 0.5
		if climb_areas <= 0 or (is_on_floor() and climb_input == 0):
			is_climbing = false
			descend_start_y = -1.0
			set_collision_mask_value(1, true)
	else:
		set_collision_mask_value(1, true)
		is_climbing = false
		descend_start_y = -1.0
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

	# Clamp to level bounds
	position.x = clamp(position.x, 0, max_x)

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
	if can_shoot and not is_dead and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot(get_global_mouse_position())
	if climb_areas > 0:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			is_climbing = true

func _respawn() -> void:
	position = spawn_point
	velocity = Vector2.ZERO
	is_dead = false
	anim_sprite.play("idle")

func shoot(target: Vector2) -> void:
	var facing := -18.0 if anim_sprite.flip_h else 18.0
	var muzzle := global_position + Vector2(facing, -6)
	var dir := target - muzzle
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	anim_sprite.flip_h = dir.x < 0
	var b := Area2D.new()
	b.set_script(BULLET_SCRIPT)
	get_parent().add_child(b)
	b.global_position = muzzle
	b.velocity = dir * b.speed

func play_death() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	anim_sprite.play("death")

func _on_anim_finished() -> void:
	if anim_sprite.animation == "death":
		died.emit()
