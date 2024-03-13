extends Node2D


@export var noise_sprite:Sprite2D = null
@export var tilemap:TileMap = null

# Called when the node enters the scene tree for the first time.
func _ready():
	await tilemap.ready
	var a = tilemap.world.chunk_size * tilemap.world.world_size
	noise_sprite.texture.width = a
	noise_sprite.texture.height = a
	
	noise_sprite.texture.noise.seed = tilemap.world.seed
	#noise_sprite.scale = Vector2(16,16)
	generate_world()

func generate_world():
	var a = tilemap.world.chunk_size * tilemap.world.world_size
	for x:float in a:
		for y:float in a:
			var value = noise_sprite.texture.noise.get_noise_2d(x, y)
			#print(value)
			if value > -0.4:
				#print("terrain")
				tilemap.set_terrain(2, Vector2i(x, y), 1002)
			else:
				tilemap.set_terrain(2, Vector2i(x, y), 1001)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
