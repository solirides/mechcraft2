extends TileMap




var explosion = preload("res://modules/explosion/explosion.tscn")

@export var json:Node = null
@export var base:Node = null
@export var debug_dot:Polygon2D = null
@export var camera:Node = null
#@export var tooltip:Node = null
@export var selector:Node = null
@export var tile_size = 16

@onready var gui:CanvasLayer = camera.gui

var world_accepts_input = true
var running = false
var tps:float = 3
var last_tick = 0
var highest_noise = 0

# these vars are all from the world save file

var world:Dictionary = {}

var result:Array[Array]

# these all correspond to each other
var lines_global:Dictionary = {}
var priorities_global:Dictionary = {}
var priorities_index:Array[Array] = []


var infinite_loop:Array[Array] = []
var max_priority:int = 0
var used_tiles:Array[Array] = [] # 0 = unprocessed; 1 = completely processed; 2 = somewhat processed
var needs_recalculation = true
var world_loaded = false

const SIDES = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var input_direction
var input_started = false
var input_start_gc = null
var selected_tile = 1
var tile_rotation = 0

var tileset = TileSet.new()
var bounds:Rect2

signal storage_changed()
signal objective_changed()
signal tick_processed(elapsed_ticks:int)

# Called when the node enters the scene tree for the first time.
func _ready():
#	print(json.json)
	await camera.ready
	#await json.ready
	#await camera.gui.ready
	self.storage_changed.connect(_on_storage_changed)
	self.objective_changed.connect(_on_objective_changed)
	
	gui.selection_changed.connect(_on_selection_changed)
	gui.world_focused.connect(_on_world_focused)
	gui.save.connect(save_game)
	
	#await get_tree().create_timer(1.0).timeout
	
	setup()
	
	gui.noise_bar.max_value = world["settings"]["sandworm_noise_thresholds"][2]
	gui.noise_bar.value = 0
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if world_loaded == true:
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
		
		gui.tooltip.visible = false
		if bounds.has_point(gc):
			if world["chunks"][str(lc.z)]["tiles"][idx] == 6:
				gui.tooltip.visible = true
				gui.update_tooltip()
		
		selector.position = selector.position.lerp(gc * tile_size, delta * 10)
		
		if input_started:
			var offset_y = 0
			var offset_x = 0
			if input_direction == 1:
				$LineY.points[0] = $LineY.points[0].lerp(Vector2(gc.x, input_start_gc.y) * tile_size + Vector2(tile_size*0.5, tile_size*0.5), delta * 10)
				$LineY.points[1] = $LineY.points[1].lerp(Vector2(gc)*tile_size + 0.5*Vector2(tile_size, tile_size), delta * 10)
				
				$LineX.points[0] = $LineX.points[0].lerp(Vector2(input_start_gc) * tile_size + Vector2(tile_size*0.5, tile_size*0.5), delta * 10)
				$LineX.points[1] = $LineX.points[1].lerp(Vector2(gc.x, input_start_gc.y)*tile_size + 0.5*Vector2(tile_size, tile_size), delta * 10)
			elif input_direction == 2:
				$LineY.points[0] = $LineY.points[0].lerp(Vector2(input_start_gc) * tile_size + Vector2(tile_size*0.5, tile_size*0.5), delta * 10)
				$LineY.points[1] = $LineY.points[1].lerp(Vector2(input_start_gc.x, gc.y)*tile_size + 0.5*Vector2(tile_size, tile_size), delta * 10)
				
				$LineX.points[0] = $LineX.points[0].lerp(Vector2(input_start_gc.x, gc.y) * tile_size + Vector2(tile_size*0.5, tile_size*0.5), delta * 10)
				$LineX.points[1] = $LineX.points[1].lerp(Vector2(gc)*tile_size + 0.5*Vector2(tile_size, tile_size), delta * 10)
			
			

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
			gui.update_hotbar(world["central_storage"])
		
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
			#print(world.noise[0])
			
		if event.is_action_pressed("pause"):
			running = !running
		
		if Input.is_action_just_pressed("save"):
			print("write to save file")
			#json.create_save()
			json.write_save()

