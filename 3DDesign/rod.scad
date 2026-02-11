// --- Parameters ---
rod_height = 100;      // How tall the rod is
number_of_teeth = 10;  // Fewer teeth = smaller diameter
outer_radius = 5;      // Distance from center to tooth tip
inner_radius = 3.5;    // Distance from center to tooth valley
tooth_width = 0.6;     // Sharpness of the teeth (0.1 to 1.0)

// --- The Logic ---
linear_extrude(height = rod_height, convexity = 10) {
    gear_profile(number_of_teeth, outer_radius, inner_radius, tooth_width);
}

// Module to create the 2D gear shape
module gear_profile(teeth, r_out, r_in, flat) {
    angle_step = 360 / teeth;
    
    points = [
        for (i = [0 : teeth - 1]) 
            each [
                // Inner point (start of tooth)
                [r_in * cos(i * angle_step - angle_step * flat/4), 
                 r_in * sin(i * angle_step - angle_step * flat/4)],
                
                // Outer point 1 (tip start)
                [r_out * cos(i * angle_step - angle_step * flat/8), 
                 r_out * sin(i * angle_step - angle_step * flat/8)],
                
                // Outer point 2 (tip end)
                [r_out * cos(i * angle_step + angle_step * flat/8), 
                 r_out * sin(i * angle_step + angle_step * flat/8)],
                
                // Inner point (end of tooth)
                [r_in * cos(i * angle_step + angle_step * flat/4), 
                 r_in * sin(i * angle_step + angle_step * flat/4)]
            ]
    ];
    
    polygon(points);
}