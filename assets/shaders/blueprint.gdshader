shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec4 color : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float brightness = 5.0;

void fragment() {
	vec4 screen = texture(TEXTURE, UV);
	float luminance = (0.30 * screen.r + 0.58 * screen.g + 0.12 * screen.b) * brightness;
	COLOR = vec4(color.r * luminance, color.g * luminance, color.b * luminance, screen.a);
	
}
