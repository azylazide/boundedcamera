extends Camera2D
class_name ClassicalRemoteCamera
## [RemoteCamera] with no custom interpolation.
##
## Primarily updates [member limit_left], [member limit_right], [member limit_top], and [member limit_bottom].
## Relies on built-in smoothing ([member position_smoothing_enabled], [member limit_smoothed]) and other features. Will follow parent [Node2D].

@export_group("Editor")
## Draw  the center of the camera.
@export var debug_draw:= true

## Current [CameraArea]s overlapped for bounds calculation.
var bbox_array: Array[CameraArea] = []
## Large integer that denotes no bounds.
var bridge_inf:= limit_right

## Current bounds used by the camera.
var bounds: BoundsContainer

signal camera_area_added(area: CameraArea)
signal camera_area_removed(area: CameraArea)

class BoundsContainer:
## Class that stores limits.
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
## Class that stores an array of limits taken from [member bbox_array].
	var left: Array[int] = []
	var right: Array[int] = []
	var top: Array[int] = []
	var bottom: Array[int] = []
	## Priority of using this current bounds. Higher value is higher priority.
	var priority: Array[int] = []

func _ready() -> void:
	bounds = BoundsContainer.new(bridge_inf)

func _draw() -> void:
	if debug_draw:
		draw_circle(to_local(get_screen_center_position()),5,Color.WHEAT)

func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	bounds = _calculate_limits()
	_update_bounds(bounds)
	if debug_draw:
		queue_redraw()

## Returns [member ClassicalRemoteCamera.BoundsContainer] calculated from [member bbox_array].
func _calculate_limits() -> BoundsContainer:
	## Initialize default limits.
	var default_limits: BoundsContainer = BoundsContainer.new(bridge_inf)

	## If inside a region.
	if not bbox_array.is_empty():
		var limit_arrays: LimitArrayContainer = LimitArrayContainer.new()

		## Assign to limit arrays the corresponding values, dependent on [member CameraArea.limit_flags].
		for area in bbox_array:
			limit_arrays.left.append(int(area.limits.left) if area.limit_flags & 0b1 else default_limits.left)
			limit_arrays.right.append(int(area.limits.right) if area.limit_flags & 0b1 << 1 else default_limits.right)
			limit_arrays.top.append(int(area.limits.top) if area.limit_flags & 0b1 << 2 else default_limits.top)
			limit_arrays.bottom.append(int(area.limits.bottom) if area.limit_flags & 0b1 << 3 else default_limits.bottom)

			limit_arrays.priority.append(area.priority_level)

		## Find the maximum priority among the current [CameraArea]s.
		var max_priority: int = limit_arrays.priority.max()

		var temp_limits: BoundsContainer = BoundsContainer.new(bridge_inf)
		## Assign temporary limits based on limits with corresponding maximum priority.
		temp_limits.left = limit_arrays.left[limit_arrays.priority.find(max_priority)]
		temp_limits.right = limit_arrays.right[limit_arrays.priority.find(max_priority)]
		temp_limits.top = limit_arrays.top[limit_arrays.priority.find(max_priority)]
		temp_limits.bottom = limit_arrays.bottom[limit_arrays.priority.find(max_priority)]

		## Check for multiple equal [member max_priority].
		if limit_arrays.priority.count(max_priority) > 1:
			var max_indices: Array[int] = []
			## Save the indices of the max priorities.
			for i in limit_arrays.priority.size():
				if limit_arrays.priority[i] == max_priority:
					max_indices.append(i)

			## Use the more limiting bounds.
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

	## Not inside any region.
	else:

		return default_limits

## Update [Camera2D] limits.
func _update_bounds(bound: BoundsContainer):
	limit_left = bound.left
	limit_right = bound.right
	limit_top = bound.top
	limit_bottom = bound.bottom

## Appends a [CameraArea] to [member bbox_array].
## [br]Main point of entry to use the remote camera.
func append_area(area: CameraArea) -> void:
	if area is CameraArea:
		bbox_array.append(area)
		camera_area_added.emit(area)

## Removes a [CameraArea] from [member bbox_array].
## [br]Second point of entry to use the remote camera.
func remove_area(area: CameraArea) -> void:
	if area is CameraArea:
		bbox_array.erase(area)
		camera_area_removed.emit(area)

