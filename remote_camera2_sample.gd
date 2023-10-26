extends RemoteCamera2

@export var decay := 0.8 #How quickly shaking will stop [0,1].
@export var max_offset := Vector2(8,5) #Maximum displacement in pixels.
@export var max_roll = 0.0 #Maximum rotation in radians (use sparingly).
@export var noise : FastNoiseLite #The source of random values.

var noise_y = 0 #Value used to move through the noise

var trauma := 0.0 #Current shake strength
var trauma_pwr := 3 #Trauma exponent. Use [2,3]

func _ready():
	super()
	randomize()
	noise.seed = randi()

func add_trauma(amount : float):
	trauma = min(trauma + amount, 1.0)

func shake():
	var amt = pow(trauma, trauma_pwr)
	var _offset:= Vector2.ZERO
	noise_y += 1
	_offset.x = max_offset.x * amt * noise.get_noise_2d(noise.seed*2,noise_y)
	_offset.y = max_offset.y * amt * noise.get_noise_2d(noise.seed*3,noise_y)
	offset = _offset

func _process(delta):
	if not follow:
		if trauma:
			trauma = max(trauma - decay * delta, 0)
			shake()
		else:
			follow = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		follow = false
		add_trauma(5)
	if event.is_action_pressed("ui_cancel"):
		follow = true


func _on_area_2d_area_entered(area: Area2D) -> void:
	append_area(area)


func _on_area_2d_area_exited(area: Area2D) -> void:
	remove_area(area)

