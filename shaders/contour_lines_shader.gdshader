shader_type canvas_item;

// === UNIFORMS ===
uniform int subdivisions = 0;							// Minor lines between main lines
uniform float main_thickness = 0.005;					// Thickness of main contour lines (in height space)
uniform float minor_thickness = 0.002;					// Thickness of minor lines
uniform vec4 main_color : source_color = vec4(0);		// Color for main contours
uniform vec4 minor_color : source_color = vec4(0);		// Color for minor contours
uniform float step = 0.125;								// Distance between main contour lines (e.g. 1.0 / bands)

void fragment() {
    float height = texture(TEXTURE, UV).r;

    // Compute spacing between *all* lines (main + minor)
    int total_divisions = subdivisions + 1;
    float spacing = step / float(total_divisions);

    // Compute normalized position within one spacing unit
    float band = fract(height / spacing);
    float dist = min(band, 1.0 - band);  // Distance to nearest line center

    // Detect whether this is a main contour
    bool is_major = abs(mod(height, step)) < (main_thickness * 0.5);

    // Set thickness and color accordingly
    float thickness = is_major ? main_thickness : minor_thickness;
    vec4 color = is_major ? main_color : minor_color;

    // Only render pixels close to the line center
    if (dist > thickness * 0.5) {
        discard;
    }

    COLOR = color;
}