// --- Motor Dimensions (NEMA 17 / 42BYGHW811) ---
body_width = 42.3;      // Square body width
body_height = 48;       // Height of the "811" model body
boss_radius = 22 / 2;   // The circular raised part on top
boss_height = 2;        // Height of the boss
shaft_radius = 5 / 2;   // 5mm diameter shaft
shaft_length = 24;      // Length of the shaft from the motor face
hole_spacing = 31;      // Distance between mounting holes
hole_depth = 4.5;       // Depth of M3 holes
$fn = 64;               // Smoothness of circles

// --- Render the Motor ---
color("SlateGray") motor_body();
color("Silver") motor_shaft();

// --- Modules ---

module motor_body() {
    difference() {
        // Main block with rounded corners
        hull() {
            for(x=[-1,1], y=[-1,1])
                translate([x*(body_width/2 - 2), y*(body_width/2 - 2), 0])
                    cylinder(h=body_height, r=2);
        }
        
        // Mounting Holes (M3)
        for(x=[-1,1], y=[-1,1])
            translate([x*hole_spacing/2, y*hole_spacing/2, body_height - hole_depth])
                cylinder(h=hole_depth + 1, r=1.5);
    }
    
    // Top Boss (circular alignment ridge)
    translate([0, 0, body_height])
        cylinder(h=boss_height, r=boss_radius);
}

module motor_shaft() {
    translate([0, 0, body_height])
        difference() {
            // Main shaft
            cylinder(h=shaft_length, r=shaft_radius);
            
            // D-cut (The flat side)
            // The 811 usually has a flat side for set screws
            translate([shaft_radius - 0.5, -shaft_radius, boss_height + 5])
                cube([1, shaft_radius*2, shaft_length]);
        }
}

