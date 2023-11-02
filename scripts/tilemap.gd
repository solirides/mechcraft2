extends TileMap



var world: Dictionary 
@onready var json = get_node("../Json")

const sides = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

# Called when the node enters the scene tree for the first time.
func _ready():
#	print(json.json)
	world = load_tiles()
	update_tilemap()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("left_click"):
		var p = get_global_mouse_position()
		print(p);
		var c = Vector2(int(p.x) / 16, int(p.y) / 16)
		self.set_cell(0, c, 1, Vector2i.ZERO)
	
	if event.is_action_pressed("reload"):
		detect_conveyors_lines()


func detect_conveyors_lines():
	var cells = self.get_used_cells(0)
	
	for cell in cells:
		if self.get_cell_source_id(0, cell) == 1:
			print("2")
			
			var current_cell = cell
			var loop = true
			detect_connections(current_cell)
				
				


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
	var world
	
	return world
