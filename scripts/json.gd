extends Node

class_name Json

var json: Dictionary
var write_json: Dictionary
var world = WorldSave.new()
var recipes: Dictionary
var tileset:TileSet
#var bounds:Rect2i = Rect2i()

var world_properties = ["world_size", "chunk_size", "world_name", "elapsed_ticks"]

func _ready():
	pass
	#print(json["chunks"][0]["tiles"])
	

func setup(tile_size:int):
	json = read_json("res://assets/world_2.json")
	recipes = read_json("res://assets/recipes.json")
	
	tileset = make_tileset_exist(tile_size)
	ResourceSaver.save(tileset, "res://generated_tileset.tres")
	
	load_save()

func read_json(file_path):
	var json_data
	var file_data = FileAccess.open(file_path, FileAccess.READ)
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(file_data.get_as_text())
	json_data = test_json_conv.get_data()
	
	if file_data.get_error() == OK:
		pass
		#print(json_data)
	else:
		print("Error: ", json_data.error)
		print("Error Line: ", json_data.error_line)
		print("Error String: ", json_data.error_string)
	
	file_data = null
	return json_data


func write_save(file_path):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(write_json))
	

func create_save():
	for p in world_properties:
		write_json[p] = world.get(p)
	write_json["chunks"] = {}
	
	for i in world.world_size**2:
		write_json["chunks"][i] = {}
	
	save_data_int("tiles")
	save_data_int("items")
	save_data_int("noise")
	save_data_int("tile_storage")
	save_tiledata()
	
	#print(write_json)

func save_data_int(property:String):
	for i in len(world.get(property)):
		write_json["chunks"][i][property] = world.get(property)[i]
	

func save_tiledata():
	for i in len(world.tiledata):
		write_json["chunks"][i]["tiledata"] = world.tiledata[i]

func load_save():
	for p in world_properties:
		world.set(p, json[p])
	#world.world_size = json["world_size"]
	#world.chunk_size = json["chunk_size"]
	world.bounds = Rect2i(0, 0, world.world_size * world.chunk_size, world.world_size * world.chunk_size)
	world.chunk_area = pow(world.chunk_size, 2)
	
	world.tiles = load_data_int("tiles", 0)
	world.items = load_data_int("items", 0)
	world.noise = load_data_int("noise", 0)
	world.tile_storage = load_data_int("tile_storage", 0)
	world.tiledata = load_tiledata()

func load_data_int(property:String, default_value:int = 0):
	var data = []
	print("loading world data")
	for i in len(json["chunks"]):
		#print(i)
		#print(property)
		data.append(PackedInt32Array(json["chunks"][str(i)][property]))
	
	# fill missing chunks
	var a:PackedInt32Array = []
	a.resize(pow(world.chunk_size, 2))
	a.fill(default_value)
	for i in pow(world.world_size, 2) - len(data):
		data.append(a.duplicate())
	
	return data

func load_tiledata():
	var data = []
	print("loading world tiledata")
	#print(json["chunks"][0])
	for i in len(json["chunks"]):
		data.append(json["chunks"][str(i)]["tiledata"])
#		print(world[0]["rotation"])
	
	# fill missing chunks
	var a:PackedInt32Array = []
	a.resize(pow(world.chunk_size, 2))
	a.fill(0)
	#var d:Dictionary = {"storage": a, "rotation": a, "state": a}
	for i in pow(world.world_size, 2) - len(data):
		data.append({"storage": a.duplicate(), "rotation": a.duplicate(), "state": a.duplicate()})
	
	return data

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
					source.create_tile(Vector2i(0,0))
					
					for i in range(3):
						source.create_alternative_tile(Vector2i(0,0), -1)
					
					for i in tile["flip_h"]:
						source.get_tile_data(Vector2i(0,0), i).flip_h = true
					for i in tile["flip_v"]:
						source.get_tile_data(Vector2i(0,0), i).flip_v = true
					for i in tile["transpose"]:
						source.get_tile_data(Vector2i(0,0), i).transpose = true
					
					ts.add_source(source, tile["id"])
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")
	
	return ts

