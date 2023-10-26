extends Area2D
class_name CameraArea2

@export var priority_level:= 0
@export_flags("Left","Right","Top","Bottom") var limit_flags:= 0b1111


@export var collision: CollisionShape2D

class LimitContainer:
	var left: float
	var right: float
	var top: float
	var bottom: float

var limits: LimitContainer

func _init() -> void:
	monitoring = false
	set_collision_layer_value(1,false)
	set_collision_layer_value(5,true)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	limits = LimitContainer.new()
	#compute limits in global coords
	limits.left = collision.global_position.x-collision.shape.extents.x
	limits.right = collision.global_position.x+collision.shape.extents.x
	limits.top = collision.global_position.y-collision.shape.extents.y
	limits.bottom = collision.global_position.y+collision.shape.extents.y
