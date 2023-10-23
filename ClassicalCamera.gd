extends Camera2D

@export var playernode: CharacterBody2D

var bbox_array: = []
var bridge_inf:= limit_right

var bounds = {"left":-bridge_inf,
				"right":bridge_inf,
				"top":-bridge_inf,
				"bottom":bridge_inf}

var clamped_pos: Vector2

@onready var screen_size:= get_viewport_rect().size
@onready var camera_span:= Vector2(screen_size.x/zoom.x,screen_size.y/zoom.y)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await playernode.ready
#	await cameraboundcontainer.ready
	playernode.camera_bound_detector.area_entered.connect(on_CameraBBoxDetector_area_entered)
	playernode.camera_bound_detector.area_exited.connect(on_CameraBBoxDetector_area_exited)
	#on player queue free


	DebugTexts.get_node("Control/HBoxContainer/Label2").text = str(get_viewport_rect())
	DebugTexts.get_node("Control/HBoxContainer/Label3").text = str(get_viewport_rect().size /zoom.x)
	pass # Replace with function body.

func _draw() -> void:
	draw_circle(to_local(global_position),5,Color.WHEAT)
	_draw_camera_clamp()
	pass

func _draw_camera_clamp() -> void:
	if not bbox_array.is_empty():
		if bounds.left != -bridge_inf:
			draw_line(to_local(Vector2(bounds.left+0.5*camera_span.x,global_position.y-300)),to_local(Vector2(bounds.left+0.5*camera_span.x,global_position.y+300)),Color.RED)
		if bounds.right != bridge_inf:
			draw_line(to_local(Vector2(bounds.right-0.5*camera_span.x,global_position.y-300)),to_local(Vector2(bounds.right-0.5*camera_span.x,global_position.y+300)),Color.BLUE)
		if bounds.top != -bridge_inf:
			draw_line(to_local(Vector2(global_position.x-300,bounds.top+0.5*camera_span.y)),to_local(Vector2(global_position.x+300,bounds.top+0.5*camera_span.y)),Color.RED)
		if bounds.bottom != bridge_inf:
			draw_line(to_local(Vector2(global_position.x-300,bounds.bottom-0.5*camera_span.y)),to_local(Vector2(global_position.x+300,bounds.bottom-0.5*camera_span.y)),Color.BLUE)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	var new_pos:= _update_position()
	clamped_pos = _clamp_pos(new_pos)
	queue_redraw()

func _update_position() -> Vector2:
	return playernode.global_position

func _clamp_pos(pos: Vector2) -> Vector2:
	var output: Vector2

	var default_limits = {"left":-bridge_inf,"right":bridge_inf,"top":-bridge_inf,"bottom":bridge_inf}

	#when intersecting
	if not bbox_array.is_empty():
		var limit_arrays = {"left":[],"right":[],"top":[],"bottom":[],"priority":[]}

		for area in bbox_array:
			limit_arrays.left.append(int(area.limits.left) if area.limit_flags & 0b1000 else default_limits.left)
			limit_arrays.right.append(int(area.limits.right) if area.limit_flags & 0b0100 else default_limits.right)
			limit_arrays.top.append(int(area.limits.top) if area.limit_flags & 0b0010 else default_limits.top)
			limit_arrays.bottom.append(int(area.limits.bottom) if area.limit_flags & 0b0001 else default_limits.bottom)

			limit_arrays.priority.append(area.priority_level)

		var max_priority: int = limit_arrays.priority.max()

		var temp_limits = {"left":limit_arrays.left[limit_arrays.priority.find(max_priority)],
							"right":limit_arrays.right[limit_arrays.priority.find(max_priority)],
							"top":limit_arrays.top[limit_arrays.priority.find(max_priority)],
							"bottom":limit_arrays.bottom[limit_arrays.priority.find(max_priority)]}

		if limit_arrays.priority.count(max_priority) > 1:
			var max_indices = []
			for i in limit_arrays.priority.size():
				if limit_arrays.priority[i] == max_priority:
					max_indices.append(i)

			for i in max_indices:
				if abs(temp_limits.left) < abs(limit_arrays.left[i]):
					temp_limits.left = limit_arrays.left[i]
				if abs(temp_limits.right) < abs(limit_arrays.right[i]):
					temp_limits.right = limit_arrays.right[i]
				if abs(temp_limits.top) < abs(limit_arrays.top[i]):
					temp_limits.top = limit_arrays.top[i]
				if abs(temp_limits.bottom) < abs(limit_arrays.bottom[i]):
					temp_limits.bottom = limit_arrays.bottom[i]

#		output.x = clampf(pos.x,temp_limits.left+0.5*camera_span.x,temp_limits.right-0.5*camera_span.x)
#		output.y = clampf(pos.y,temp_limits.top+0.5*camera_span.y,temp_limits.bottom-0.5*camera_span.y)

		limit_left = temp_limits.left
		limit_right = temp_limits.right
		limit_top = temp_limits.top
		limit_bottom = temp_limits.bottom

		bounds.left = temp_limits.left
		bounds.right = temp_limits.right
		bounds.top = temp_limits.top
		bounds.bottom = temp_limits.bottom


	#if detector exited

	else:
#		output.x = clampf(pos.x,default_limits.left+0.5*camera_span.x,default_limits.right-0.5*camera_span.x)
#		output.y = clampf(pos.y,default_limits.top+0.5*camera_span.y,default_limits.bottom-0.5*camera_span.y)

		limit_left = default_limits.left
		limit_right = default_limits.right
		limit_top = default_limits.top
		limit_bottom = default_limits.bottom

		bounds.left = default_limits.left
		bounds.right = default_limits.right
		bounds.top = default_limits.top
		bounds.bottom = default_limits.bottom


	var debug_string = "L: %.00f R: %.00f\nT: %.00f B: %.00f"
	var format_array = [bounds.left,bounds.right,bounds.top,bounds.bottom]

	DebugTexts.get_node("Control/HBoxContainer/Label").text = debug_string %format_array

	return output

func on_CameraBBoxDetector_area_entered(area: Area2D) -> void:
	bbox_array.append(area)

func on_CameraBBoxDetector_area_exited(area: Area2D) -> void:
	bbox_array.erase(area)
