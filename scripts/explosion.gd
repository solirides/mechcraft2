extends Node2D


@export var fire:Node = null
@export var smoke:Node = null
@export var thing:Node = null


# Called when the node enters the scene tree for the first time.
func _ready():
	fire.one_shot = true
	smoke.one_shot = true
	thing.one_shot = true
	fire.emitting = false
	smoke.emitting = false
	thing.emitting = false
	#explode()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func explode():
	fire.emitting = true
	smoke.emitting = true
	thing.emitting = true
	
	await get_tree().create_timer(1.0).timeout
	
	queue_free()
	
