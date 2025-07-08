shader_type canvas_item;

// === UNIFORMS ===
uniform int bands = 10;          // Number of bands
uniform float gray_min = 0.5;    // Minimum gray level (darkest)
uniform float gray_max = 0.8;    // Maximum gray level (lightest)

void fragment() {
    float height = texture(TEXTURE, UV).r;
    height = clamp(height, 0.0, 1.0);

    // Determine band index
    int index = int(floor(height * float(bands)));
    index = clamp(index, 0, bands - 1);

    // Map index to grayscale value in range [gray_min, gray_max]
    float t = float(index) / float(bands - 1);
    float level = mix(gray_min, gray_max, 1.0 - t); // 1.0 - t = high = light

    COLOR = vec4(vec3(level), 1.0);
}