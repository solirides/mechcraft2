extends Node2D


@export var json:Node = null
@export var noise_sprite:Sprite2D = null
@export var noise_sprite2:Sprite2D = null
@export var thresholds:Dictionary = {-0.4: 1001, -0.5: 1002, -0.96:1001, -1.0: 1002}
#@export var thresholds:Dictionary = {-1.0: 1001}
@export var ore_thresholds:Array = [[1101, -1.0, -0.75], [1102, -1.0, -0.75], [1103, -1.0, -0.78], [1105, -1.0, -0.7]]

var ore_noise = FastNoiseLite.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	#await tilemap.ready
	pass

func setup():
	var a = json.world["chunk_size"] * json.world["world_size"]
	noise_sprite.texture.width = a
	noise_sprite.texture.height = a
	noise_sprite.texture.noise.seed = json.world["seed"]
	
	noise_sprite2.texture.width = a
	noise_sprite2.texture.height = a
	noise_sprite2.texture.noise.seed = json.world["seed"]
	
	ore_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	ore_noise.fractal_octaves = 2
	ore_noise.frequency = 0.05
	ore_noise.fractal_lacunarity = 5.0
	ore_noise.seed = json.world["seed"]
	
	#noise_sprite.scale = Vector2(16,16)
	generate_world()

func generate_world():
	var a = json.world["chunk_size"] * json.world["world_size"]
	for x:float in a:
		for y:float in a:
			var placed = false
			#if value > 0.6:
				#tilemap.set_terrain(2, Vector2i(x, y), 1101)
			for i in len(ore_thresholds):
				var value = noise_sprite2.texture.noise.get_noise_3d(x, y, 10 * i)
				if float(ore_thresholds[i][1]) < value and value < float(ore_thresholds[i][2]):
					#json.tilemap.set_terrain(2, Vector2i(x, y), ore_thresholds[k])
					var gc = Vector2i(x, y)
					var lc = Globals.global2local(gc, json.world["chunk_size"], json.world["world_size"])
					var idx = Globals.local2index(Vector2i(lc.x, lc.y), json.world["chunk_size"])
						
					json.world["chunks"][str(lc.z)]["terrain"][idx] = ore_thresholds[i][0]
					placed = true
					break
				
			
			if placed != true:
				var value = noise_sprite.texture.noise.get_noise_2d(x, y)
				#print(value)
				for k in thresholds.keys():
					#print(k)
					if value > float(k):
						#print("set")
						#json.tilemap.set_terrain(2, Vector2i(x, y), thresholds[k])
						var gc = Vector2i(x, y)
						var lc = Globals.global2local(gc, json.world["chunk_size"], json.world["world_size"])
						var idx = Globals.local2index(Vector2i(lc.x, lc.y), json.world["chunk_size"])
						
						json.world["chunks"][str(lc.z)]["terrain"][idx] = thresholds[k]
						
						break


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
