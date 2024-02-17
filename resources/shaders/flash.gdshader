shader_type canvas_item;

uniform vec4 flash_color: source_color = vec4(1.0);
uniform float intensity: hint_range(0.0, 0.5, 0.05) = 0.4;
uniform float speed: hint_range(1.0, 12.0, 0.5) = 5.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float i =  step(0.5, intensity * sin(speed * TIME) + 0.5);
	color.rgb = mix(color.rgb, flash_color.rgb, i);
	COLOR = color;
}