func _unhandled_input(event):
	if world_accepts_input:
		if input_started == true:
			if event.is_action_pressed("remove"):
				cancel_input()
			elif event is InputEventMouseMotion:
				var p = get_global_mouse_position()
				var gc = Vector2i(floor(p.x/tile_size), floor(p.y/tile_size))
				var lc = global2local(gc)
				
				input_mouse_motion(gc, lc, local2index(Vector2i(lc.x, lc.y)), input_start_gc)
			
			if Input.is_action_just_released("place"):
				var p = get_global_mouse_position()
				var gc = Vector2i(floor(p.x/tile_size), floor(p.y/tile_size))
				var lc = global2local(gc)
				input_end(gc, selected_tile, tile_rotation, input_start_gc, input_direction)
		else:
			if Input.is_action_pressed("place"):
				var p = get_global_mouse_position()
				var gc = Vector2i(floor(p.x/tile_size), floor(p.y/tile_size))
				var lc = global2local(gc)
				var idx = local2index(Vector2i(lc.x, lc.y))
				
				if selected_tile == 1:
					input_start(gc, lc, local2index(Vector2i(lc.x, lc.y)))
				else:
					place_tile(gc, lc, idx, selected_tile, tile_rotation)
			
			if Input.is_action_pressed("remove"):
				var p = get_global_mouse_position()
				var gc = Vector2i(floor(p.x/tile_size), floor(p.y/tile_size))
				var lc = global2local(gc)
				var idx = local2index(Vector2i(lc.x, lc.y))
				
				if (bounds.has_point(gc)):
					var e = explosion.instantiate()
					add_child(e)
					e.position = gc * tile_size
					e.explode()
					camera.camera_shake(0.4, 16, 50, 10)
					remove_tile(gc, lc, idx)
			
			if event.is_action_pressed("delay_tile"):
				var p = get_global_mouse_position()
				var gc = Vector2i(floor(p.x/tile_size), floor(p.y/tile_size))
				var lc = global2local(gc)
				var idx = local2index(Vector2i(lc.x, lc.y))
				
				if (bounds.has_point(gc)):
					decrease_state(gc, lc, idx)
				
		
		if Input.is_action_pressed("pan") and event is InputEventMouseMotion:
			camera.camera.position -= event.relative / camera.camera.zoom
		
		if false:
			var p = get_global_mouse_position()
			var tile_pos = Vector2i(floor(p.x / tile_size), floor(p.y / tile_size))
			rotate_conveyor(tile_pos)
	
		if event.is_action_pressed("resource"):
			var p = get_global_mouse_position()
			print("resource spawned")
			set_item(1, Vector2i(floor(p.x/tile_size), floor(p.y/tile_size)), 3001)
		
		
		


func remove_tile(gc, lc, idx):
	if (bounds.has_point(gc) and world["chunks"][str(lc.z)]["integrity"][idx] >= 0):
		#if world["chunks"][str(lc.z)]["tiles"][idx] != id:
		var old_id = world["chunks"][str(lc.z)]["tiles"][idx]
		if old_id != 7:
			if old_id != 0:
				if world["central_storage"].has(str(old_id)):
					world["central_storage"][str(old_id)] += 1
				else:
					world["central_storage"][str(old_id)] == 1
				
				set_tile(0, gc, 0, 0)
				self.storage_changed.emit()


func place_tile(gc, lc, idx, id, rotation):
	if (bounds.has_point(gc) and world["chunks"][str(lc.z)]["integrity"][idx] >= 0):
		#if world["chunks"][str(lc.z)]["tiles"][idx] != id:
		var old_id = world["chunks"][str(lc.z)]["tiles"][idx]
		if old_id != 7:
			if old_id != 0:
				if world["central_storage"].has(str(old_id)):
					world["central_storage"][str(old_id)] += 1
				else:
					world["central_storage"][str(old_id)] == 1
				
			if world["central_storage"].has(str(id)) and world["central_storage"][str(id)] > 0:
				set_tile(0, gc, id, rotation)
				world["central_storage"][str(id)] -= 1
				self.storage_changed.emit()
			else:
				gui.alert("Not enough resources")

