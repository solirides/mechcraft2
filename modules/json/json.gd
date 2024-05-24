extends Node

class_name Json


@export var tilemap:Node = null
@export var world_gen:Node = null
@export_file var constructor_recipes_file:String = "res://assets/constructor_recipes.json"
@export_file var smelter_recipes_file:String = "res://assets/smelter_recipes.json"
@export_file var ores_file:String = "res://assets/ores.json"
@export_file var objectives_file:String = "res://assets/objectives.json"
var save_path:String = ""

var json: Dictionary
var write_json: Dictionary
var world:Dictionary = {}
var constructor_recipes: Dictionary
var smelter_recipes: Dictionary
var ores: Dictionary
var objectives: Dictionary
var tileset:TileSet
var tile_textures:Dictionary = {}
#var bounds:Rect2i = Rect2i()

var world_properties = ["seed", "world_size", "chunk_size", "world_name", "elapsed_ticks", "central_storage", "settings"]
var world_data_int = ["tiles", "items", "noise", "terrain", "integrity", "tile_storage", "rotation", "state"]

signal setup_complete

func _ready():
	load_world(Globals.load_game_type)
	setup_complete.emit()

func load_world(type:String):
	match type:
		"new":
			if Globals.save_file_name == "":
				Globals.save_file_name = "world.json"
			Globals.world_override_data["file_name"] = Globals.save_file_name.trim_suffix(".json")
			
			DirAccess.make_dir_recursive_absolute(Globals.saves_directory)
			var dir = DirAccess.open(Globals.saves_directory)
			dir.copy("res://assets/world_template.json", Globals.saves_directory + Globals.save_file_name)
			dir = null
			
			save_path = Globals.saves_directory + Globals.save_file_name
			
			json = read_json(save_path)
			load_save()
			Globals.world_override_data = {}
			
			world_gen.setup()
			
			# this is really convoluted
			var a = 1
			
			for x in int(world["base_dimensions"][0]):
				for y in int(world["base_dimensions"][1]):
					var gc = Vector2i(world["base_location"][0] + x, world["base_location"][1] + y)
					var lc = Globals.global2local(gc, world["chunk_size"], world["world_size"])
					var idx = Globals.local2index(Vector2i(lc.x, lc.y), world["chunk_size"])
					
					world["chunks"][str(lc.z)]["tiles"][idx] = 7
					world["chunks"][str(lc.z)]["terrain"][idx] = 2002
			
			for i in int(world["base_dimensions"][0]) - 2 * a:
				var gc = Vector2i(world["base_location"][0] + i + a, world["base_location"][1])
				var lc = Globals.global2local(gc, world["chunk_size"], world["world_size"])
				var idx = Globals.local2index(Vector2i(lc.x, lc.y), world["chunk_size"])
				
				world["chunks"][str(lc.z)]["tiles"][idx] = 5
				world["chunks"][str(lc.z)]["terrain"][idx] = 2002
			
			for i in int(world["base_dimensions"][0]) - 2 * a:
				var gc = Vector2i(world["base_location"][0] + i + a, world["base_location"][1] + world["base_dimensions"][1] - 1)
				var lc = Globals.global2local(gc, world["chunk_size"], world["world_size"])
				var idx = Globals.local2index(Vector2i(lc.x, lc.y), world["chunk_size"])
				
				world["chunks"][str(lc.z)]["tiles"][idx] = 5
				world["chunks"][str(lc.z)]["terrain"][idx] = 2002
			
			for i in int(world["base_dimensions"][1]) - 2 * a:
				var gc = Vector2i(world["base_location"][0], world["base_location"][1] + i + a)
				var lc = Globals.global2local(gc, world["chunk_size"], world["world_size"])
				var idx = Globals.local2index(Vector2i(lc.x, lc.y), world["chunk_size"])
				
				world["chunks"][str(lc.z)]["tiles"][idx] = 5
				world["chunks"][str(lc.z)]["terrain"][idx] = 2002
			
			for i in int(world["base_dimensions"][1]) - 2 * a:
				var gc = Vector2i(world["base_location"][0] + world["base_dimensions"][0] - 1, world["base_location"][1] + i + a)
				var lc = Globals.global2local(gc, world["chunk_size"], world["world_size"])
				var idx = Globals.local2index(Vector2i(lc.x, lc.y), world["chunk_size"])
				
				world["chunks"][str(lc.z)]["tiles"][idx] = 5
				world["chunks"][str(lc.z)]["terrain"][idx] = 2002
			
			
			write_save()
			
			
			#loading_path = Globals.save_file_path
		"load":
			if Globals.save_file_name != "":
				save_path = Globals.saves_directory + Globals.save_file_name
				
				json = read_json(save_path)
				load_save()
				Globals.world_override_data = {}
				
				
	
	#print(json["chunks"][0]["tiles"])
	

func setup(tile_size:int):
	#json = read_json(save_path)
	constructor_recipes = read_json(constructor_recipes_file)
	smelter_recipes = read_json(smelter_recipes_file)
	ores = read_json(ores_file)
	objectives = read_json(objectives_file)
	
	tileset = make_tileset_exist(tile_size)
	ResourceSaver.save(tileset, "res://generated_tileset.tres")
	
	load_save()
	
	#Globals.world_override_data = {}

func read_json(file_path:String = save_path):
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


func write_save(file_path:String = save_path):
	write_json = world
	write_json["unix_time"] = Time.get_unix_time_from_system()
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(write_json))
	file = null

func load_save():
	var world = json.duplicate()
	
	world.merge(Globals.world_override_data, true)
	
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
				var image = load(path + file_name)
				
				if (tile_metadata.has(file_name.get_basename())):
					var tile = tile_metadata[file_name.get_basename()]
					var source = TileSetAtlasSource.new()
					source.texture = image
					
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
	
	file_data = null
	dir = null
	
	return ts

func texture_from_tile(id:int):
	if tile_textures.has(id) and ResourceLoader.exists("res://assets/tiles/" + self.tile_textures[id] + ".png"):
		return load("res://assets/tiles/" + self.tile_textures[id] + ".png")
	print(id)
	return load("res://assets/textures/missing16.png")
