extends Control


# Called when the node enters the scene tree for the first time.
@export var window:Window = null

var direction = Vector2i(1, 1)
var screen_size = DisplayServer.screen_get_size()

func _ready():
	pass
	#get_tree().root.add_child(window)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if (window.position.x + 256 >= screen_size.x):
		direction.x = -1
	elif (window.position.x <= 0):
		direction.x = 1
	
	if (window.position.y + 256 >= screen_size.y):
		direction.y = -1
	elif (window.position.y <= 0):
		direction.y = 1
	
	
	#print(window.position.x)
	
	window.position.x += delta * 400 * direction.x
	window.position.y += delta * 400 * direction.y


func _on_window_close_requested():
	window.hide()
