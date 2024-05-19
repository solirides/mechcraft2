extends Node



var load_game_type = "new"
var save_file_name = ""
var saves_directory = "user://saves/"
var world_override_data = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func local2index(local_coords:Vector2i, chunk_size:int):
	return local_coords.x + local_coords.y * chunk_size

func index2local(index:int, chunk:int, chunk_size:int):
	return Vector3i(index % int(chunk_size), floor(index / chunk_size), chunk)

func local2global(local_coords:Vector3i, chunk_size:int, world_size:int):
	var c = Vector2i(local_coords.z % int(world_size), floor(local_coords.z / world_size))
	return Vector2i(local_coords.x + c.x * chunk_size, local_coords.y + c.y * chunk_size)

func global2local(global_coords:Vector2i, chunk_size:int, world_size:int):
	return Vector3i(global_coords.x % int(chunk_size), \
		global_coords.y % int(chunk_size), \
		floor(global_coords.x / chunk_size) + world_size*floor(global_coords.y/chunk_size))
