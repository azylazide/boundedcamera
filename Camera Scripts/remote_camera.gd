extends Camera2D
class_name RemoteCamera

@export var followed_node: Node2D
@export var follow:= true
@export var initial_pos:= Vector2.ZERO

@export_group("Smoothing")
@export var vertical_smoothing:= 0.15
@export var horizontal_smoothing:= 0.15

@export_group("Editor")
@export var debug_draw:= true

var bbox_array: Array[CameraArea] = []
var bridge_inf:= limit_right

var bounds: BoundsContainer

var clamped_pos: Vector2
var interped_pos: Vector2

signal camera_area_added(area: Area2D)
signal camera_area_removed(area: Area2D)

@onready var screen_size:= get_viewport_rect().size
@onready var camera_span:= Vector2(screen_size.x/zoom.x,screen_size.y/zoom.y)

class BoundsContainer:
	var _large_value: int
	var left: int
	var right: int
	var top: int
	var bottom: int
	func _init(large_value: int) -> void:
		left = -large_value
		right = large_value
		top = -large_value
		bottom = large_value

class LimitArrayContainer:
	var left: Array[float] = []
	var right: Array[float] = []
	var top: Array[float] = []
	var bottom: Array[float] = []
	var priority: Array[int] = []

func _ready() -> void:
	bounds = BoundsContainer.new(bridge_inf)
	if follow:
		global_position = followed_node.global_position
	else:
		global_position = initial_pos + offset

func _draw() -> void:
	if debug_draw:
		draw_circle(to_local(global_position),5,Color.WHEAT)
		_draw_camera_clamp()

func _draw_camera_clamp() -> void:
	if not bbox_array.is_empty():
		if bounds.left != -bridge_inf:
			draw_line(to_local(Vector2(bounds.left+0.5*camera_span.x,global_position.y-300)),to_local(Vector2(bounds.left+0.5*camera_span.x,global_position.y+300)),Color.RED)
		if bounds.right != bridge_inf:
			draw_line(to_local(Vector2(bounds.right-0.5*camera_span.x,global_position.y-300)),to_local(Vector2(bounds.right-0.5*camera_span.x,global_position.y+300)),Color.RED)
		if bounds.top != -bridge_inf:
			draw_line(to_local(Vector2(global_position.x-300,bounds.top+0.5*camera_span.y)),to_local(Vector2(global_position.x+300,bounds.top+0.5*camera_span.y)),Color.RED)
		if bounds.bottom != bridge_inf:
			draw_line(to_local(Vector2(global_position.x-300,bounds.bottom-0.5*camera_span.y)),to_local(Vector2(global_position.x+300,bounds.bottom-0.5*camera_span.y)),Color.RED)


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	process_camera_position()

func process_camera_position() -> void:
	var new_pos:= _updated_position()
	bounds = calculate_limits()
	clamped_pos = _clamp_pos(new_pos)
	interped_pos = _interp_pos(global_position)

	if follow:
		global_position = interped_pos
	queue_redraw()

func _updated_position() -> Vector2:
	return followed_node.global_position + offset

func calculate_limits() -> BoundsContainer:

	var default_limits: BoundsContainer = BoundsContainer.new(bridge_inf)

	#when intersecting
	if not bbox_array.is_empty():
		var limit_arrays: LimitArrayContainer = LimitArrayContainer.new()

		for area in bbox_array:
			limit_arrays.left.append(int(area.limits.left) if area.limit_flags & 0b1 else default_limits.left)
			limit_arrays.right.append(int(area.limits.right) if area.limit_flags & 0b1 << 1 else default_limits.right)
			limit_arrays.top.append(int(area.limits.top) if area.limit_flags & 0b1 << 2 else default_limits.top)
			limit_arrays.bottom.append(int(area.limits.bottom) if area.limit_flags & 0b1 << 3 else default_limits.bottom)

			limit_arrays.priority.append(area.priority_level)

		var max_priority: int = limit_arrays.priority.max()

		var temp_limits: BoundsContainer = BoundsContainer.new(bridge_inf)
		temp_limits.left = limit_arrays.left[limit_arrays.priority.find(max_priority)]
		temp_limits.right = limit_arrays.right[limit_arrays.priority.find(max_priority)]
		temp_limits.top = limit_arrays.top[limit_arrays.priority.find(max_priority)]
		temp_limits.bottom = limit_arrays.bottom[limit_arrays.priority.find(max_priority)]

		if limit_arrays.priority.count(max_priority) > 1:
			var max_indices: Array[int] = []
			for i in limit_arrays.priority.size():
				if limit_arrays.priority[i] == max_priority:
					max_indices.append(i)

			for i in max_indices:
				if absi(temp_limits.left) < absi(limit_arrays.left[i]):
					temp_limits.left = limit_arrays.left[i]
				if absi(temp_limits.right) < absi(limit_arrays.right[i]):
					temp_limits.right = limit_arrays.right[i]
				if absi(temp_limits.top) < absi(limit_arrays.top[i]):
					temp_limits.top = limit_arrays.top[i]
				if absi(temp_limits.bottom) < absi(limit_arrays.bottom[i]):
					temp_limits.bottom = limit_arrays.bottom[i]

		return temp_limits

	else:

		return default_limits

func _clamp_pos(pos: Vector2) -> Vector2:
	var output: Vector2

	output.x = clampf(pos.x,bounds.left+0.5*camera_span.x,bounds.right-0.5*camera_span.x)
	output.y = clampf(pos.y,bounds.top+0.5*camera_span.y,bounds.bottom-0.5*camera_span.y)

	return output

func _interp_pos(pos: Vector2) -> Vector2:
	var output: Vector2

	output.x = lerpf(pos.x,clamped_pos.x,horizontal_smoothing)
	output.y = lerpf(pos.y,clamped_pos.y,vertical_smoothing)

	return output

func append_area(area: CameraArea) -> void:
	if area is CameraArea:
		bbox_array.append(area)
		camera_area_added.emit(area)

func remove_area(area: CameraArea) -> void:
	if area is CameraArea:
		bbox_array.erase(area)
		camera_area_removed.emit(area)
