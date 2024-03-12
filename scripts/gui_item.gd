extends TextureRect


var slot = -1

signal clicked(slot)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_gui_input(event):
	if event.is_action_pressed("left_click"):
		self.clicked.emit(slot)
