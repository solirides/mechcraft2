extends TileMap




var explosion = preload("res://scenes/explosion.tscn")

@onready var json = get_node("../Json")
@export var gui:CanvasLayer = null
@export var debug_dot:Polygon2D = null

@export var camera:Node = null
@export var tile_size = 16

var world_accepts_input = true
var running = false
var tps:float = 3
var last_tick = 0
var highest_noise = 0

# these vars are all from the world save file

var world = WorldSave.new()

var result:Array[Array]

# these all correspond to each other
var lines_global:Dictionary = {}
var priorities_global:Dictionary = {}
var priorities_index:Array[Array] = []


var infinite_loop:Array[Array] = []
var max_priority:int = 0
var used_tiles:Array[Array] = [] # 0 = unprocessed; 1 = completely processed; 2 = somewhat processed
var needs_recalculation = true

const SIDES = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var selected_tile = 1
var tile_rotation = 0

var tileset = TileSet.new()
#var bounds:Rect2i

# Called when the node enters the scene tree for the first time.
func _ready():
#	print(json.json)
	setup()
	
	gui.selection_changed.connect(_on_selection_changed)
	gui.world_focused.connect(_on_world_focused)
	
	gui.noise_bar.max_value = world.sandworm_noise_threshold * 1.5
	gui.noise_bar.value = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var p = get_global_mouse_position()
	var gc = Vector2i(floor(p.x / tile_size), floor(p.y / tile_size))
	var lc = global2local(gc)
	var idx = local2index(Vector2i(lc.x, lc.y))
	var lc2 = index2local(idx, lc.z)
	var gc2 = local2global(lc2)
	#gui.debug(str(gc.x) + " " + str(gc.y) + "\n" + str(lc.x) + " " + str(lc.y) + " " + str(lc.z) + \
		#"\n" + str(idx) + "\n" + str(lc2.x) + " " + str(lc2.y) + " " + str(lc2.z) + \
		#"\n" + str(gc2.x) + " " + str(gc2.y))
	gui.debug(str(gc.x) + " " + str(gc.y) + "\n" + str(lc.x) + " " + str(lc.y) + " " + str(lc.z))
	

func _physics_process(delta):
	#print(last_tick)
	last_tick += delta
	if running == true and last_tick >= (1.0 / tps):
		tick()

func _input(event):
	
	if world_accepts_input:
		if event.is_action_pressed("reload"):
			print("this does nothing")
			
		
		if event.is_action_pressed("update_gui"):
			gui.update_hotbar(world)
		
		if event.is_action_pressed("ping"):
			var p = get_global_mouse_position()
			print(p);
			var c = Vector2i(int(p.x) / tile_size, int(p.y) / tile_size)
			var gc = Vector2i(floor(p.x/tile_size), floor(p.y/tile_size))
			var lc = global2local(gc)
			print("PING " + " " + str(c) + " " + str(global2local(Vector2i(floor(p.x/tile_size), floor(p.y/tile_size)))) )
			summon_the_sandworm_from_the_depths_of_the_dunes(gc, lc, local2index(Vector2i(lc.x, lc.y)))
			
		if event.is_action_pressed("tick"):
			print("tick")
			do_positive_net_work_on_the_items_located_on_conveyors_and_similar_tiles_that_facillitate_movement()
			#for i in world.noise:
				#prints(i)
			print(world.noise[0])
			
		if event.is_action_pressed("pause"):
			running = !running
		
		if Input.is_action_just_pressed("save"):
			print("write to save file")
			json.create_save()
			json.write_save()

