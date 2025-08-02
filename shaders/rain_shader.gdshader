shader_type canvas_item;

uniform float rain_density : hint_range(50.0, 300.0) = 150.0;
uniform float rain_speed : hint_range(0.5, 3.0) = 1.5;
uniform float drop_length : hint_range(0.05, 0.5) = 0.2;
uniform vec4 rain_color : source_color = vec4(0.8, 0.9, 1.0, 0.7);

float hash(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Make rain fall diagonally
    uv.x += uv.y * 0.2;
    
    // Scale UV for rain density
    uv *= rain_density;
    
    // Get grid cell
    vec2 cell = floor(uv);
    vec2 local_uv = fract(uv);
    
    // Random for this cell
    float rand = hash(cell);
    
    float drop = 0.0;
    
    // Only show rain in some cells
    if (rand > 0.6) {
        // Random start time for this drop
        float start_offset = hash(cell + vec2(1.0, 1.0)) * 2.0;
        
        // Current position of the drop's center
        float drop_center = fract((TIME + start_offset) * rain_speed);
        
        // Distance from current pixel to drop center
        float distance_to_center = abs(local_uv.y - drop_center);
        
        // Only render if we're within the drop length
        if (distance_to_center < drop_length) {
            // Create vertical line shape
            float line = smoothstep(0.6, 0.5, abs(local_uv.x - 0.5));
            
            // Create drop shape with tapered ends
            float drop_shape = 1.0 - (distance_to_center / drop_length);
            
            // Make drop fade at the ends
            drop_shape = smoothstep(0.0, 0.3, drop_shape);
            
            drop = line * drop_shape;
        }
    }
    
    COLOR = vec4(rain_color.rgb, rain_color.a * drop);
}