extends TileMap




@onready var json = get_node("../Json")
@export var gui:CanvasLayer = null
@export var debug_dot:Polygon2D = null

var world_tiles = []
var world_tiledata = []
var world_size:int
var chunk_size:int
var chunk_area:int
var conveyor_lines = []

const sides = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var selected_tile = 1
var tile_rotation = 0

var tileset = TileSet.new()
var bounds:Rect2i

# Called when the node enters the scene tree for the first time.
func _ready():
#	print(json.json)
	make_tileset_exist(tileset)
	ResourceSaver.save(tileset, "res://generated_tileset.tres")
	self.tile_set = tileset
	
	world_size = json.json["chunk_size"]
	bounds = Rect2i(0, 0,world_size, world_size)
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
		set_tile(Vector2i(floor(p.x/16), floor(p.y/16)), selected_tile, tile_rotation)
#		var c = Vector2i(int(p.x) / 16, int(p.y) / 16)
#		self.set_cell(0, c, selected_tile, Vector2i.ZERO, tile_rotation)
#		world_tiles[0][c.x + c.y * chunk_size] = selected_tile
#		world_tiledata[0]["rotation"][c.x + c.y * chunk_size] = tile_rotation
	
	if event.is_action_pressed("right_click"):
		var p = get_global_mouse_position()
		print(p);
		var c = Vector2i(int(p.x) / 16, int(p.y) / 16)
		self.set_cell(0, c, 0, Vector2i.ZERO)
		world_tiles[0][c.x + c.y * chunk_size] = 0
		world_tiledata[0]["rotation"][c.x + c.y * chunk_size] = 0
	
	if event.is_action_pressed("reload"):
		print("recalculate")
		clear_markers()
		#detect miners and create conveyor lines
		var roots:Array = []
		var lines:Array = detect_world_tiles()
		#move items
		update_items(roots, lines)

func detect_world_tiles():
#	var cells = self.get_used_cells(0)
	var d = [chunk_size, 1, -chunk_size, -1]
	var lines:Array[Vector2i] = []
	var c = 0
	
	for index in chunk_area:
#		print(world_tiles[0][index])
		# one chunk
		match int(world_tiles[c][index]):
			5:
				print("5")
				# line includes miners and storage
				var gc = local2global(index2local(index, c))
#				print(Vector3i(index % chunk_size, floor(index / chunk_size), c))
#				print(gc)
				debug_marker(gc, Color(1, 0, 1, 0.7))
				lines.append_array(detect_connections(gc, 0, 0))
#				for b in range(4):
##					var neighbor = self.get_cell_source_id(0, index + sides[b])
#					var facing:Vector2i = gc + sides[b]
#					# temp solution
#					if not Rect2i(0,0,chunk_size,chunk_size).has_point(facing):
#						print("a")
#						continue
#
#					var facing_lc = global2local(facing)
#					var facing_id = world_tiles[facing_lc.z][local2index(Vector2i(facing_lc.x, facing_lc.y))]
#					var facing_dir = world_tiledata[facing_lc.z]["rotation"][local2index(Vector2i(facing_lc.x, facing_lc.y))]
#					print(facing)
#					print(facing_lc)
#					print(facing_id)
#					print(facing_dir)
#					debug_marker(gc, Color(0, 1, 1, 0.7))
#					if facing_id == 1 and facing_dir == (b + 2) % 4:
#						print(Vector2i(0, index))
#						line.append(local2global(index2local(index, c)))
#						debug_marker(gc, Color(1, 0, 1, 0.7))
#						detect_connections(facing, facing_dir)
								
	return lines

func neighbor(gc:Vector2i, dir:int):
	var tile = gc + sides[dir]
	if bounds.has_point(tile):
		return tile
	return null

