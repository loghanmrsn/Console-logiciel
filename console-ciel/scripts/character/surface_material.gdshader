shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D detail_map : filter_linear_mipmap, repeat_enable;
uniform float tile_scale = 30.0;
uniform float relief = 0.00025;
uniform float roughness_base = 0.75;
uniform float variation = 0.18;
uniform float shine = 0.28;
uniform bool capped = false;
uniform bool skin_coverage = false;
uniform bool evening_dress = false;
uniform bool short_sleeves = false;
varying vec3 surface_position;
varying vec3 surface_normal;
void vertex() {
	surface_position = VERTEX;
	surface_normal = NORMAL;
}
void fragment() {
	if (skin_coverage) {
		float h = surface_position.y;
		bool arm = abs(surface_position.x) > 0.18;
		if (!arm && h < (evening_dress ? 1.278 : 1.373)) { discard; }
		if (arm && h > (evening_dress ? 0.853 : 0.863) && h < (evening_dress ? 1.210 : (short_sleeves ? 1.330 : 1.365)) && (!short_sleeves || h > 1.18)) { discard; }
	}
	if (capped && surface_position.y > 1.594) { discard; }
	vec3 weights = pow(abs(normalize(surface_normal)), vec3(4.0));
	weights /= max(weights.x + weights.y + weights.z, 0.001);
	vec3 data = texture(detail_map, surface_position.yz * tile_scale).rgb * weights.x
		+ texture(detail_map, surface_position.xz * tile_scale).rgb * weights.y
		+ texture(detail_map, surface_position.xy * tile_scale).rgb * weights.z;
	ALBEDO = tint.rgb * (1.0 + (data.r - 0.5) * variation);
	ROUGHNESS = clamp(roughness_base + (data.b - 0.5) * 0.22, 0.25, 1.0);
	SPECULAR = shine;
	METALLIC = 0.0;
	// Screen-space bump gradients work on the original meshes without UV/tangents.
	vec3 s = dFdx(VERTEX), t = dFdy(VERTEX);
	vec3 r1 = cross(t, NORMAL), r2 = cross(NORMAL, s);
	float determinant = dot(s, r1);
	float height = data.g * relief;
	vec3 gradient = sign(determinant) * (dFdx(height) * r1 + dFdy(height) * r2);
	NORMAL = normalize(max(abs(determinant), 0.00000001) * NORMAL - gradient);
}