func input_start(gc, lc, idx):
	input_start_gc = gc
	input_started = true
	input_direction = 0
	$LineX.visible = true
	$LineY.visible = true
	
	$LineX.points[0] = Vector2(gc) * tile_size
	$LineX.points[1] = Vector2(gc) * tile_size
	$LineY.points[0] = Vector2(gc) * tile_size
	$LineY.points[1] = Vector2(gc) * tile_size

func input_mouse_motion(gc, lc, idx, input_start_gc):
	var a:Vector2i = gc - input_start_gc
	#if a != Vector2i(0,0):
		#if abs(a.x) > abs(a.y):
			#input_direction = 1
		#else:
			#input_direction = 2
	if a.x == 0:
		input_direction = 2
	elif a.y == 0:
		input_direction = 1
	#else:
		#input_direction = 0
	

func input_end(gc, id, rotation, input_start_gc, input_direction):
	if input_start_gc == gc:
		var lc = global2local(gc)
		var idx = local2index(Vector2i(lc.x, lc.y))
		place_tile(gc, lc, idx, selected_tile, tile_rotation)
	else:
		match input_direction:
			0:
				var lc = global2local(gc)
				var idx = local2index(Vector2i(lc.x, lc.y))
				place_tile(gc, lc, idx, selected_tile, tile_rotation)
			1:
				var s = -sign(input_start_gc.x - gc.x)
				for x in range(abs(input_start_gc.x - gc.x) + 1):
					var lc = global2local(input_start_gc + s * Vector2i(x, 0))
					var idx = local2index(Vector2i(lc.x, lc.y))
					place_tile(input_start_gc + s * Vector2i(x, 0), lc, idx, selected_tile, (s + 4) % 4)
				
				s = -sign(input_start_gc.y - gc.y)
				if s != 0:
					for y in range(abs(input_start_gc.y - gc.y) + 1):
						var lc = global2local(Vector2i(gc.x, input_start_gc.y + s * y))
						var idx = local2index(Vector2i(lc.x, lc.y))
						place_tile(Vector2i(gc.x, input_start_gc.y + s * y), lc, idx, selected_tile, (s + 5) % 4)
				
			2:
				var s = -sign(input_start_gc.y - gc.y)
				for y in range(abs(input_start_gc.y - gc.y) + 1):
					var lc = global2local(input_start_gc + s * Vector2i(0, y))
					var idx = local2index(Vector2i(lc.x, lc.y))
					place_tile(input_start_gc + s * Vector2i(0, y), lc, idx, selected_tile, (s + 5) % 4)
				
				s = -sign(input_start_gc.x - gc.x)
				if s != 0:
					for x in range(abs(input_start_gc.x - gc.x) + 1):
						var lc = global2local(Vector2i(input_start_gc.x + s * x, gc.y))
						var idx = local2index(Vector2i(lc.x, lc.y))
						place_tile(Vector2i(input_start_gc.x + s * x, gc.y), lc, idx, selected_tile, (s + 4) % 4)
	
	input_started = false
	$LineX.visible = false
	$LineY.visible = false

func cancel_input():
	input_started = false
	$LineX.visible = false
	$LineY.visible = false

# Detecting conveyor lines:
#region
func detect_world_tiles():
#	var cells = self.get_used_cells(0)
	var d = [world["chunk_size"], 1, -world["chunk_size"], -1]
	var lines:Array[Vector2i] = []
	
	for c in world["world_size"]**2:
		for index in world["chunk_area"]:
	#		print(world.tiles[0][index])
			# one chunk
			var gc = local2global(index2local(index, c))
			if [5, 7].has(int(world["chunks"][str(c)]["tiles"][index])):
