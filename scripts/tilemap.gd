extends TileMap




@onready var json = get_node("../Json")
@export var gui:CanvasLayer = null
@export var debug_dot:Polygon2D = null

var running = false
var last_tick = 0
var tps:float = 3

var world_tiles = []
var world_tiledata = []
var world_items = []
var world_size:int
var chunk_size:int
var chunk_area:int
var result:Array[Array]

# these all correspond to each other
var lines_global:Dictionary = {}
var priorities_global:Dictionary = {}
var priorities_index:Array[Array] = []


var infinite_loop:Array[Array] = []
var max_priority:int = 0
var used_tiles:Array[Array] = [] # 0 = unprocessed 1 = completely processed 2 = somewhat processed

const SIDES = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var selected_tile = 1
var tile_rotation = 0

var tileset = TileSet.new()
var bounds:Rect2i

# Called when the node enters the scene tree for the first time.
func _ready():
#	print(json.json)
	setup()
	
	gui.selection_changed.connect(_on_selection_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var p = get_global_mouse_position()
	var gc = Vector2i(floor(p.x / 16), floor(p.y / 16))
	var lc = global2local(gc)
	gui.alert(str(gc.x) + " " + str(gc.y) + "\n" + str(lc.x) + " " + str(lc.y) + " " + str(lc.z))
	

func _physics_process(delta):
	#print(last_tick)
	last_tick += delta
	if running == true and last_tick >= (1.0 / tps):
		last_tick = 0
		do_positive_net_work_on_the_items_located_on_conveyors_and_similar_tiles_that_facillitate_movement()

func _input(event):
	
	if event.is_action_pressed("left_click"):
		var p = get_global_mouse_position()
		
		print(p);
		set_tile(0, Vector2i(floor(p.x/16), floor(p.y/16)), selected_tile, tile_rotation)
#		var c = Vector2i(int(p.x) / 16, int(p.y) / 16)
#		self.set_cell(0, c, selected_tile, Vector2i.ZERO, tile_rotation)
#		world_tiles[0][c.x + c.y * chunk_size] = selected_tile
#		world_tiledata[0]["rotation"][c.x + c.y * chunk_size] = tile_rotation
	if event.is_action_pressed("middle_click"):
		var p = get_global_mouse_position()
		var tile_pos = Vector2i(floor(p.x / 16), floor(p.y / 16))
		rotate_conveyor(tile_pos)
	
	if event.is_action_pressed("resource"):
		var p = get_global_mouse_position()
		print("resource spawned")
		set_item(1, Vector2i(floor(p.x/16), floor(p.y/16)), 6)
	
	if event.is_action_pressed("right_click"):
		var p = get_global_mouse_position()
		print(p);
		set_tile(0, Vector2i(floor(p.x/16), floor(p.y/16)), 0, 0)
	
	if event.is_action_pressed("reload"):
		print("recalculate")
		clear_markers()
		#detect miners and create conveyor lines
		#var roots:Array = []
		lines_global = {}
		priorities_global = {}
		priorities_index = []
		max_priority = 0
		
		for i in len(used_tiles):
			used_tiles[i].fill(0)
		
		detect_world_tiles()
	
	if event.is_action_pressed("ping"):
		var p = get_global_mouse_position()
		print(p);
		var c = Vector2i(int(p.x) / 16, int(p.y) / 16)
		print("PING " + " " + str(c) + " " + str(global2local(Vector2i(floor(p.x/16), floor(p.y/16)))) )
		
	if event.is_action_pressed("tick"):
		print("tick")
		do_positive_net_work_on_the_items_located_on_conveyors_and_similar_tiles_that_facillitate_movement()
	if event.is_action_pressed("pause"):
		running = !running
		

# Detecting conveyor lines:
#region
func detect_world_tiles():
#	var cells = self.get_used_cells(0)
	var d = [chunk_size, 1, -chunk_size, -1]
	var lines:Array[Vector2i] = []
	var c = 0
	
	for index in chunk_area:
#		print(world_tiles[0][index])
		# one chunk
		match int(world_tiles[c][index]):
			5: # line includes storage
				print("5")
				var gc = local2global(index2local(index, c))
#				print(Vector3i(index % chunk_size, floor(index / chunk_size), c))
#				print(gc)
				debug_marker(gc, Color(1, 0, 1, 0.7))
				used_tiles[gc.x][gc.y] == 1
				var a = detect_connections(gc, world_tiles[c][index], 1, 0, true)
				# add self to line
				#a[0][0].push_front(gc)
				
				lines_global.merge(a[0])
				priorities_global.merge(a[1])
	
	# sort lines
	for i in range(max_priority + 1):
		priorities_index.append([])
	
	for i in priorities_global.keys():
		priorities_index[priorities_global[i]].append(i)
	
	return null

func detect_connections(gc:Vector2i, id:int, p:int, start_dir:int, recurse:bool):
	# gc = global coords of starting tile
	# id = id of starting tile
	# p = priority of current line
	# start_dir = rotation of starting tile
	# these variables are getting complicated
	
	var tile = gc
	var dir:int = start_dir
	var loop = true
	
	# temp vars to continue checking for lines after one path has been found
	var n_tile = tile
	var n_dir = dir
	var split = false
	
	var color = Color.from_hsv(randf(), randf_range(0.7, 1), randf_range(0.7, 1))
	debug_marker(tile, color)
	debug_text(gc, str(p))
	
	var priority:int = p
	var priorities:Dictionary = {}
	var result:Dictionary = {}
	var line:Array[Vector2i] = [gc]
	
	var neighbors:Array[int] = [] # clockwise offset from current rotation
	match int(id):
		2:
			neighbors = [1, 3]
		3:
			neighbors = [2, 3]
		_:
			neighbors = [1, 2, 3]
	
	while loop:
		loop = false
		split = false
		tile = n_tile
		dir =  n_dir
		print(tile)
		for b:int in neighbors:
			var neighbor_dir = (b + dir) % 4 # direction to neighbor from current tile
			var facing_gc:Vector2i = tile + SIDES[(b + dir) % 4]
			var facing_lc:Vector3i = global2local(facing_gc)
			#print(facing_lc)
			print(facing_gc)
			if not bounds.has_point(Vector2i(facing_lc.x,facing_lc.y)) or used_tiles[facing_gc.x][facing_gc.y] == 1:
				# out of bounds
				print("a")
				#print(bounds.has_point(Vector2i(facing_lc.x,facing_lc.y)))
				#print(used_tiles[facing_lc.x][facing_lc.y])
				continue
			var c = facing_lc.z
			var facing_idx:int = local2index(Vector2i(facing_lc.x,facing_lc.y))
			var facing_rot:int = world_tiledata[c]["rotation"][facing_idx]
			var facing_tile:int = world_tiles[c][facing_idx]
			
			match facing_tile:
				1: # conveyor
					if facing_rot == (neighbor_dir + 2) % 4:
						used_tiles[facing_gc.x][facing_gc.y] = 1
						# create new line
						if split:
							#result.append(line)
							#priorities.append(priority)
							var a = detect_connections(facing_gc, facing_tile, priority + 1, facing_rot, true)
							result.merge(a[0])
							priorities.merge(a[1])
							continue
						
						# extend line
						debug_marker(facing_gc, color)
						line.append(facing_gc)
						
						n_tile = facing_gc
						n_dir = facing_rot
						loop = true
						split = true
				2:
					if facing_rot == (neighbor_dir + 2) % 4:
						used_tiles[facing_gc.x][facing_gc.y] = 1
						# create new line
						if split:
							#result.append(line)
							#priorities.append(priority)
							var a = detect_connections(facing_gc, facing_tile, priority + 1, facing_rot, true)
							result.merge(a[0])
							priorities.merge(a[1])
							continue
						
						# extend line
						debug_marker(facing_gc, color)
						line.append(facing_gc)
						
						n_tile = facing_gc
						n_dir = facing_rot
						loop = true
						split = true
				3: # sketchy
					if facing_rot == (neighbor_dir + 2) % 4 or facing_rot == (neighbor_dir + 1) % 4:
						if (used_tiles[facing_gc.x][facing_gc.y] == 2):
							#update priority
							pass
						else:
							if true:
								var a = detect_connections(facing_gc, facing_tile, priority + 1, facing_rot, true)
								result.merge(a[0])
								priorities.merge(a[1])
								continue
							
							debug_marker(facing_gc, color)
							line.append(facing_gc)
							
							n_tile = facing_gc
							n_dir = facing_rot
							loop = true
							split = true
						
						
	result[gc2string(gc)] = line
	priorities[gc2string(gc)] = priority
	
	max_priority = max(max_priority, priority)
	return [result, priorities]

#endregion

# Processing tiles
#region

func do_positive_net_work_on_the_items_located_on_conveyors_and_similar_tiles_that_facillitate_movement():
	for p in priorities_index: # p = array of lines of the same priority
			for p2 in p: # i = index of one line
				if len(p) != 0:
					#var last_gc = lines_global[p2][0]
					#var last_lc = global2local(last_gc)
					#var last_index = local2index(Vector2i(last_lc.x, last_lc.y))
					#
					## process first tile
					## same as one in for loop
					#if world_items[last_lc.z][last_index] != 0:
						## doesn't work with balancers yet
						#match world_tiles[last_lc.z][last_index]:
							#1:
								#var dir = world_tiledata[last_lc.z]["rotation"][last_index]
								## the "last" vars are what the current conveyor points to (since the line's array is reversed)
								#var idk = global2local(last_gc + SIDES[0])
								#if (world_items[idk.z][local2index(Vector2i(idk.x, idk.y))] == 0):
									## move if space
									#move_resource(last_gc, dir)
							#5:# storage recieves item
								#print("item recieved")
								#gui.add_resource(1)
								## item go bye bye
								#set_item(1, last_gc, 0)
					
					# process rest of the line
					for gc in lines_global[p2]:
						var lc = global2local(gc)
						var index = local2index(Vector2i(lc.x, lc.y))
						if world_items[lc.z][index] != 0:
							# doesn't work with balancers yet
							match world_tiles[lc.z][index]:
								1:
									var dir = world_tiledata[lc.z]["rotation"][index]
									# the "last" vars are what the current conveyor points to (since the line's array is reversed)
									#if (world_items[last_lc.z][last_index] == 0):
									move_resource(gc, dir)
								3:
									var dir = world_tiledata[lc.z]["rotation"][index]
									var state = world_tiledata[lc.z]["state"][index]
									move_resource(gc, dir + int(state))
									world_tiledata[lc.z]["state"][index] = not world_tiledata[lc.z]["state"][index]
									
								5:# storage recieves item
									print("item recieved")
									gui.add_resource(1)
									# item go bye bye
									set_item(1, gc, 0)
						#last_gc = gc
						#last_lc = lc
						#last_index = index
		
		

#func initiate_resource_movement(tile_pos):
	#var local_coords = global2local(tile_pos)
	#var index = local2index(Vector2i(local_coords.x, local_coords.y))
	#var rotation = world_tiledata[local_coords.z]["rotation"][index]
	#
	#if world_tiles[local_coords.z][index] == 6:
		#match rotation:
			#0:  
				#move_resource(tile_pos, "up")
			#1:  
				#move_resource(tile_pos, "right")
			#2:  
				#move_resource(tile_pos, "down")
			#3:  
				#move_resource(tile_pos, "left")

func move_resource(gc:Vector2i, direction:int):
	var lc = global2local(gc)
	var idx = local2index(Vector2i(lc.x, lc.y))
	var current_tile = world_tiles[lc.z][idx]
	var next_gc = gc + SIDES[direction]
	var next_lc = global2local(next_gc)
	var next_idx = local2index(Vector2i(next_lc.x, next_lc.y))
	var id = world_items[lc.z][idx]
	
	
	if (world_items[next_lc.z][next_idx] == 0):
		set_item(1, gc, 0)
		set_item(1, next_gc, id)
	
	#if next_tile and world_tiles[next_tile.z][local2index(Vector2i(next_tile.x, next_tile.y))] == 6:
		#print("Moving resource from ", tile_pos, " to ", next_tile)
	#else:
		#print("Cannot move in that direction or no conveyor")

#endregion

func rotate_conveyor(tile_pos): 
	var local_coords = global2local(tile_pos)
	var index = local2index(Vector2i(local_coords.x, local_coords.y))
	var tile = world_tiles[local_coords.z][index]
	var rotation:int = world_tiledata[local_coords.z]["rotation"][index]
	
	rotation = (rotation + 1) % 4
	world_tiledata[local_coords.z]["rotation"][index] = rotation
	set_cell(0, tile_pos, tile, Vector2i(0, 0), rotation)

func neighbor(gc:Vector2i, dir:int):
	var tile = gc + SIDES[dir]
	if bounds.has_point(tile):
		return tile
	return null



#func neighbor_index(chunk:int, index:int, direction:int):
#	var location:Vector3
#	var x:int = index % chunk_size
#	var y:int = floor(index / chunk_size)
#
#	return location


# Coordinate stuff:
#region
func gc2string(gc:Vector2i):
	return str(gc.x) + "," + str(gc.y)


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

func set_tile(layer:int, global_coords:Vector2i, tile:int, rotation:int):
#	no storage data yet
	var local_coords = global2local(global_coords)
	
#	world_tiledata[local_coords.z]["storage"][local_coords.x + local_coords.y * chunk_size] = null
	world_tiles[local_coords.z][local_coords.x + local_coords.y * chunk_size] = tile
	world_tiledata[local_coords.z]["rotation"][local_coords.x + local_coords.y * chunk_size] = rotation
	self.set_cell(layer, \
			global_coords, tile, \
			Vector2i.ZERO, rotation
			)

func set_item(layer:int, global_coords:Vector2i, tile:int):
	var local_coords = global2local(global_coords)
	
	world_items[local_coords.z][local_coords.x + local_coords.y * chunk_size] = tile
	self.set_cell(layer, \
			global_coords, tile, \
			Vector2i.ZERO, rotation
			)

func debug_marker(global_coords:Vector2i, color:Color):
	var a = Polygon2D.new()
	a.polygon = [Vector2(0.8,0.8), Vector2(-0.8,0.8), Vector2(-0.8,-0.8), Vector2(0.8,-0.8)]
	a.color = color
	a.position = Vector2(16 * global_coords.x + 8, \
		16 * global_coords.y + 8)
	$Debug.add_child(a)

func debug_text(global_coords:Vector2i, text:String):
	var a = $DebugText.duplicate()
	a.text = text
	a.z_index = 10
	a.clip_contents = false
	#var theme = load("res://assets/theme.tres")
	#a.set_theme(theme)
	a.position = Vector2(16 * global_coords.x + 8, \
		16 * global_coords.y + 8)
	$Debug.add_child(a)

func clear_markers():
	for node in $Debug.get_children():
		$Debug.remove_child(node)

#endregion

# Setup
#region

func setup():
	make_tileset_exist(tileset)
	ResourceSaver.save(tileset, "res://generated_tileset.tres")
	self.tile_set = tileset
	
	world_size = json.json["world_size"]
	chunk_size = json.json["chunk_size"]
	bounds = Rect2i(0, 0, world_size * chunk_size, world_size * chunk_size)
	
	chunk_area = pow(chunk_size, 2)
	world_tiles = load_tiles()
	world_items = load_items()
	world_tiledata = load_tiledata()
	
	for i in bounds.size.x:
		var a = []
		a.resize(bounds.size.y)
		a.fill(false)
		used_tiles.append(a)
	
	
	set_tilemap(world_tiles, world_tiledata)

func set_tilemap(world_tiles, world_tiledata):
	for c in len(world_tiles):
		for i in chunk_area:
			#print(world_tiles[c][i])
			# left to right, top to bottom
			self.set_cell(0, \
				Vector2i(fmod(i, chunk_size) + (c % world_size)*chunk_size, \
					floor(i / chunk_size) + floor(c / world_size)*chunk_size), world_tiles[c][i], \
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
	
	# fill missing chunks
	var a:PackedInt32Array = []
	a.resize(pow(chunk_size, 2))
	a.fill(0)
	for i in pow(world_size, 2) - len(world):
		world.append(a)
	
	return world

func load_items():
	var world = []
	print("loading items")
	for i in len(json.json["chunks"]):
		world.append(PackedInt32Array(json.json["chunks"][i]["items"]))

	var a:PackedInt32Array = []
	a.resize(pow(chunk_size, 2))
	a.fill(0)
	for i in pow(world_size, 2) - len(world):
		world.append(a)
	
	return world

func load_tiledata():
	var world = []
	print("loading tiledata")
	for i in len(json.json["chunks"]):
		world.append(json.json["chunks"][i]["tiledata"])
#		print(world[0]["rotation"])
	
	# fill missing chunks
	var a:PackedInt32Array = []
	a.resize(pow(chunk_size, 2))
	a.fill(0)
	var d:Dictionary = {"storage": a, "rotation": a, "state": a}
	for i in pow(world_size, 2) - len(world):
		world.append(d)
	
	return world


func make_tileset_exist(ts: TileSet):
	var id = 0
	var path = "res://assets/tiles/"
	var dir = DirAccess.open(path)
	
	var blank = TileSetAtlasSource.new()
	ts.add_source(blank)
	
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
				var source = TileSetAtlasSource.new()
				source.texture = ImageTexture.create_from_image(image)
				source.create_tile(Vector2i(0,0))
				
				for i in range(3):
					source.create_alternative_tile(Vector2i(0,0), -1)
				
				source.get_tile_data(Vector2i(0,0), 1).flip_h = true
				source.get_tile_data(Vector2i(0,0), 1).transpose = true
				
				source.get_tile_data(Vector2i(0,0), 2).flip_v = true
				
				source.get_tile_data(Vector2i(0,0), 3).transpose = true
				
				# temp solution
				if file_name == "3-balancer.png":
					source.get_tile_data(Vector2i(0,0), 1).flip_h = true
					source.get_tile_data(Vector2i(0,0), 1).transpose = true
					
					source.get_tile_data(Vector2i(0,0), 2).flip_v = false
					source.get_tile_data(Vector2i(0,0), 2).transpose = true
					
					source.get_tile_data(Vector2i(0,0), 3).flip_v = true
					source.get_tile_data(Vector2i(0,0), 3).transpose = true
					
				
				ts.add_source(source)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")
	

#endregion

func _on_selection_changed(selected_tile, tile_rotation):
	self.selected_tile = selected_tile
	self.tile_rotation = tile_rotation

