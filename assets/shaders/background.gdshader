shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (mod(SCREEN_UV.x / SCREEN_PIXEL_SIZE.x + SCREEN_UV.y / SCREEN_PIXEL_SIZE.y / 4.0 + TIME * 10.0, 8) >= 3.0 + sin(TIME)) {
		COLOR = color1;
	}
	else {
		COLOR = color2;
	}
	if (mod(SCREEN_UV.x / SCREEN_PIXEL_SIZE.x - SCREEN_UV.y / SCREEN_PIXEL_SIZE.y / 4.0 - TIME * 10.0, 8) >= 3.0 + sin(TIME)) {
		COLOR = color1;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
