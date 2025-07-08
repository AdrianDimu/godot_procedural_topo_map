shader_type canvas_item;

// === UNIFORMS ===
uniform int bands = 10;          // Number of bands
uniform float gray_min = 0.5;    // Minimum gray level (darkest)
uniform float gray_max = 0.8;    // Maximum gray level (lightest)

void fragment() {
	// Sample the height value (only red channel is used)
	float height = texture(TEXTURE, UV).r;
	height = clamp(height, 0.0, 1.0);

	// Convert height into a band index
	int index = int(floor(height * float(bands)));
	index = clamp(index, 0, bands - 1);

	// Normalize index to [0.0, 1.0] for interpolation
	float t = float(index) / float(bands - 1);

	// Interpolate from gray_max (light) to gray_min (dark)
	float level = mix(gray_min, gray_max, 1.0 - t);

    COLOR = vec4(vec3(level), 1.0); // Output final grayscale color
}