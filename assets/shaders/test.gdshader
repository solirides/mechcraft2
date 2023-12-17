shader_type canvas_item;


uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float exponent = 1.0;
uniform float strength = 0.02;
uniform float variation = 0.02;
uniform float frequency = 2.0;

void fragment() {
	vec2 uv_offset = vec2(SCREEN_UV.x - 0.5, SCREEN_UV.y - 0.5) * vec2(2, 2);
//	vec2 offset_map = sign(uv_offset) * pow(vec2(uv_offset.x, uv_offset.y), vec2(3,3));
	vec2 offset_map = sign(uv_offset) * abs(vec2(pow(uv_offset.x, 2), pow(uv_offset.y, 2)));
//	broken math fdgoiuhbsuigfdahiugdoahbjgdf
//	vec2 offset_map = vec2(sign(uv_offset.x) * abs(pow(uv_offset.x, exponent)), sign(uv_offset.y) * abs(pow(uv_offset.y, exponent)));
//	vec2 offset_map = uv_offset;
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
//	float offset = strength * texture(offset_image, SCREEN_UV).r / 100.0;
//	float offset = (sin(TIME * frequency) * variation + strength) * offset_map/ 100.0;
	vec2 offset = offset_map * (vec2(strength, strength) + sin(TIME * frequency) * variation);
//	vec2 offset = offset_map * vec2(strength, strength);
	
	color.r = texture(SCREEN_TEXTURE, SCREEN_UV + offset).r;
	color.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	color.b = texture(SCREEN_TEXTURE, SCREEN_UV - offset).b;
	
//	color.r = texture(SCREEN_TEXTURE, SCREEN_UV).r;
//	color.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
//	color.b = texture(SCREEN_TEXTURE, SCREEN_UV).b;
	
	COLOR = color;
}