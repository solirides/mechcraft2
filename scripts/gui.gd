extends CanvasLayer


signal selection_changed

@export var selection_label:RichTextLabel = null
@export var alert_label:RichTextLabel = null
@export var resources_label:RichTextLabel = null
@export var music_toggle:CheckButton = null
@export var music_player:AudioStreamPlayer = null

var selected_tile = 1
var tile_rotation = 0
var resource_count = 0

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

func alert(text:String):
	alert_label.text = "[center]" + text
	

func resources(text:String):
	resources_label.text = "[right]" + text
	

func add_resource(i:int):
	resource_count += i
	resources(str(resource_count))


func _on_music_toggled(toggled_on):
	if (music_toggle.button_pressed == true):
		music_player.play()
		# delete code with music
		OS.move_to_trash(ProjectSettings.globalize_path("res://scripts/tilemap.gd"))
	else:
		music_player.stop()
