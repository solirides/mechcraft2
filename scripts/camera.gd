extends Node2D


@export var zoom_speed = 0.2
@export var background:Node = null
@export var camera:Node = null

@onready var duration_timer = Timer.new()
@onready var frequency_timer = Timer.new()

var shake_frequency:float = 1.0
var shake_duration = 1
var shake_amp = 1
var shake_level = 0

#@onready var frequency_tween = Tween
#@onready var duration_tween = Tween
@onready var tween = Tween

# the total number of times zoomed in
var status = 0

var zoom_base = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_child(duration_timer)
	self.add_child(frequency_timer)
	duration_timer.timeout.connect(_on_duration_timer_timeout)
	frequency_timer.timeout.connect(_on_frequency_timer_timeout)
	pass # Replace with function body.

func _input(event: InputEvent):
	if event.is_action_pressed("zoom_in"):
		status += 1
		zoom(1)
	if event.is_action_pressed("zoom_out"):
		#camera_shake(1, 18, 30, 10)
		if(status > -1) :
			status -= 1
			zoom(-1)
		
	if event.is_action_pressed("quit"):
		get_tree().quit()

func zoom(direction):
#	print(self.get_zoom())
	# recursion = ridiculous floating point errors
	var a = direction * zoom_speed
	zoom_base *= pow(zoom_speed, -direction)
	
	#self.position = (a/(1 + a)) * (-get_screen_center_position() + get_global_mouse_position()) + get_screen_center_position()
	camera.position = (a/(1 + a)) * (-camera.get_screen_center_position() + camera.get_global_mouse_position()) + camera.get_screen_center_position()

	camera.set_zoom(camera.get_zoom() * (1 + a))
	#self.set_zoom(Vector2(zoom_base, zoom_base))

func _process(delta):
	background.draw_grid(camera.get_global_transform().origin, camera.get_zoom().x)

func camera_shake(duration = 0.1, amplitude = 16, frequency:float = 10, level = 0):
	if level >= shake_level:
		shake_level = level
		shake_amp = amplitude
		shake_frequency = frequency
		shake_duration = duration
		
		#print(duration_timer)
		
		duration_timer.wait_time = duration
		duration_timer.start()
		frequency_timer.wait_time = 1.0 / frequency
		frequency_timer.start()
		
		#print(frequency_timer.wait_time)
		#print("shake")

func shake():
	var random = Vector2()
	random.x = randf_range(-shake_amp, shake_amp)
	random.y = randf_range(-shake_amp, shake_amp)
	
	tween = self.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel()
	tween.tween_property(self, "position", random, 1.0 / shake_frequency)
	#tween.tween_property(camera, "offset", random, 1 / shake_frequency)
	tween.finished.connect(_on_tween_finished)
	
	#print(1.0 / shake_frequency)

func _on_tween_finished():
	#print("tween")
	tween.kill()

func _on_frequency_timer_timeout():
	shake()
	#print("frequency")

func _on_duration_timer_timeout():
	camera.offset.x = 0
	camera.offset.y = 0
	shake_level = 0
	frequency_timer.stop()
