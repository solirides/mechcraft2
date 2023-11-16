extends TileMap




@onready var json = get_node("../Json")
@export var gui:CanvasLayer = null

var world_tiles = []
var world_tiledata = []
var chunk_size
var chunk_area

const sides = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var selected_tile = 1
var tile_rotation = 0

var tileset = TileSet.new()

# Called when the node enters the scene tree for the first time.
func _ready():
#	print(json.json)
	make_tileset_exist(tileset)
	ResourceSaver.save(tileset, "res://generated_tileset.tres")
	self.tileset = tileset
	
	chunk_size = json.json["chunk_size"]
	chunk_area = pow(chunk_size, 2)
	world_tiles = load_tiles()
	world_tiledata = load_tiledata()
	
	set_tilemap(world_tiles, world_tiledata)
	
	gui.selection_changed.connect(_on_selection_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("left_click"):
		var p = get_global_mouse_position()
		print(p);
		var c = Vector2(int(p.x) / 16, int(p.y) / 16)
		self.set_cell(0, c, selected_tile, Vector2i.ZERO)
	
	if event.is_action_pressed("right_click"):
		var p = get_global_mouse_position()
		print(p);
		var c = Vector2(int(p.x) / 16, int(p.y) / 16)
		self.set_cell(0, c, 0, Vector2i.ZERO)
	
	if event.is_action_pressed("reload"):
		print("recalculate")
		detect_world_tiles()
		detect_conveyors_lines()

func detect_world_tiles():
#	var cells = self.get_used_cells(0)
	var d = [chunk_size, 1, -chunk_size, -1]
	
	for cell in chunk_area:
#		print(world_tiles[0][cell])
		match int(world_tiles[0][cell]):
			1:
				print("1")
				
				var current_cell = cell
				var loop = true
				var line: Array[int] = []
				for b in range(4):
#					var neighbor = self.get_cell_source_id(0, cell + sides[b])
					var idk = cell + d[b]
					if idk >= 0 and idk <= chunk_area:
						var neighbor = world_tiles[0][cell]
						if neighbor == 1:
								print("found")
								line.append(neighbor)
				


func detect_conveyors_lines():
	pass


func detect_connections(current_cell:Vector2i):
	var neighbors: Array[int] = []
	for b in range(4):
		var neighbor = self.get_cell_source_id(0, current_cell + sides[b])
		neighbors.append(neighbor)
		if neighbor == 1:
				print("found")

func set_tilemap(world_tiles, world_tiledata):
	for c in len(world_tiles):
		for i in chunk_area:
			print(world_tiles[c][i])
			self.set_cell(0, \
				Vector2i(fmod(i, chunk_size), floor(i / chunk_size)), world_tiles[c][i], \
				Vector2i.ZERO
			)
#		world_tiledata[c]["rotation"][i]
	

func load_tiles():
	var world = []
	print("loading tiles")
	for i in len(json.json["chunks"]):
#		print(json.json["chunks"][i]["tiles"])
		world.append(PackedInt32Array(json.json["chunks"][i]["tiles"]))
#		print(world[0])
	
	return world

func load_tiledata():
	var world = []
	print("loading tiledata")
	for i in len(json.json["chunks"]):
		world.append(json.json["chunks"][i]["tiledata"])
#		print(world[0]["rotation"])
	return world

func _on_selection_changed(selected_tile, tile_rotation):
	self.selected_tile = selected_tile
	self.tile_rotation = tile_rotation
	
func make_tileset_exist(ts: TileSet):
	var id = 0
	var path = "res://assets/tiles/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			elif file_name.ends_with(".png"):
				print("Found file: " + file_name)
				print(path + file_name)
				var image = Image.load_from_file(path + file_name)
				var source = TileSetAtlasSource.new()
				source.texture = ImageTexture.create_from_image(image)
				source.create_tile(Vector2i(0,0))
				ts.add_source(source)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	

#	ts.tile_set_name()
#	ts.tile_set_texture(id, ...)
#	ts.tile_set_region(id, ...)

func dir_contents(path):
	var dir = DirAccess.open("res://assets/tiles")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

