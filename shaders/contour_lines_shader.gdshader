shader_type canvas_item;

uniform int subdivisions = 0;
uniform float main_thickness = 0.005;      // Height-space thickness
uniform float minor_thickness = 0.002;
uniform vec4 main_color : source_color = vec4(0.0);
uniform vec4 minor_color : source_color = vec4(0.0);
uniform float step = 0.125;                // 1.0 / bands

void fragment() {
    float height = texture(TEXTURE, UV).r;

    // Total divisions (main + minor lines)
    int total_divisions = subdivisions + 1;
    float spacing = step / float(total_divisions);

    // Get position relative to the nearest contour (main or minor)
    float band = fract(height / spacing);
    float dist = min(band, 1.0 - band);

    // Check if this is a main contour line
    bool is_major = abs(mod(height, step)) < (main_thickness * 0.5);

    // Decide which thickness and color to use
    float thickness = is_major ? main_thickness : minor_thickness;
    vec4 color = is_major ? main_color : minor_color;

    // Show only pixels near the line center
    if (dist > thickness * 0.5) {
        discard;
    }

    COLOR = color;
}