#				print(Vector3i(index % world["chunk_size"], floor(index / world["chunk_size"]), c))
#				print(gc)
				debug_marker(gc, Color(1, 0, 1, 0.7))
				used_tiles[gc.x][gc.y] == 1
				var a = detect_connections(gc, world["chunks"][str(c)]["tiles"][index], 1, 0, true)
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
			neighbors = [0,1, 2, 3]
	
	while loop:
		loop = false
		split = false
		tile = n_tile
		dir =  n_dir
		#print(str(tile) + " tile")
		for b:int in neighbors:
			var neighbor_dir = (b + dir) % 4 # direction to neighbor from current tile
			var facing_gc:Vector2i = tile + SIDES[(b + dir) % 4]
			var facing_lc:Vector3i = global2local(facing_gc)
			#print(facing_lc)
			#print(str(facing_gc) + " gc")
			if not bounds.has_point(Vector2i(facing_lc.x,facing_lc.y)) or used_tiles[facing_gc.x][facing_gc.y] == 1:
				# out of bounds
				#print("a")
				#print(bounds.has_point(Vector2i(facing_lc.x,facing_lc.y)))
				#print(used_tiles[facing_lc.x][facing_lc.y])
				continue
			var c = facing_lc.z
			var facing_idx:int = local2index(Vector2i(facing_lc.x,facing_lc.y))
			var facing_rot:int = world["chunks"][str(c)]["rotation"][facing_idx]
			var facing_tile:int = world["chunks"][str(c)]["tiles"][facing_idx]
			#print(str(facing_tile) + " facing tile")
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
				6:
					if facing_rot == (neighbor_dir + 2) % 4:
						used_tiles[facing_gc.x][facing_gc.y] = 1
						
						if split:
							#var a = detect_connections(facing_gc, facing_tile, priority + 1, facing_rot, false)
							#print(a)
							var color2 = Color.from_hsv(randf(), randf_range(0.7, 1), randf_range(0.7, 1))
							debug_marker(facing_gc, color2)
							debug_text(facing_gc, str((priority + 1)))
							
							var line2:Array[Vector2i] = [facing_gc]
							result.merge({gc2string(facing_gc):line2})
							priorities.merge({gc2string(facing_gc):int(priority + 1)})
							max_priority = max(max_priority, priority + 1)
							continue
						
						debug_marker(facing_gc, color)
						line.append(facing_gc)
						
						#n_tile = facing_gc
						#n_dir = facing_rot
						#loop = false
						#split = true
				8:
					# same as 2
					if facing_rot == (neighbor_dir + 2) % 4:
						used_tiles[facing_gc.x][facing_gc.y] = 1
						if split:
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

# Processing world tiles
#region