func _unhandled_input(event):
	if world_accepts_input:
		if event.is_action_pressed("left_click"):
			var p = get_global_mouse_position()
			var gc = Vector2i(floor(p.x/tile_size), floor(p.y/tile_size))
			var lc = global2local(gc)
			print(p)
			print(gc)
			if (world.bounds.has_point(gc) and world.integrity[lc.z][local2index(Vector2i(lc.x, lc.y))] >= 0):
				set_tile(0, gc, selected_tile, tile_rotation)
			
		if event.is_action_pressed("middle_click"):
			var p = get_global_mouse_position()
			var tile_pos = Vector2i(floor(p.x / tile_size), floor(p.y / tile_size))
			rotate_conveyor(tile_pos)
	
		if event.is_action_pressed("resource"):
			var p = get_global_mouse_position()
			print("resource spawned")
			set_item(1, Vector2i(floor(p.x/tile_size), floor(p.y/tile_size)), 6)
		
		if event.is_action_pressed("right_click"):
			var p = get_global_mouse_position()
			var gc = Vector2i(floor(p.x/tile_size), floor(p.y/tile_size))
			print(p);
			if (world.bounds.has_point(gc)):
				var e = explosion.instantiate()
				add_child(e)
				e.position = gc * tile_size
				e.explode()
				camera.camera_shake(0.4, 16, 50, 10)
				set_tile(0, gc, 0, 0)
		

# Detecting conveyor lines:
#region
func detect_world_tiles():
#	var cells = self.get_used_cells(0)
	var d = [world.chunk_size, 1, -world.chunk_size, -1]
	var lines:Array[Vector2i] = []
	
	for c in world.world_size**2:
		for index in world.chunk_area:
	#		print(world.tiles[0][index])
			# one chunk
			var gc = local2global(index2local(index, c))
			match int(world.tiles[c][index]):
				5: # line includes storage
					print("5")
					
	#				print(Vector3i(index % world.chunk_size, floor(index / world.chunk_size), c))
	#				print(gc)
					debug_marker(gc, Color(1, 0, 1, 0.7))
					used_tiles[gc.x][gc.y] == 1
					var a = detect_connections(gc, world.tiles[c][index], 1, 0, true)
					# add self to line
					#a[0][0].push_front(gc)
					
					lines_global.merge(a[0])
					#priorities_global.merge(a[1])
					for k in a[1].keys():
						if (priorities_global.has(k)):
							if (priorities_global[k] < a[1][k]):
								priorities_global[k] = a[1][k]
						else:
							priorities_global[k] = a[1][k]
	
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
		0:
			neighbors = []
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
		print(str(tile) + " tile")
		for b:int in neighbors:
			var neighbor_dir = (b + dir) % 4 # direction to neighbor from current tile
			var facing_gc:Vector2i = tile + SIDES[(b + dir) % 4]
			var facing_lc:Vector3i = global2local(facing_gc)
			#print(facing_lc)
			print(str(facing_gc) + " gc")
			if not world.bounds.has_point(Vector2i(facing_lc.x,facing_lc.y)) or used_tiles[facing_gc.x][facing_gc.y] == 1:
				# out of bounds
				print("a")
				#print(bounds.has_point(Vector2i(facing_lc.x,facing_lc.y)))
				#print(used_tiles[facing_lc.x][facing_lc.y])
				continue
			var c = facing_lc.z
			var facing_idx:int = local2index(Vector2i(facing_lc.x,facing_lc.y))
			var facing_rot:int = world.tiledata[c]["rotation"][facing_idx]
			var facing_tile:int = world.tiles[c][facing_idx]
			print(str(facing_tile) + " facing tile")
			match facing_tile:
				1: # conveyor
					if facing_rot == (neighbor_dir + 2) % 4:
						used_tiles[facing_gc.x][facing_gc.y] = 1
						# create new line
						if split:
							#result.append(line)
							#priorities.append(priority)
							print(split)
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
							used_tiles[facing_gc.x][facing_gc.y] = 1
							var k = gc2string(gc)
							#priorities_global[gc2string(gc)] = max(priorities_global[gc2string(gc)], priority)
							if (priorities_global.has(k)):
								if (priorities_global[k] < priority):
									priorities_global[k] = priority
							else:
								priorities_global[k] = priority
							pass
						else:
							used_tiles[facing_gc.x][facing_gc.y] = 2
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
				4:
					if facing_rot == (neighbor_dir + 2) % 4:
						used_tiles[facing_gc.x][facing_gc.y] = 1
						# create new line
						if split:
							print(split)
							# basically just detect_connections() but for 1 tile
							result[gc2string(facing_gc)] = [facing_gc]
							priorities[gc2string(facing_gc)] = priority + 1
							max_priority = max(max_priority, priority + 1)
							var color2 = Color.from_hsv(randf(), randf_range(0.7, 1), randf_range(0.7, 1))
							debug_marker(facing_gc, color2)
							debug_text(facing_gc, str(priority + 1))
							
							continue
						
						# extend line
						debug_marker(facing_gc, color)
						line.append(facing_gc)
						
						n_tile = facing_gc
						n_dir = facing_rot
						#loop = true
						split = true
	result[gc2string(gc)] = line
	priorities[gc2string(gc)] = priority
	
	max_priority = max(max_priority, priority)
	return [result, priorities]

