@tool
extends EditorScript


var paths = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _run():
	files(32)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#if Input.is_action_just_pressed("debug"):
		#files(32)

func files(tile_size:int):
	var path = "res://assets/tiles/"
	var dir = DirAccess.open(path)
	
	var file_data = FileAccess.open("res://assets/tiles.json", FileAccess.READ)
	var json_thing = JSON.new()
	json_thing.parse(file_data.get_as_text())
	var tile_metadata = json_thing.get_data()
	
	print("start finding textures")
	
	if dir:
		dir.list_dir_begin()
		print("dir exists")
		#var file_name = dir.get_next()
		for file_name in dir.get_files():
			#print(file_name)
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			elif file_name.ends_with(".png"):
				print("Found file: " + file_name)
				print(path + file_name)
				var image = ResourceLoader.load(path + file_name)
				image.resize(32,32,0)
				var texture = ImageTexture.create_from_image(image)
				
				if (tile_metadata.has(file_name.trim_suffix(".png"))):
					var tile = tile_metadata[file_name.trim_suffix(".png")]
				
					paths[str(tile["id"])] = path + file_name
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")
	
	file_data = null
	dir = null
	
	print(paths)
	
