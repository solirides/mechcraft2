extends Node2D


var pos = Vector2(100,100)
var size:int = 256/2
var zoom = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func draw_grid(pos:Vector2, zoom:float):
	self.pos = pos
	self.zoom = zoom
	queue_redraw()

func _draw():
	var space = size * zoom
	
	var origin = Vector2(get_viewport().size.x / 2 - pos.x * zoom, \
		get_viewport().size.y / 2 - pos.y * zoom)
		
	var offset = fmod(origin.x, space)
#	offset = 0
	
#	print(floor(get_viewport().size.x / size / zoom))
	
#	draw_circle(Vector2(offset,10), 10, Color(1,0.5,1,1))
	
	for i in range(get_viewport().size.x / space + 2):
		draw_line(Vector2(space * i + offset, 0), \
			Vector2(space * i + offset, get_viewport().size.y), Color(1,1,1,1))
	
	offset = fmod(origin.y, space)
	
	for i in range(get_viewport().size.y / space + 2):
		draw_line(Vector2(0, space * i + offset), \
			Vector2(get_viewport().size.x, space * i + offset), Color(1,1,1,1))
	
	draw_line(Vector2(0, origin.y), \
			Vector2(get_viewport().size.x, origin.y), Color(1,0.1,0,1), 3)
	
	draw_line(Vector2(origin.x, 0), \
			Vector2(origin.x, get_viewport().size.x), Color(0,1,0.2,1), 3)