#endregion

# Processing world.tiles
#region

func do_positive_net_work_on_the_items_located_on_conveyors_and_similar_tiles_that_facillitate_movement():
	highest_noise = 0
	for p in priorities_index: # p = array of lines of the same priority
			for p2 in p: # i = index of one line
				# process rest of the line
				for gc in lines_global[p2]:
					var lc = global2local(gc)
					var index = local2index(Vector2i(lc.x, lc.y))
					var id = world.tiles[lc.z][index]
					if id != 0:
						match id:
							1:
								world.noise[lc.z][index] += 2
								var dir = world.tiledata[lc.z]["rotation"][index]
								# the "last" vars are what the current conveyor points to (since the line's array is reversed)
								#if (world_items[last_lc.z][last_index] == 0):
								move_resource(gc, dir)
								
							2: #constructor
								world.noise[lc.z][index] += 3
								var item = world.items[lc.z][index]
								if (item != 0):
									#print("item recieved at constructor")
									var a = gc2string(gc)
									if (world.tile_storage[lc.z][index] != 0):
										# construct thing
										world.noise[lc.z][index] += 5
										var key = str(world.tile_storage[lc.z][index]) + "," + str(item)
										if json.recipes.has(key):
											set_item(1, gc, json.recipes[key])
											move_resource(gc, world.tiledata[lc.z]["rotation"][index])
										else:
											set_item(1, gc, 0)
											
										world.tile_storage[lc.z][index] = 0
									else:
										world.tile_storage[lc.z][index] = item
										set_item(1, gc, 0)
									# item go bye bye
									#set_item(1, gc, 0)
							
							3:
								world.noise[lc.z][index] += 3
								if (world.items[lc.z][index] != 0):
									var dir = world.tiledata[lc.z]["rotation"][index]
									var state = world.tiledata[lc.z]["state"][index]
									move_resource(gc, (dir + int(state)) % 4)
									world.tiledata[lc.z]["state"][index] = not world.tiledata[lc.z]["state"][index]
							4:
								world.noise[lc.z][index] += 3
								var item = world.items[lc.z][index]
								if (item != 0):
									move_resource(gc, world.tiledata[lc.z]["rotation"][index])
								if (world.tiledata[lc.z]["state"][index] == 4):
									set_item(1, gc, 6)
									world.tiledata[lc.z]["state"][index] = 1
								else:
									world.tiledata[lc.z]["state"][index] += 1
								
							5:# storage recieves item
								var item = world.items[lc.z][index]
								if (item != 0):
									#print("item recieved")
									#gui.add_resource(1)
									if (not world.central_storage.has(str(item))):
										world.central_storage[str(item)] = 1
									world.central_storage[str(item)] += 1
									# item go bye bye
									set_item(1, gc, 0)
					
					world.noise[lc.z][index] = max(world.noise[lc.z][index] - 5, 0)
					if world.noise[lc.z][index] >= world.sandworm_noise_threshold and world.sandworm_current_cooldown <= 0:
						summon_the_sandworm_from_the_depths_of_the_dunes(gc, lc, index)
						world.sandworm_current_cooldown = world.sandworm_attack_cooldown
						
					
					highest_noise = max(highest_noise, world.noise[lc.z][index])
					
					gui.noise_bar.value = highest_noise
					#last_gc = gc
					#last_lc = lc
					#last_index = index

func make_the_terrain_less_bad():
	for c in world.world_size**2:
		for index in world.chunk_area:
			var gc = local2global(index2local(index, c))
			if world.integrity[c][index] < 0:
				world.integrity[c][index] = min(0, world.integrity[c][index] + 4)
				if world.integrity[c][index] >= 0:
					set_terrain(3, gc, -1)

