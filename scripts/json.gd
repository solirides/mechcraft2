extends Node

class_name Json

@export var json: Dictionary

func _ready():
	json = ReadData("res://assets/world.json")
	print(json["chunks"][0]["tiles"])


func ReadData(file_path):
	
	var json_data
	var file_data = FileAccess.open(file_path, FileAccess.READ)
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(file_data.get_as_text())
	json_data = test_json_conv.get_data()
	
	if file_data.get_error() == OK:
		print(json_data)
	else:
		print("Error: ", json_data.error)
		print("Error Line: ", json_data.error_line)
		print("Error String: ", json_data.error_string)
	
	file_data = null
	return json_data

