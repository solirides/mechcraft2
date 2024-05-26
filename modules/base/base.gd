extends Node2D


@export_dir var texture_dir:String = "res://modules/base/textures/"
@export var order = ["platform", "cables", "fence", "overlay_1", "control_building", "satellite_dish", "cylinders", "crane", "overlay_2", "tower", "ship_boosters", "ship_tail", "ship_hull", "ship_front", "overlay_3"]
@export var overlays = ["overlay_1", "overlay_2", "overlay_3"]
@export var overlay_shader:Resource = null

var sprites = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open(texture_dir)
	
	if dir:
		print("dir exists")
		dir.list_dir_begin()
		for file_name in dir.get_files():
			if dir.current_is_dir():
				continue
			if file_name.replace('.import', '').ends_with(".png"):
				var sprite = TextureRect.new()
				var texture = load(texture_dir + file_name.replace('.import', ''))
				
				sprite.custom_minimum_size = Vector2(128, 128)
				sprite.texture = texture
				
				sprites[file_name.replace('.import', '').trim_suffix(".png")] = sprite
				
				print(file_name)
				print(file_name.replace('.import', ''))
		
		for k in overlays:
			#sprites[k].material = ShaderMaterial.new()
			#sprites[k].material.shader = overlay_shader
			sprites[k].material = CanvasItemMaterial.new()
			sprites[k].material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			
			sprites[k].modulate = Color(1,1,1,0.4)
		
		for k in order:
			sprites[k].visible = false
			self.add_child(sprites[k])
	
	dir = null

func show_layer(name:String, visible=true):
	if order.has(name):
		sprites[name].visible = visible

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
