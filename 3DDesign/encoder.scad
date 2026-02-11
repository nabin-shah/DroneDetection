// --- Encoder Dimensions (BRT38-SOM1024-RT1) ---
body_dia = 38;          // 38mm outer diameter
body_height = 35;       // Standard body depth
boss_dia = 20;          // Raised mounting pilot diameter
boss_height = 5;        // Height of the pilot boss
shaft_dia = 6;          // 6mm solid shaft
shaft_length = 15;      // Typical shaft length
mounting_bolt_circle = 28; // M3 holes spaced on a 28mm circle
$fn = 64;

// --- Render the Encoder ---
color("DimGray") encoder_body();
color("Silver") encoder_shaft();

// --- Modules ---

module encoder_body() {
    difference() {
        union() {
            // Main cylindrical body
            cylinder(h=body_height, r=body_dia/2);
            
            // Mounting Boss (Pilot)
            translate([0, 0, body_height])
                cylinder(h=boss_height, r=boss_dia/2);
        }
        
        // Mounting Holes (usually 3 holes at 120 degrees)
        for(a = [0, 120, 240]) {
            rotate([0, 0, a])
                translate([mounting_bolt_circle/2, 0, body_height - 5])
                    cylinder(h=boss_height + 6, r=1.5); // M3 holes
        }
        
        // Cable Exit Relief (Small cutout on the bottom side)
        translate([body_dia/2 - 5, -5, 0])
            cube([10, 10, 10]);
    }
}

module encoder_shaft() {
    // Shaft extends from the top of the boss
    translate([0, 0, body_height + boss_height])
        cylinder(h=shaft_length, r=shaft_dia/2);
}