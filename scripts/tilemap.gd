extends TileMap




@onready var json = get_node("../Json")
@export var gui:CanvasLayer = null

var world: Dictionary 

const sides = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var selected_tile = 1
var tile_rotation = 0



# Called when the node enters the scene tree for the first time.
func _ready():
#	print(json.json)
	world = load_tiles()
	update_tilemap()
	
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
		
		print("reload")
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

func update_tilemap():
	pass
	

func load_tiles():
	var world:Dictionary = {}
	
	return world

func _on_selection_changed(selected_tile, tile_rotation):
	self.selected_tile = selected_tile
	self.tile_rotation = tile_rotation
	
