extends Area2D
class_name CameraArea

@export var priority_level:= 0
@export_flags("Left","Right","Top","Bottom") var limit_flags:= 0b1111


@onready var collision:= $CollisionShape2D


var limits = {}

func _init() -> void:
	monitoring = false
	set_collision_layer_value(1,false)
	set_collision_layer_value(5,true)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#compute limits in global coords
	limits["left"] = collision.global_position.x-collision.shape.extents.x
	limits["right"] = collision.global_position.x+collision.shape.extents.x
	limits["top"] = collision.global_position.y-collision.shape.extents.y
	limits["bottom"] = collision.global_position.y+collision.shape.extents.y
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
