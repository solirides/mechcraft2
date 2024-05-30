extends Panel



@export var label:Label= null
@export var button1:Button = null
@export var button2:Button = null
@export var tilemap:Node = null


var pid = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_1_pressed():
	
	tilemap.save_game()
	
	#var path = ProjectSettings.globalize_path("user://supersecretbossfight.pck")
	
	#DirAccess.make_dir_recursive_absolute("user://")
	#var dir = DirAccess.open("user://")
	#dir.copy("res://supersecretbossfight.pck", "user://supersecretbossfight.pck")
	#dir = null
	#
	#var output = []
	#
	#pid = OS.execute("godot", ["--main-pack", path], output)
	#print(output)
	#
	#OS.execute("godot", [args])
	#var path = ProjectSettings.globalize_path("res://downloads/movement-is-key-main.zip")
	#var args = "--path  \"" + path + "\""
	#get_tree().change_scene_to_file("res://supersecretbossfight/scenes/level1.tscn")
	
	
	if OS.has_feature("editor"):
		var result = ProjectSettings.load_resource_pack("res://supersecretbossfight.pck", true)
		print(result)
		get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")
	else:
		var path = OS.get_executable_path().get_base_dir() + "/supersecretbossfight.pck"
		print(path)
		OS.create_instance(["--main-pack", path])
		#get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")
	#get_tree().change_scene_to_file("res://supersecretbossfight.pck")
	
	
	
	
	self.visible = false


func _on_button_2_pressed():
	self.visible = false
