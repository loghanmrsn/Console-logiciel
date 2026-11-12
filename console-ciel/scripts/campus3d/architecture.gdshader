shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform bool wood = false;
varying vec3 local_position;
float grain(vec3 p) {
	return fract(sin(dot(floor(p), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}
void vertex() { local_position = VERTEX; }
void fragment() {
	float detail = grain(local_position * 140.0) - 0.5;
	float veins = sin(local_position.x * 7.0 + sin(local_position.z * 3.0) * 2.0);
	float pattern = wood ? sin(local_position.z * 100.0 + veins * 4.0) * 0.035 : 0.0;
	ALBEDO = base_color.rgb * (0.95 + detail * 0.055 + pattern);
	ROUGHNESS = wood ? 0.66 : 0.88;
	SPECULAR = 0.2;
}
