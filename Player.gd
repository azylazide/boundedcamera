extends CharacterBody2D

@onready var camera_bound_detector:= $CameraBoundDetector

const SPEED = 600.0

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right","ui_up","ui_down")
	if direction:
		velocity = direction.normalized() * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()
