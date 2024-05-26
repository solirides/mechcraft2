extends Control


# Called when the node enters the scene tree for the first time.
@export var window:Window = null
@export var level_selector:Node = null
@export var level_creator:Node = null
@export var help:Node = null
@export var background:Node = null

var direction = Vector2i(1, 1)
var screen_size = DisplayServer.screen_get_size()

func _ready():
	level_selector.back.connect(hide_background)
	level_creator.back.connect(hide_background)
	help.back.connect(hide_background)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#get_tree().root.add_child(window)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#moving_window_thing(delta)
	pass


func _on_window_close_requested():
	window.hide()


func moving_window_thing(delta):
	if (window.position.x + 256 >= screen_size.x):
		direction.x = -1
	elif (window.position.x <= 0):
		direction.x = 1
	
	if (window.position.y + 256 >= screen_size.y):
		direction.y = -1
	elif (window.position.y <= 0):
		direction.y = 1
	
	
	#print(window.position.x)
	
	window.position.x += delta * 400 * direction.x
	window.position.y += delta * 400 * direction.y


func _on_load_pressed():
	#Globals.load_game_type = "load"
	level_selector.visible = true
	background.visible = true
	#get_tree().change_scene_to_file("res://modules/level_selector/level_selector.tscn")

func _on_new_pressed():
	#Globals.load_game_type = "new"
	level_creator.visible = true
	background.visible = true
	#get_tree().change_scene_to_file("res://modules/level_creator/level_creator.tscn")


func _on_help_pressed():
	help.visible = true
	background.visible = true


func _on_quit_pressed():
	get_tree().quit()

func hide_background():
	background.visible = false