func detect_connections(gc:Vector2i, p:int, start_dir:int):
	var tile = gc
	var dir:int = start_dir
	var loop = true
	var priority:int = p
	var priorities:Array[int] = []
	var result:Array[Array] = []
	var line:Array[Vector2i] = []
	while loop:
		loop = false
		for b in range(4):
			var facing_gc:Vector2i = tile + sides[(b + dir + 2) % 4]
			var facing_lc:Vector3i = global2local(facing_gc)
			var facing:Vector2i = Vector2i(facing_lc.x,facing_lc.y)
			var c = facing_lc.z
			print(facing_lc)
			if not Rect2i(0,0,chunk_size,chunk_size).has_point(facing):
				# out of bounds
				print("a")
				continue
			var facing_idx = local2index(facing)
			var facing_rot = world_tiledata[c]["rotation"][facing_idx]
			match int(world_tiles[c][facing_idx]):
				1:
					if facing_rot == int(b + dir) % 4:
						if line.has(facing_gc):
							break
						# extend line
						debug_marker(facing_gc, Color(1, 0, 1, 0.7))
						tile = facing_gc
						dir = world_tiledata[c]["rotation"][facing_idx]
						loop = true
						break
				3:
					if facing_rot == int(b + dir) % 4 or facing_rot == int(b + dir + 1) % 4:
						# new line
						priority += 1
						
						break
						
			# no tile found
	return result

func update_items(roots:Array, lines:Array):
	for cell in chunk_area:
		match int(world_tiles[0][cell]):
			1:
				pass

#func neighbor_index(chunk:int, index:int, direction:int):
#	var location:Vector3
#	var x:int = index % chunk_size
#	var y:int = floor(index / chunk_size)
#
#	return location

func local2index(local_coords:Vector2i):
	return local_coords.x + local_coords.y * chunk_size

func index2local(index, chunk):
	return Vector3i(index % chunk_size, floor(index / chunk_size), chunk)

func local2global(local_coords:Vector3i):
	var c = Vector2i(local_coords.z % world_size, floor(local_coords.z / world_size))
	return Vector2i(local_coords.x + c.x * chunk_size, local_coords.y + c.y * chunk_size)

func global2local(global_coords:Vector2i):
	return Vector3i(global_coords.x % chunk_size, \
		global_coords.y % chunk_size, \
		floor(global_coords.x / chunk_size) + world_size*floor(global_coords.y/chunk_size))

func set_tile(global_coords:Vector2i, tile:int, rotation:int):
#	no storage data yet
	var local_coords = global2local(global_coords)
	
#	world_tiledata[local_coords.z]["storage"][local_coords.x + local_coords.y * chunk_size] = null
	world_tiles[local_coords.z][local_coords.x + local_coords.y * chunk_size] = selected_tile
	world_tiledata[local_coords.z]["rotation"][local_coords.x + local_coords.y * chunk_size] = tile_rotation
	self.set_cell(0, \
		global_coords, tile, \
		Vector2i.ZERO, tile_rotation
		)

func debug_marker(global_coords:Vector2i, color:Color):
	var a = Polygon2D.new()
	a.polygon = [Vector2(1,1), Vector2(-1,1), Vector2(-1,-1), Vector2(1,-1)]
	a.color = color
	a.position = Vector2(16 * global_coords.x + 8, \
		16 * global_coords.y + 8)
	$Debug.add_child(a)

func clear_markers():
	for node in $Debug.get_children():
		$Debug.remove_child(node)

func set_tilemap(world_tiles, world_tiledata):
	for c in len(world_tiles):
		for i in chunk_area:
			print(world_tiles[c][i])
			# left to right, top to bottom
			self.set_cell(0, \
				Vector2i(fmod(i, chunk_size), floor(i / chunk_size)), world_tiles[c][i], \
				Vector2i.ZERO, world_tiledata[c]["rotation"][i]
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
	
	var blank = TileSetAtlasSource.new()
	ts.add_source(blank)
	
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
				
				for i in range(3):
					source.create_alternative_tile(Vector2i(0,0), -1)
				
				source.get_tile_data(Vector2i(0,0), 1).flip_h = true
				source.get_tile_data(Vector2i(0,0), 1).transpose = true
				
				source.get_tile_data(Vector2i(0,0), 2).flip_v = true
				
				source.get_tile_data(Vector2i(0,0), 3).transpose = true
				
				
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