func do_positive_net_work_on_the_items_located_on_conveyors_and_similar_tiles_that_facillitate_movement():
	highest_noise = 0
	for p in priorities_index: # p = array of lines of the same priority
			for p2 in p: # i = index of one line
				# process rest of the line
				for gc in lines_global[p2]:
					var lc = global2local(gc)
					var index = local2index(Vector2i(lc.x, lc.y))
					var id = world["chunks"][str(lc.z)]["tiles"][index]
					if id != 0:
						match int(id):
							1:
								world["chunks"][str(lc.z)]["noise"][index] += 2
								var dir = world["chunks"][str(lc.z)]["rotation"][index]
								# the "last" vars are what the current conveyor points to (since the line's array is reversed)
								#if (world_items[last_lc.z][last_index] == 0):
								move_resource(gc, dir)
								
							2: #constructor
								world["chunks"][str(lc.z)]["noise"][index] += 3
								var item = world["chunks"][str(lc.z)]["items"][index]
								if (item != 0):
									#print("item recieved at constructor")
									var a = gc2string(gc)
									if (world["chunks"][str(lc.z)]["tile_storage"][index] != 0):
										# construct thing
										world["chunks"][str(lc.z)]["noise"][index] += 5
										var key = str(world["chunks"][str(lc.z)]["tile_storage"][index]) + "," + str(item)
										if json.constructor_recipes.has(key):
											set_item(1, gc, json.constructor_recipes[key])
											move_resource(gc, world["chunks"][str(lc.z)]["rotation"][index])
										else:
											set_item(1, gc, 0)
											
										world["chunks"][str(lc.z)]["tile_storage"][index] = 0
									else:
										world["chunks"][str(lc.z)]["tile_storage"][index] = item
										set_item(1, gc, 0)
									# item go bye bye
									#set_item(1, gc, 0)
							
							3:
								world["chunks"][str(lc.z)]["noise"][index] += 3
								if (world["chunks"][str(lc.z)]["items"][index] != 0):
									var dir = world["chunks"][str(lc.z)]["rotation"][index]
									var state = world["chunks"][str(lc.z)]["state"][index]
									move_resource(gc, (dir + int(state)) % 4)
									world["chunks"][str(lc.z)]["state"][index] = not world["chunks"][str(lc.z)]["state"][index]
							4:
								world["chunks"][str(lc.z)]["noise"][index] += 3
								var item = world["chunks"][str(lc.z)]["items"][index]
								var terrain = world["chunks"][str(lc.z)]["terrain"][index]
								if (item != 0):
									move_resource(gc, world["chunks"][str(lc.z)]["rotation"][index])
									#print("miner moving item")
								if (world["chunks"][str(lc.z)]["state"][index] >= 4):
									if json.ores.has(str(terrain)):
										set_item(1, gc, json.ores[str(terrain)])
									world["chunks"][str(lc.z)]["state"][index] = 1
								else:
									world["chunks"][str(lc.z)]["state"][index] += 1
									#print("wait")
								
							5:# storage recieves item
								var item = world["chunks"][str(lc.z)]["items"][index]
								if (item != 0):
									if (not world["central_storage"].has(str(item))):
										world["central_storage"][str(item)] = 1
									else:
										world["central_storage"][str(item)] += 1
									set_item(1, gc, 0)
									self.storage_changed.emit()
							6:
								world["chunks"][str(lc.z)]["noise"][index] += 2
								var item = world["chunks"][str(lc.z)]["items"][index]
								var target_item = world["chunks"][str(lc.z)]["mode"][index]
								if (item != 0):
									move_resource(gc, world["chunks"][str(lc.z)]["rotation"][index])
								if (world["chunks"][str(lc.z)]["state"][index] == 4):
									var input_lc = global2local(gc + SIDES[(world["chunks"][str(lc.z)]["rotation"][index] + 2) % 4])
									if world["chunks"][str(input_lc.z)]["tiles"][local2index(Vector2i(input_lc.x, input_lc.y))] == 5:
										
										if world["central_storage"].has(str(target_item)) and world["central_storage"][str(target_item)] > 0:
											set_item(1, gc, target_item)
											world["central_storage"][str(target_item)] -= 1
											self.storage_changed.emit()
									world["chunks"][str(lc.z)]["state"][index] = 1
								else:
									world["chunks"][str(lc.z)]["state"][index] += 1
							7:
								var item = world["chunks"][str(lc.z)]["items"][index]
								var objective = world["current_objective"]
								if (item != 0):
									print(item)
									#print(world["objectives"][objective]["resources"][0])
									if json.objectives[objective]["resource_goals"].keys().has(str(item)):
										world["objectives"][objective]["resources"][str(item)] += 1
									set_item(1, gc, 0)
									self.objective_changed.emit()
							8:
								world["chunks"][str(lc.z)]["noise"][index] += 3
								var item = world["chunks"][str(lc.z)]["items"][index]
								if (item != 0):
									var a = gc2string(gc)
									if (world["chunks"][str(lc.z)]["tile_storage"][index] != 0):
										world["chunks"][str(lc.z)]["noise"][index] += 5
										var key = str(world["chunks"][str(lc.z)]["tile_storage"][index]) + "," + str(item)
										if json.smelter_recipes.has(key):
											set_item(1, gc, json.smelter_recipes[key])
											move_resource(gc, world["chunks"][str(lc.z)]["rotation"][index])
										else:
											set_item(1, gc, 0)
										world["chunks"][str(lc.z)]["tile_storage"][index] = 0
									else:
										world["chunks"][str(lc.z)]["tile_storage"][index] = item
										set_item(1, gc, 0)
					
					
					var a = world["settings"]["max_noise_decay"]
					for i in len(world["settings"]["sandworm_noise_thresholds"]):
						if world["chunks"][str(lc.z)]["noise"][index] < world["settings"]["sandworm_noise_thresholds"][i]:
							a = world["settings"]["noise_decay_rates"][i]
					world["chunks"][str(lc.z)]["noise"][index] = max(world["chunks"][str(lc.z)]["noise"][index] - a, 0)
					if world["chunks"][str(lc.z)]["noise"][index] >= world["settings"]["sandworm_noise_thresholds"][2] and world["settings"]["sandworm_current_cooldown"] <= 0:
						summon_the_sandworm_from_the_depths_of_the_dunes(gc, lc, index)
						world["settings"]["sandworm_current_cooldown"] = world["settings"]["sandworm_attack_cooldown"]
						
					
					highest_noise = max(highest_noise, world["chunks"][str(lc.z)]["noise"][index])
					
					gui.noise_bar.value = highest_noise
					#last_gc = gc
					#last_lc = lc
					#last_index = index

