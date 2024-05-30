extends Control



@export_category("Nodes")
@export var saves:Node = null
@export var buttons:Node = null

var savefile = preload("res://modules/level_selector/save_file/save_file.tscn")

var selected_file = ""

signal back
signal save

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var savefiles = {}
	var dir = DirAccess.open(Globals.saves_directory)
	
	if dir:
		dir.list_dir_begin()
		for file_name in dir.get_files():
			if dir.current_is_dir():
				continue
			if file_name.ends_with(".json"):
				print("Found file: " + file_name)
				
				var file_path = ProjectSettings.globalize_path(Globals.saves_directory + file_name)
				var json_data
				var file_data = FileAccess.open(file_path, FileAccess.READ)
				
				var json_conv = JSON.new()
				var error = json_conv.parse(file_data.get_as_text())
				
				if error != OK:
					continue
				
				json_data = json_conv.get_data()
				
				
				var a = savefile.instantiate()
				a.file_name = file_name
				a.get_node(^"VBoxContainer/Name").text = json_data["world_name"]
				a.get_node(^"VBoxContainer/FileName").text = file_name
				a.get_node(^"VBoxContainer/Date").text = Time.get_datetime_string_from_unix_time(json_data["unix_time"], true)
				
				savefiles[int(json_data["unix_time"])] = a
		
		var sorted = savefiles.keys()
		sorted.sort_custom(func(a, b): return a > b)
		
		for k in sorted:
			saves.add_child(savefiles[k])
			
			savefiles[k].clicked.connect(_on_save_file_clicked)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_save_file_clicked(file_name:String):
	selected_file = file_name
	Globals.save_file_name = file_name


func _on_load_pressed():
	if Globals.save_file_name != "":
		Globals.load_game_type = "load"
		get_tree().change_scene_to_file("res://modules/game/game.tscn")


func _on_save_pressed():
	save.emit()


func _on_delete_pressed():
	pass


func _on_back_pressed():
	back.emit()
	self.visible = false
