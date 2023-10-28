extends Area2D
class_name CameraArea

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
	limits = LimitContainer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_limits()

func set_limits() -> void:
	#compute limits in global coords
	limits.left = collision.global_position.x-collision.shape.get_rect().size.x*0.5
	limits.right = collision.global_position.x+collision.shape.get_rect().size.x*0.5
	limits.top = collision.global_position.y-collision.shape.get_rect().size.y*0.5
	limits.bottom = collision.global_position.y+collision.shape.get_rect().size.y*0.5
