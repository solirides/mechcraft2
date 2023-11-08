extends TileMap




@onready var json = get_node("../Json")
@export var gui:CanvasLayer = null

var world_tiles = []
var world_tiledata = []
var chunk_size

const sides = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var selected_tile = 1
var tile_rotation = 0



# Called when the node enters the scene tree for the first time.
func _ready():
#	print(json.json)
	chunk_size = json.json["chunk_size"]
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
	var cells = self.get_used_cells(0)
	
	for cell in cells:
		match self.get_cell_source_id(0, cell):
			1:
				print("1")
				
				var current_cell = cell
				var loop = true
				detect_connections(current_cell)
				


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
		for i in pow(chunk_size, 2):
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
		world.append(json.json["chunks"][i]["tiles"])
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
	
