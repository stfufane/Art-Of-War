shader_type canvas_item;

uniform vec4 flash_color: source_color = vec4(1.0);
uniform float intensity: hint_range(0.0, 0.5, 0.05) = 0.4;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	color.rgb = mix(color.rgb, flash_color.rgb, intensity * sin(5.0 * TIME));
	COLOR = color;
}
