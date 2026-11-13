shader_type canvas_item;
// Viloyat holati bo'yicha xaritani bo'yash. idx_tex.r = viloyat raqami + 1 (0 = dengiz).
// states[i]: 0 = yopiq (kulrang), 1 = ochiq, 2 = zabt etilgan (qahramon rangi), 3 = tanlangan.
uniform sampler2D idx_tex : filter_nearest;
uniform float states[16];
uniform vec4 tint : source_color = vec4(0.2, 0.45, 0.9, 1.0);
uniform float time = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	int r = int(round(texture(idx_tex, UV).r * 255.0));
	if (r > 0 && r <= 16) {
		float s = states[r - 1];
		if (s < 0.5) {
			float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
			c.rgb = mix(c.rgb, vec3(g) * 0.72, 0.8);
		} else if (s > 1.5 && s < 2.5) {
			c.rgb = mix(c.rgb, tint.rgb, 0.24);
		} else if (s > 2.5) {
			c.rgb = c.rgb * (1.1 + 0.07 * sin(time * 4.0));
		}
	}
	COLOR = c;
}
