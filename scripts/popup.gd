extends Panel



@export var label:Label= null
@export var button1:Button = null
@export var button2:Button = null
var pid = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_1_pressed():
	
	#OS.execute("godot", [args])
	var path = ProjectSettings.globalize_path("res://supersecretbossfight.pck")
	#var args = "--path  \"" + path + "\""
	pid = OS.execute("godot", ["--main-pack", path])
	#print(args)
	#get_tree().change_scene_to_file("res://supersecretbossfight/scenes/level1.tscn")
	self.visible = false


func _on_button_2_pressed():
	self.visible = false