func tick():
	if needs_recalculation:
		recalculate()
		needs_recalculation = false
	
	last_tick = 0
	make_the_terrain_less_bad()
	do_positive_net_work_on_the_items_located_on_conveyors_and_similar_tiles_that_facillitate_movement()
	world.elapsed_ticks += 1;;;;;;;;;;;;;
	world.sandworm_current_cooldown = max(0, world.sandworm_current_cooldown - 1)
	gui.resources(str(floor(world.elapsed_ticks / 900)))

func summon_the_sandworm_from_the_depths_of_the_dunes(gc:Vector2i, lc:Vector3i, index:int):
	var e = explosion.instantiate()
	add_child(e)
	e.position = gc * tile_size
	e.explode()
	for x in range(3):
		for y in range(3):
			var coords = gc + Vector2i(x - 2, y - 2)
			if (world.bounds.has_point(coords)):
				set_tile(0, coords, 0, 0)
				var local = global2local(coords)
				world.integrity[local.z][local2index(Vector2i(local.x, local.y))] = -40
				set_terrain(3, coords, 2001)
	
	camera.camera_shake(0.4, 40, 30, 10)
	

func recalculate():
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


#func initiate_resource_movement(tile_pos):
	#var local_coords = global2local(tile_pos)
	#var index = local2index(Vector2i(local_coords.x, local_coords.y))
	#var rotation = world.tiledata[local_coords.z]["rotation"][index]
	#
	#if world.tiles[local_coords.z][index] == 6:
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
	var current_tile = world.tiles[lc.z][idx]
	var next_gc = gc + SIDES[direction]
	var next_lc = global2local(next_gc)
	var next_idx = local2index(Vector2i(next_lc.x, next_lc.y))
	var id = world.items[lc.z][idx]
	
	
	if (world.items[next_lc.z][next_idx] == 0):
		match int(world.tiles[next_lc.z][next_idx]):
			3:
				if (int(int(world.tiledata[next_lc.z]["state"][next_idx]) + \
				world.tiledata[next_lc.z]["rotation"][next_idx]) % 4 == direction):
					set_item(1, gc, 0)
					set_item(1, next_gc, id)
			_:
				set_item(1, gc, 0)
				set_item(1, next_gc, id)
	else: # clogged
		world.noise[lc.z][idx] += 6
	
	#if next_tile and world.tiles[next_tile.z][local2index(Vector2i(next_tile.x, next_tile.y))] == 6:
		#print("Moving resource from ", tile_pos, " to ", next_tile)
	#else:
		#print("Cannot move in that direction or no conveyor")

#endregion

func rotate_conveyor(tile_pos): 
	var local_coords = global2local(tile_pos)
	var index = local2index(Vector2i(local_coords.x, local_coords.y))
	var tile = world.tiles[local_coords.z][index]
	var rotation:int = world.tiledata[local_coords.z]["rotation"][index]
	
	rotation = (rotation + 1) % 4
	world.tiledata[local_coords.z]["rotation"][index] = rotation
	set_cell(0, tile_pos, tile, Vector2i(0, 0), rotation)

func neighbor(gc:Vector2i, dir:int):
	var tile = gc + SIDES[dir]
	if world.bounds.has_point(tile):
		return tile
	return null



#func neighbor_index(chunk:int, index:int, direction:int):
#	var location:Vector3
#	var x:int = index % world.chunk_size
#	var y:int = floor(index / world.chunk_size)
#
#	return location


# Coordinate stuff:
#region
func gc2string(gc:Vector2i):
	return str(gc.x) + "," + str(gc.y)


func local2index(local_coords:Vector2i):
	return local_coords.x + local_coords.y * world.chunk_size

func index2local(index, chunk):
	return Vector3i(index % world.chunk_size, floor(index / world.chunk_size), chunk)

func local2global(local_coords:Vector3i):
	var c = Vector2i(local_coords.z % world.world_size, floor(local_coords.z / world.world_size))
	return Vector2i(local_coords.x + c.x * world.chunk_size, local_coords.y + c.y * world.chunk_size)