func make_the_terrain_less_bad():
	for c in world["world_size"]**2:
		for i in world["chunk_area"]:
			var gc = local2global(index2local(i, c))
			if world["chunks"][str(c)]["integrity"][i] < 0:
				world["chunks"][str(c)]["integrity"][i] = min(0, world["chunks"][str(c)]["integrity"][i] + 4)
			else:
				set_overlay(3, gc, -1)

func tick():
	#print("tick")
	if needs_recalculation:
		recalculate()
		needs_recalculation = false
	
	last_tick = 0
	make_the_terrain_less_bad()
	do_positive_net_work_on_the_items_located_on_conveyors_and_similar_tiles_that_facillitate_movement()
	world["elapsed_ticks"] += 1;;;;;;;;;;;;;
	world["settings"]["sandworm_current_cooldown"] = max(0, world["settings"]["sandworm_current_cooldown"] - 1)
	#gui.resources(str(floor(world["elapsed_ticks"] / 900)))
	
	tick_processed.emit(int(world["elapsed_ticks"]))
	

func summon_the_sandworm_from_the_depths_of_the_dunes(gc:Vector2i, lc:Vector3i, index:int):
	var e = explosion.instantiate()
	add_child(e)
	e.position = gc * tile_size
	e.explode()
	for x in range(3):
		for y in range(3):
			var coords = gc + Vector2i(x - 2, y - 2)
			if (bounds.has_point(coords)):
				set_tile(0, coords, 0, 0)
				var local = global2local(coords)
				world["chunks"][str(local.z)]["integrity"][local2index(Vector2i(local.x, local.y))] = -400
				set_overlay(3, coords, 2001)
	
	camera.camera_shake(0.4, 40, 30, 10)
	
	running = false
	gui.popup.visible = true
	

func recalculate():
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



func move_resource(gc:Vector2i, direction:int):
	var lc = global2local(gc)
	var idx = local2index(Vector2i(lc.x, lc.y))
	var current_tile = world["chunks"][str(lc.z)]["tiles"][idx]
	var next_gc = gc + SIDES[direction]
	var next_lc = global2local(next_gc)
	var next_idx = local2index(Vector2i(next_lc.x, next_lc.y))
	var id = world["chunks"][str(lc.z)]["items"][idx]
	
	
	if (world["chunks"][str(next_lc.z)]["items"][next_idx] == 0):
		match int(world["chunks"][str(next_lc.z)]["tiles"][next_idx]):
			3:
				if (int(int(world["chunks"][str(next_lc.z)]["state"][next_idx]) + \
				world["chunks"][str(next_lc.z)]["rotation"][next_idx]) % 4 == direction):
					set_item(1, gc, 0)
					set_item(1, next_gc, id)
			_:
				set_item(1, gc, 0)
				set_item(1, next_gc, id)
		#print("not clogged")
	else: # clogged
		world["chunks"][str(lc.z)]["noise"][idx] += 6
	

#endregion

