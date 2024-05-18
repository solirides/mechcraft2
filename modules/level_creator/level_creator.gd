extends Control



@export_category("Nodes")
@export var name_label:Node = null


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_create_pressed():
	randomize()
	
	Globals.world_override_data["unix_time"] = Time.get_unix_time_from_system()
	Globals.world_override_data["world_name"] = name_label.text
	Globals.world_override_data["seed"] = randi()
	
	var regex = RegEx.new()
	regex.compile("\\w| |-")
	
	var file_name = ""
	
	for a in name_label.text:
		if regex.search(a):
			file_name += a
	
	if file_name == "":
		file_name = "world"
	
	file_name += ".json"
	
	Globals.save_file_name = file_name
	Globals.load_game_type = "new"
	
	get_tree().change_scene_to_file("res://modules/game/game.tscn")
	


func _on_back_pressed():
	pass # Replace with function body.
