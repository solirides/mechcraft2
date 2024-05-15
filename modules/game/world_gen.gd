extends Node2D


@export var noise_sprite:Sprite2D = null
@export var tilemap:TileMap = null
@export var thresholds:Dictionary = {-0.4: 1001, -0.5: 1002, -0.6: 1001, -1: 1002}
@export var ore_thresholds:Dictionary = {-0.75: 1101}

var ore_noise = FastNoiseLite.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	#await tilemap.ready
	pass

func setup():
	var a = tilemap.world["chunk_size"] * tilemap.world["world_size"]
	noise_sprite.texture.width = a
	noise_sprite.texture.height = a
	noise_sprite.texture.noise.seed = tilemap.world["seed"]
	
	ore_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	ore_noise.fractal_octaves = 2
	ore_noise.frequency = 0.05
	ore_noise.fractal_lacunarity = 5.0
	ore_noise.seed = tilemap.world["seed"]
	
	#noise_sprite.scale = Vector2(16,16)
	generate_world()

func generate_world():
	var a = tilemap.world["chunk_size"] * tilemap.world["world_size"]
	for x:float in a:
		for y:float in a:
			var value = ore_noise.get_noise_2d(x, y)
			var placed = false
			#if value > 0.6:
				#tilemap.set_terrain(2, Vector2i(x, y), 1101)
			for k in ore_thresholds.keys():
				if value < float(k):
					tilemap.set_terrain(2, Vector2i(x, y), ore_thresholds[k])
					placed = true
					break
					
			if placed != true:
				value = noise_sprite.texture.noise.get_noise_2d(x, y)
				#print(value)
				for k in thresholds.keys():
					#print(k)
					if value > float(k):
						#print("set")
						tilemap.set_terrain(2, Vector2i(x, y), thresholds[k])
						break


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass