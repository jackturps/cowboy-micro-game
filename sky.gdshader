shader_type canvas_item;

uniform sampler2D sky_gradient;
uniform vec2 texture_size;

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    mat2 rot = mat2(vec2(c, -s), vec2(s, c));
    return rot * v;
}

void fragment() {
	vec2 centered_uv = -0.5 + UV;
	vec2 px_pos = centered_uv * texture_size;
	
	float globe_radius = 0.8;
	vec2 globe_center = vec2(0.0, globe_radius);
	float uv_height = length(globe_center - centered_uv) - (globe_radius - 0.5);
	COLOR = texture(sky_gradient, vec2(uv_height, 0.0));
	
	float space_prox = smoothstep(0.4, 0.7, uv_height);
	if (space_prox > 0.0) {
		for (float lattice_idx = 0.0; lattice_idx < 3.0; lattice_idx++) {
			vec2 rotated_px_pos = rotate(px_pos,  lattice_idx * 3.0 / 17.0);
			vec2 cell_size = vec2(
				10000.0 + PI * 500.0 * lattice_idx, 
				8000.0 - PI * 40.0 * lattice_idx
			);
			vec2 local_pos = mod(rotated_px_pos, cell_size);
			vec2 cell_center = 0.5 * cell_size;
			
			float star_prox = smoothstep(80.0, 50.0, length(cell_center - local_pos));
			COLOR.rgb = mix(COLOR.rgb, vec3(1.0), star_prox * space_prox);
		}
	}
}