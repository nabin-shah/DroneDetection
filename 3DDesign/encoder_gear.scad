// --- Gear Specs ---
gear_height = 15;        // Height of the gear
number_of_teeth = 14;    
outer_radius = 9;        
inner_radius = 7;        
$fn = 64;

// --- Encoder Shaft Fit (BRT38 Specs) ---
shaft_dia = 6.2;         // 6mm shaft + 0.2mm tolerance for 3D printing
set_screw_dia = 3.2;     // For an M3 screw
hub_diameter = 14;       // Extra thickness to hold the set screw

// --- Final Assembly ---
difference() {
    union() {
        // 1. The Gear Teeth
        linear_extrude(height = gear_height) {
            gear_profile(number_of_teeth, outer_radius, inner_radius, 0.6);
        }
        
        // 2. The Reinforced Hub (Internal collar for the screw)
        cylinder(h = gear_height, d = hub_diameter);
    }

    // 3. Subtract the 6mm Round Shaft Hole
    translate([0, 0, -1]) 
        cylinder(h = gear_height + 2, d = shaft_dia);

    // 4. Subtract the Set-Screw Hole
    // Positioned in the middle of the gear height
    translate([0, 0, gear_height / 2])
        rotate([0, 90, 0])
            cylinder(h = outer_radius + 5, d = set_screw_dia);
}

// --- Gear Profile Module ---
module gear_profile(teeth, r_out, r_in, flat) {
    angle_step = 360 / teeth;
    points = [
        for (i = [0 : teeth - 1]) 
            each [
                [r_in * cos(i * angle_step - angle_step * flat/4), r_in * sin(i * angle_step - angle_step * flat/4)],
                [r_out * cos(i * angle_step - angle_step * flat/8), r_out * sin(i * angle_step - angle_step * flat/8)],
                [r_out * cos(i * angle_step + angle_step * flat/8), r_out * sin(i * angle_step + angle_step * flat/8)],
                [r_in * cos(i * angle_step + angle_step * flat/4), r_in * sin(i * angle_step + angle_step * flat/4)]
            ]
    ];
    polygon(points);
}