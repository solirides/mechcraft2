extends Node2D


@export_dir var texture_dir:String = "res://modules/base/textures/"
@export var order = ["platform", "cables", "fence", "overlay_1", "control_building", "satellite_dish", "cylinders", "crane", "overlay_2", "tower", "ship", "overlay_3"]
@export var overlays = ["overlay_1", "overlay_2", "overlay_3"]
@export var overlay_shader:Resource = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open(texture_dir)
	var sprites = {}
	
	if dir:
		dir.list_dir_begin()
		for file_name in dir.get_files():
			if dir.current_is_dir():
				continue
			if file_name.ends_with(".png"):
				var sprite = TextureRect.new()
				var texture = load(texture_dir + file_name)
				
				sprite.custom_minimum_size = Vector2(128, 128)
				sprite.texture = texture
				
				sprites[file_name.trim_suffix(".png")] = sprite
				
				print(file_name)
		
		for k in overlays:
			#sprites[k].material = ShaderMaterial.new()
			#sprites[k].material.shader = overlay_shader
			sprites[k].modulate = Color(2,2,2,0.1)
		
		for k in order:
			self.add_child(sprites[k])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