func rotate_conveyor(gc): 
	var lc = global2local(gc)
	var index = local2index(Vector2i(lc.x, lc.y))
	var tile = world["chunks"][str(lc.z)]["tiles"][index]
	var rotation:int = world["chunks"][str(lc.z)]["rotation"][index]
	
	rotation = (rotation + 1) % 4
	world["chunks"][str(lc.z)]["rotation"][index] = rotation
	set_cell(0, gc, tile, Vector2i(0, 0), rotation)

func neighbor(gc:Vector2i, dir:int):
	var tile = gc + SIDES[dir]
	if bounds.has_point(tile):
		return tile
	return null



#func neighbor_index(chunk:int, index:int, direction:int):
#	var location:Vector3
#	var x:int = index % world["chunk_size"]
#	var y:int = floor(index / world["chunk_size"])
#
#	return location



func change_tick_speed(speed:float):
	if speed == 0:
		running = false
	else:
		running = true
		tps = speed


# Coordinate stuff:
#region
func gc2string(gc:Vector2i):
	return str(gc.x) + "," + str(gc.y)


func local2index(local_coords:Vector2i):
	return local_coords.x + local_coords.y * world["chunk_size"]

func index2local(index:int, chunk:int):
	return Vector3i(index % int(world["chunk_size"]), floor(index / world["chunk_size"]), chunk)

func local2global(local_coords:Vector3i):
	var c = Vector2i(local_coords.z % int(world["world_size"]), floor(local_coords.z / world["world_size"]))
	return Vector2i(local_coords.x + c.x * world["chunk_size"], local_coords.y + c.y * world["chunk_size"])

func global2local(global_coords:Vector2i):
	return Vector3i(global_coords.x % int(world["chunk_size"]), \
		global_coords.y % int(world["chunk_size"]), \
		floor(global_coords.x / world["chunk_size"]) + world["world_size"]*floor(global_coords.y/world["chunk_size"]))

func decrease_state(gc:Vector2i, lc:Vector3i, idx:int):
	if world["chunks"][str(lc.z)]["tiles"][idx] == 4:
		world["chunks"][str(lc.z)]["state"][idx] -= 1

func set_tile(layer:int, gc:Vector2i, tile:int, rotation:int):
	var lc = global2local(gc)
	var index = local2index(Vector2i(lc.x, lc.y))
	
	world["chunks"][str(lc.z)]["tiles"][index] = tile
	world["chunks"][str(lc.z)]["rotation"][index] = rotation
	world["chunks"][str(lc.z)]["state"][index] = 0
	#print(gc)
	#print(lc)
	self.set_cell(layer, \
			gc, tile, \
			Vector2i.ZERO, rotation
			)
	
	_on_world_updated()

func set_item(layer:int, gc:Vector2i, tile:int):
	var lc = global2local(gc)
	var index = local2index(Vector2i(lc.x, lc.y))
	world["chunks"][str(lc.z)]["items"][index] = tile
	self.set_cell(layer, \
			gc, tile, \
			Vector2i.ZERO, rotation
			)

func set_terrain(layer:int, gc:Vector2i, tile:int):
	var lc = global2local(gc)
	var index = local2index(Vector2i(lc.x, lc.y))
	world["chunks"][str(lc.z)]["terrain"][index] = tile
	self.set_cell(layer, \
			gc, tile, \
			Vector2i.ZERO, rotation
			)

func set_overlay(layer:int, gc:Vector2i, tile:int):
	var lc = global2local(gc)
	var index = local2index(Vector2i(lc.x, lc.y))
	self.set_cell(layer, \
			gc, tile, \
			Vector2i.ZERO, rotation
			)

func debug_marker(gc:Vector2i, color:Color):
	var a = Polygon2D.new()
	a.polygon = [Vector2(0.8,0.8), Vector2(-0.8,0.8), Vector2(-0.8,-0.8), Vector2(0.8,-0.8)]
	a.color = color
	a.position = Vector2(tile_size * gc.x + 8, \
		tile_size * gc.y + 8)
	$Debug.add_child(a)

func debug_text(gc:Vector2i, text:String):
	var a = $DebugText.duplicate()
	a.text = text
	a.z_index = 10
	a.clip_contents = false
	#var theme = load("res://assets/theme.tres")
	#a.set_theme(theme)
	a.position = Vector2(tile_size * gc.x + 8, \
		tile_size * gc.y + 8)
	$Debug.add_child(a)

