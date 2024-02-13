shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec4 color : source_color = vec4(1, 1, 1, 1);
uniform float noise_size = 512;
uniform float amount = 0.8;
uniform sampler2D noise : repeat_enable, filter_nearest;


void fragment()
{
	
	vec4 n = texture(noise, (SCREEN_UV / SCREEN_PIXEL_SIZE  
		* max(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y)) * vec2(2, 2));
	
//	COLOR = n * color;
	n = n * color;
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
//	COLOR = vec4(1) - (vec4(1) - texture(SCREEN_TEXTURE, SCREEN_UV)) * (vec4(1) - n);
	COLOR = mix(2.0 * screen * n, 1.0 - 2.0 * (1.0 - screen) * (1.0 - n), step(0.5, screen));
	COLOR = mix(COLOR, screen, amount);
	
}