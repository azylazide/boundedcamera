extends ClassicalRemoteCamera

func _physics_process(delta: float) -> void:
	super(delta)

	var debug_string = "cam: (%.00f,%.00f)\nL: %.00f R: %.00f\nT: %.00f B: %.00f"
	var format_array = [global_position.x,global_position.y,bounds.left,bounds.right,bounds.top,bounds.bottom]

	DebugTexts.get_node("Control/HBoxContainer/Label").text = debug_string %format_array

func _on_camera_detector_area_entered(area: Area2D) -> void:
	append_area(area)

func _on_camera_detector_area_exited(area: Area2D) -> void:
	remove_area(area)