func clear_markers():
	for node in $Debug.get_children():
		$Debug.remove_child(node)

#endregion

# Setup
#region

func setup():
	json.tilemap = self
	json.setup(tile_size)
	self.tile_set = json.tileset
	
	# same dictionary (like literally the same memory address)
	self.world = json.world
	
	var a = []
	a.resize(world["bounds"][1])
	a.fill(0)
	for i in world["bounds"][0]:
		# make duplicate or else everything decides to use the same array
		used_tiles.append(a.duplicate())
	
	self.bounds = Rect2(0, 0, world["bounds"][0], world["bounds"][0])
	
	base.position = tile_size * Vector2(world["base_location"][0] + 1, world["base_location"][1] + 1)
	
	set_tilemap_from_world()
	#json.world_gen.setup()
	_on_world_updated()
	#self.set_cell(0, Vector2i(1,1), 1, Vector2i.ZERO, 0)
	world_loaded = true
	
	self.storage_changed.emit()
	self.objective_changed.emit()
	

func set_tilemap_from_world():
	for c in world["world_size"]**2:
		for i in world["chunk_area"]:
			#print(world["chunks"][str(c)]["tiles"][i])
			var lc:Vector3i = index2local(i, c)
			var gc:Vector2i = local2global(lc)
			#print(gc)
			#if world["chunks"][str(c)]["tiles"][i] != 0:
				#print(world["chunks"][str(c)]["tiles"][i])
				#print(gc)
			self.set_cell(0, gc, int(world["chunks"][str(c)]["tiles"][i]), \
				Vector2i.ZERO, int(world["chunks"][str(c)]["rotation"][i])
			)
			self.set_cell(2, gc, int(world["chunks"][str(c)]["terrain"][i]), \
				Vector2i.ZERO, 0
			)
			self.set_cell(1, gc, int(world["chunks"][str(c)]["items"][i]), \
				Vector2i.ZERO, 0
			)

func set_tilemap_items():
	for c in world["world_size"]**2:
		for i in world["chunk_area"]:
			var lc:Vector3i = index2local(i, c)
			var gc:Vector2i = local2global(lc)
			self.set_cell(1, gc, int(world["chunks"][str(c)]["items"][i]), \
				Vector2i.ZERO, 0
			)
#endregion

func _on_selection_changed(selected_tile, tile_rotation):
	self.selected_tile = int(selected_tile)
	self.tile_rotation = int(tile_rotation)
	self.selector.get_node("Tile").texture = json.texture_from_tile(int(selected_tile))
	
	self.selector.get_node("Tile").rotation_degrees = tile_rotation * 90

func _on_world_focused(state):
	world_accepts_input = state

func _on_world_updated():
	needs_recalculation = true

func _on_storage_changed():
	gui.update_resources(world["central_storage"])
	gui.update_hotbar(world["central_storage"])

func _on_objective_changed():
	var objective = world["current_objective"]
	# there is a better way but i'm lazy
	var complete = true
	for k in world["objectives"][objective]["resources"].keys():
		if world["objectives"][objective]["resources"][k] < int(json.objectives[objective]["resource_goals"][k]):
			complete = false
	
	if complete:
		world["objectives"][objective]["status"] = "completed"
		
		world["current_objective"] = json.objectives[objective]["unlock_objectives"][0]
		objective = world["current_objective"]
		world["objectives"][objective] = {}
		
		world["objectives"][objective]["status"] = "active"
		world["objectives"][objective]["resources"] = {}
		
		for k in json.objectives[objective]["resource_goals"].keys():
			world["objectives"][objective]["resources"][str(k)] = 0
	
	gui.update_objective(objective, world["objectives"][objective])
	

func save_game():
	var file_name = world["file_name"] + str(Time.get_datetime_string_from_system()) + ".json"
	
	json.write_save(Globals.saves_directory + file_name)
	json.write_save(Globals.saves_directory + world["file_name"] + ".json")
	