func global2local(global_coords:Vector2i):
	return Vector3i(global_coords.x % world.chunk_size, \
		global_coords.y % world.chunk_size, \
		floor(global_coords.x / world.chunk_size) + world.world_size*floor(global_coords.y/world.chunk_size))

func set_tile(layer:int, global_coords:Vector2i, tile:int, rotation:int):
#	no storage data yet
	var local_coords = global2local(global_coords)
	var index = local2index(Vector2i(local_coords.x, local_coords.y))
	
#	world.tiledata[local_coords.z]["storage"][local_coords.x + local_coords.y * world.chunk_size] = null
	world.tiles[local_coords.z][index] = tile
	world.tiledata[local_coords.z]["rotation"][index] = rotation
	print(global_coords)
	print(local_coords)
	self.set_cell(layer, \
			global_coords, tile, \
			Vector2i.ZERO, rotation
			)
	
	_on_world_updated()

func set_item(layer:int, global_coords:Vector2i, tile:int):
	var local_coords = global2local(global_coords)
	
	world.items[local_coords.z][local_coords.x + local_coords.y * world.chunk_size] = tile
	self.set_cell(layer, \
			global_coords, tile, \
			Vector2i.ZERO, rotation
			)

func set_terrain(layer:int, global_coords:Vector2i, tile:int):
	var local_coords = global2local(global_coords)
	
	world.terrain[local_coords.z][local_coords.x + local_coords.y * world.chunk_size] = tile
	self.set_cell(layer, \
			global_coords, tile, \
			Vector2i.ZERO, rotation
			)

func debug_marker(global_coords:Vector2i, color:Color):
	var a = Polygon2D.new()
	a.polygon = [Vector2(0.8,0.8), Vector2(-0.8,0.8), Vector2(-0.8,-0.8), Vector2(0.8,-0.8)]
	a.color = color
	a.position = Vector2(tile_size * global_coords.x + 8, \
		tile_size * global_coords.y + 8)
	$Debug.add_child(a)

func debug_text(global_coords:Vector2i, text:String):
	var a = $DebugText.duplicate()
	a.text = text
	a.z_index = 10
	a.clip_contents = false
	#var theme = load("res://assets/theme.tres")
	#a.set_theme(theme)
	a.position = Vector2(tile_size * global_coords.x + 8, \
		tile_size * global_coords.y + 8)
	$Debug.add_child(a)

func clear_markers():
	for node in $Debug.get_children():
		$Debug.remove_child(node)

#endregion

# Setup
#region

func setup():
	json.setup(tile_size)
	self.tile_set = json.tileset
	
	self.world = json.world
	
	var a = []
	a.resize(world.bounds.size.y)
	a.fill(0)
	for i in world.bounds.size.x:
		# make duplicate or else everything decides to use the same array
		used_tiles.append(a.duplicate())
	
	set_tilemap_tiles()
	set_tilemap_items()
	_on_world_updated()

func set_tilemap_tiles():
	for c in len(world.tiles):
		for i in world.chunk_area:
			#print(world.tiles[c][i])
			# left to right, top to bottom
			self.set_cell(0, \
				Vector2i(fmod(i, world.chunk_size) + (c % world.world_size)*world.chunk_size, \
					floor(i / world.chunk_size) + floor(c / world.world_size)*world.chunk_size), world.tiles[c][i], \
				Vector2i.ZERO, world.tiledata[c]["rotation"][i]
			)

func set_tilemap_items():
	for c in len(world.items):
		for i in world.chunk_area:
			#print(world.tiles[c][i])
			# left to right, top to bottom
			self.set_cell(1, \
				Vector2i(fmod(i, world.chunk_size) + (c % world.world_size)*world.chunk_size, \
					floor(i / world.chunk_size) + floor(c / world.world_size)*world.chunk_size), world.items[c][i], \
				Vector2i.ZERO, 0
			)


#endregion

func _on_selection_changed(selected_tile, tile_rotation):
	self.selected_tile = int(selected_tile)
	self.tile_rotation = int(tile_rotation)

func _on_world_focused(state):
	world_accepts_input = state

func _on_world_updated():
	needs_recalculation = true
