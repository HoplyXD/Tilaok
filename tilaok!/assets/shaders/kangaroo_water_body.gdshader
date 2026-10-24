shader_type canvas_item;

uniform vec2 region_size = vec2(512.0, 256.0);
uniform float simulation_time = 0.0;

void fragment() {
	vec2 p = UV * max(region_size, vec2(1.0));
	float broad_flow = sin(p.x * 0.018 + p.y * 0.013 + sin(p.y * 0.009) * 1.4 + simulation_time * 0.12);
	float fine_flow = sin(p.x * 0.031 - p.y * 0.021 + sin(p.x * 0.012) * 1.1 - simulation_time * 0.09);
	float caustics = sin(p.x * 0.043 + sin(p.y * 0.027) * 1.8 + simulation_time * 0.07);
	float bands = 0.5 + 0.31 * broad_flow + 0.19 * fine_flow;
	float glint = smoothstep(0.82, 0.98, caustics) * smoothstep(0.05, 0.48, bands);
	vec3 deep_teal = vec3(0.035, 0.34, 0.40);
	vec3 lagoon = vec3(0.075, 0.52, 0.57);
	vec3 light_ripple = vec3(0.40, 0.80, 0.78);
	vec3 body = mix(deep_teal, lagoon, clamp(bands, 0.0, 1.0));
	body = mix(body, light_ripple, glint * 0.42);
	// Start with the same deep teal as the illustrated strip's lower water, then ease into
	// the moving pattern so the transparent art edge disappears into the body.
	float seam = smoothstep(0.0, 52.0, p.y);
	body = mix(vec3(0.025, 0.29, 0.32), body, seam);
	COLOR = vec4(body, 0.36);
}
