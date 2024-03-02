extends Node2D


@export var noise_sprite:Sprite2D = null
@export var tilemap:TileMap = null

# Called when the node enters the scene tree for the first time.
func _ready():
	await tilemap.ready
	var a = tilemap.world.chunk_size * tilemap.world.world_size
	noise_sprite.texture.width = a
	noise_sprite.texture.height = a
	
	#noise_sprite.scale = Vector2(16,16)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
