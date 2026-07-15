shader_type canvas_item;

uniform float countdown = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float height = 1.0 - UV.x;
	if (height <= 1.0 - countdown) {
		COLOR.a = 0.0;
	}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
