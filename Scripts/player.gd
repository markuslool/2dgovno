extends CharacterBody2D
## Top-down персонаж-морф из двух спрайтов.
## Управление: WASD или стрелки — бег в 8 сторон.

@export var speed := 200.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _squash := Vector2.ONE
var _time := 0.0
var _was_moving := false

func _ready() -> void:
	anim.play(&"idle")

func _physics_process(delta: float) -> void:
	_time += delta

	# --- движение в 8 сторон (стрелки + WASD без настройки InputMap) ---
	var vec := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if vec == Vector2.ZERO:
		vec = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		)
	velocity = vec.limit_length(1.0) * speed
	move_and_slide()

	# --- сплющивание на старт/стоп ---
	var moving := velocity.length() > 10.0
	if moving and not _was_moving:
		_squash = Vector2(0.8, 1.2)
	elif not moving and _was_moving:
		_squash = Vector2(1.25, 0.75)
	_was_moving = moving

	_update_anim(delta)
	_update_squash(delta)

func _update_anim(delta: float) -> void:
	var moving := velocity.length() > 10.0
	if moving:
		if anim.animation != &"run":
			anim.play(&"run")
		if velocity.x != 0.0:
			anim.flip_h = velocity.x < 0.0
	else:
		if anim.animation != &"idle":
			anim.play(&"idle")
	# лёгкий наклон по направлению + покачивание в idle
	var target_rot := 0.0
	if moving:
		target_rot = clampf(velocity.x * 0.0009, -0.2, 0.2) + sin(_time * 10.0) * 0.04
	else:
		target_rot = sin(_time * 2.5) * 0.06
	anim.rotation = lerpf(anim.rotation, target_rot, minf(1.0, delta * 10.0))

func _update_squash(delta: float) -> void:
	# возврат к норме + «дыхание» в idle
	_squash = _squash.lerp(Vector2.ONE, minf(1.0, delta * 8.0))
	var pulse := Vector2.ZERO
	if velocity.length() < 10.0:
		pulse = Vector2(sin(_time * 6.0) * 0.04, sin(_time * 6.0 + PI) * 0.05)
	anim.scale = _squash + pulse
