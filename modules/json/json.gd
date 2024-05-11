extends Node

class_name Json


@export var saving_path:String = "res://assets/world_2.json"
@export var loading_path:String = "res://assets/world.json"

var json: Dictionary
var write_json: Dictionary
var world:Dictionary = {}
var recipes: Dictionary
var ores: Dictionary
var objectives: Dictionary
var tileset:TileSet
var tile_textures:Dictionary = {}
#var bounds:Rect2i = Rect2i()

var world_properties = ["seed", "world_size", "chunk_size", "world_name", "elapsed_ticks", "central_storage", "settings"]
var world_data_int = ["tiles", "items", "noise", "terrain", "integrity", "tile_storage", "rotation", "state"]

func _ready():
	pass
	#print(json["chunks"][0]["tiles"])
	

func setup(tile_size:int):
	json = read_json(loading_path)
	recipes = read_json("res://assets/recipes.json")
	ores = read_json("res://assets/ores.json")
	objectives = read_json("res://assets/objectives.json")
	
	tileset = make_tileset_exist(tile_size)
	ResourceSaver.save(tileset, "res://generated_tileset.tres")
	
	load_save()

func read_json(file_path:String = loading_path):
	var json_data
	var file_data = FileAccess.open(file_path, FileAccess.READ)
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(file_data.get_as_text())
	json_data = test_json_conv.get_data()
	
	if file_data.get_error() == OK:
		pass
		print(json_data)
	else:
		print("Error: ", json_data.error)
		print("Error Line: ", json_data.error_line)
		print("Error String: ", json_data.error_string)
	
	file_data = null
	return json_data


func write_save(file_path:String = saving_path):
	write_json = world
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(write_json))

func load_save():
	var world = json.duplicate()
	var a:Array = []
	a.resize(world["chunk_area"])
	a.fill(0)
	var keys = world["chunks"]["0"].keys()
	
	# create missing chunks
	for i in range(len(world["chunks"]), world["world_size"]**2):
		var b:Dictionary
		for k in keys:
			b[k] = a.duplicate()
		world["chunks"][str(i)] = b
	
	self.world = world


func make_tileset_exist(tile_size:int):
	var ts = TileSet.new()
	var id = 0
	var path = "res://assets/tiles/"
	var dir = DirAccess.open(path)
	
	var blank = TileSetAtlasSource.new()
	ts.add_source(blank)
	ts.tile_size = Vector2i(tile_size,tile_size)
	var file_data = FileAccess.open("res://assets/tiles.json", FileAccess.READ)
	var json_thing = JSON.new()
	json_thing.parse(file_data.get_as_text())
	var tile_metadata = json_thing.get_data()
	
	if dir:
		dir.list_dir_begin()
		#var file_name = dir.get_next()
		for file_name in dir.get_files():
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			elif file_name.ends_with(".png"):
				print("Found file: " + file_name)
				print(path + file_name)
				var image = Image.load_from_file(path + file_name)
				
				if (tile_metadata.has(file_name.get_basename())):
					var tile = tile_metadata[file_name.get_basename()]
					var source = TileSetAtlasSource.new()
					source.texture = ImageTexture.create_from_image(image)
					
					if image.get_height() == 32:
						source.texture_region_size = Vector2i(32, 32)
						#source.texture
					
					source.create_tile(Vector2i(0,0))
					
					if tile.has("rotatable") and tile["rotatable"] == 1:
						for i in range(3):
							source.create_alternative_tile(Vector2i(0,0), -1)
						
						for i in [1,2]:
							source.get_tile_data(Vector2i(0,0), i).flip_h = true
						for i in [2,3]:
							source.get_tile_data(Vector2i(0,0), i).flip_v = true
						for i in [1,3]:
							source.get_tile_data(Vector2i(0,0), i).transpose = true
					
					ts.add_source(source, tile["id"])
					tile_textures[int(tile["id"])] = file_name.get_basename()
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")
	
	return ts

func texture_from_tile(id:int):
	return load("res://assets/tiles/" + self.tile_textures[id] + ".png")
