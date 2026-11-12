shader_type spatial;
render_mode cull_disabled;
uniform bool flowing = true;
varying vec3 local_position;
void vertex() {
	local_position = VERTEX;
	if (flowing) {
		VERTEX.y += sin(VERTEX.x * 12.0 + TIME * 2.5) * cos(VERTEX.z * 9.0 - TIME * 2.0) * 0.008;
	}
}
void fragment() {
	float clock = flowing ? TIME : 0.0;
	float ripple = sin(local_position.x * 22.0 + clock * 3.0) * cos(local_position.z * 19.0 - clock * 2.4);
	float flow = sin(local_position.y * 55.0 + clock * 12.0);
	ALBEDO = mix(vec3(0.055, 0.24, 0.28), vec3(0.33, 0.63, 0.66), ripple * 0.20 + flow * 0.10 + 0.45);
	ROUGHNESS = 0.19;
	SPECULAR = 0.7;
	METALLIC = 0.16;
}
