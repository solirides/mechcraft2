extends Control



@export_category("Nodes")
@export var box:Node = null

var objective_item = preload("res://modules/gui/objective_item/objective_item.tscn")

var json_data:Dictionary = {}
var json_data2:Dictionary = {}
var tile_textures = {}

signal back

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var file_data = FileAccess.open("res://assets/smelter_recipes.json", FileAccess.READ)
	
	var json_conv = JSON.new()
	json_conv.parse(file_data.get_as_text())
	json_data = json_conv.get_data()
	file_data = null
	
	file_data = FileAccess.open("res://assets/constructor_recipes.json", FileAccess.READ)
	json_conv.parse(file_data.get_as_text())
	json_data2 = json_conv.get_data()
	
	
	file_data = FileAccess.open("res://assets/tile_path_list.json", FileAccess.READ)
	json_conv.parse(file_data.get_as_text())
	var tile_paths:Dictionary = json_conv.get_data()
	
	file_data = null
	
	for id in tile_paths.keys():
		print(tile_paths[id])
		tile_textures[int(id)] = tile_paths[id].get_file().get_basename()
	
	#dir = null
	
	
	
	
	#var i = 0
	#for n in box.get_children():
		#box.remove_child(n)
		#n.queue_free()
	for i in [json_data, json_data2]:
		for j in i.keys():
			var h = HBoxContainer.new()
			h.alignment = BoxContainer.ALIGNMENT_CENTER
			for k in j.split(","):
				var a = objective_item.instantiate()
				a.get_child(0).text = ""
				#a.slot = i
				#a.tile_id = k
				a.texture = texture_from_tile(int(k))
				#a.clicked.connect(_on_hotbar_item_clicked)
				h.add_child(a)
				
			
			var a = Label.new()
			a.text = "+"
			a.label_settings = LabelSettings.new()
			a.label_settings.font_size = 26
			h.add_child(a)
			h.move_child(a, 1)
			
			a = Label.new()
			a.text = "="
			a.label_settings = LabelSettings.new()
			a.label_settings.font_size = 26
			h.add_child(a)
			
			a = objective_item.instantiate()
			a.get_child(0).text = ""
			a.texture = texture_from_tile(int(i[j]))
			h.add_child(a)
			
			box.add_child(h)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_pressed():
	back.emit()
	self.visible = false

func texture_from_tile(id:int):
	return ImageTexture.create_from_image(load("res://assets/tiles/" + self.tile_textures[id] + ".png"))
