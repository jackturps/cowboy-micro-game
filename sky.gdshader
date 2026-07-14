shader_type canvas_item;

uniform sampler2D sky_gradient;
uniform vec2 texture_size;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    mat2 rot = mat2(vec2(c, -s), vec2(s, c));
    return rot * v;
}

void fragment() {
	vec2 centered_uv = -0.5 + UV;
	vec2 px_pos = centered_uv * texture_size;
	
	float uv_height = 1.0 - UV.y;
	COLOR = texture(sky_gradient, vec2(uv_height, 0.0));
	
	float space_prox = smoothstep(0.5, 0.8, uv_height);
	for (int lattice_idx = 0; lattice_idx < 3; lattice_idx++) {
		vec2 rotated_px_pos = rotate(px_pos,  float(lattice_idx) * 3.0 / 17.0);
		vec2 cell_size = vec2(5000, 4000);
		vec2 local_pos = mod(rotated_px_pos, cell_size);
		vec2 cell_center = 0.5 * cell_size;
		
		float star_prox = smoothstep(80.0, 50.0, length(cell_center - local_pos));
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0), star_prox * space_prox);
	}
	
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
