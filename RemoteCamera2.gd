extends Camera2D
class_name RemoteCamera2

@export var followed_node: Node2D
@export var follow:= true
@export var initial_pos:= Vector2.ZERO
@export var vertical_smoothing:= 0.15
@export var horizontal_smoothing:= 0.15

var bbox_array: Array[CameraArea2] = []
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
	if not follow:
		global_position = initial_pos + offset

	DebugTexts.get_node("Control/HBoxContainer/Label2").text = str(get_viewport_rect())
	DebugTexts.get_node("Control/HBoxContainer/Label3").text = str(get_viewport_rect().size /zoom.x)

func _draw() -> void:
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
	clamped_pos = _clamp_pos(new_pos)
	interped_pos = _interp_pos(global_position)

	if follow:
		global_position = interped_pos
	queue_redraw()

func _updated_position() -> Vector2:
	return followed_node.global_position + offset

func _clamp_pos(pos: Vector2) -> Vector2:
	var output: Vector2

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

		output.x = clampf(pos.x,temp_limits.left+0.5*camera_span.x,temp_limits.right-0.5*camera_span.x)
		output.y = clampf(pos.y,temp_limits.top+0.5*camera_span.y,temp_limits.bottom-0.5*camera_span.y)

		bounds.left = temp_limits.left
		bounds.right = temp_limits.right
		bounds.top = temp_limits.top
		bounds.bottom = temp_limits.bottom


	#if detector exited

	else:
		output.x = clampf(pos.x,default_limits.left+0.5*camera_span.x,default_limits.right-0.5*camera_span.x)
		output.y = clampf(pos.y,default_limits.top+0.5*camera_span.y,default_limits.bottom-0.5*camera_span.y)

		bounds.left = default_limits.left
		bounds.right = default_limits.right
		bounds.top = default_limits.top
		bounds.bottom = default_limits.bottom


	var debug_string = "cam: (%.00f,%.00f) C(%.00f,%.00f)\nL: %.00f R: %.00f\nT: %.00f B: %.00f"
	var format_array = [global_position.x,global_position.y,clamped_pos.x,clamped_pos.y,bounds.left,bounds.right,bounds.top,bounds.bottom]

	DebugTexts.get_node("Control/HBoxContainer/Label").text = debug_string %format_array

	return output

func _interp_pos(pos: Vector2) -> Vector2:
	var output: Vector2

	output.x = lerpf(pos.x,clamped_pos.x,horizontal_smoothing)
	output.y = lerpf(pos.y,clamped_pos.y,vertical_smoothing)


	return output

func append_area(area: Area2D) -> void:
	bbox_array.append(area)
	camera_area_added.emit(area)

func remove_area(area: Area2D) -> void:
	bbox_array.erase(area)
	camera_area_removed.emit(area)
