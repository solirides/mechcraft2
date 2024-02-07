extends Camera2D


@export var zoom_speed = 0.2
@export var background:Node = null

# the total number of times zoomed in
var status = 0

var zoom_base = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event: InputEvent):
	if event.is_action_pressed("zoom_in"):
		status += 1
		zoom(1)
	if event.is_action_pressed("zoom_out"):
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
	self.position = (a/(1 + a)) * (-get_screen_center_position() + get_global_mouse_position()) + get_screen_center_position()

	self.set_zoom(self.get_zoom() * (1 + a))
	#self.set_zoom(Vector2(zoom_base, zoom_base))

func _process(delta):
	background.draw_grid(self.get_global_transform().origin, self.get_zoom().x)
