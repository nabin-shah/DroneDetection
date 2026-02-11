// --- GLOBAL PARAMETERS ---
$fn = 32;
box_w = 160;
box_d = 120;
box_h = 110; // Tall enough to clear the 100mm rod
wall = 3;

// Placement coordinates
arduino_pos = [10, 10];
mech_center = [100, 60];
mesh_dist = 13.5; 

// --- TOGGLE VIEW ---
// Set to 1 for Box, 2 for Lid, 3 for Both (Exploded)
view_mode = 3; 

if (view_mode == 1 || view_mode == 3) main_box();
if (view_mode == 2) lid();
if (view_mode == 3) translate([0, 0, box_h + 20]) lid();

// --- MODULES ---

module main_box() {
    difference() {
        // Outer shell
        cube([box_w, box_d, box_h]);
        
        // Hollow out the inside
        translate([wall, wall, wall])
            cube([box_w - wall*2, box_d - wall*2, box_h]);
            
        // Cutout for Arduino USB/Power
        translate([-1, arduino_pos[1] + 35, wall + 2]) cube([wall+2, 16, 12]);
        translate([-1, arduino_pos[1] + 3, wall + 2]) cube([wall+2, 10, 12]);
    }
    
    // Arduino Mounting Stays (Posts)
    translate([arduino_pos[0], arduino_pos[1], wall]) {
        posts = [[14.0, 2.5], [15.3, 50.8], [66.1, 7.6], [66.1, 35.6]];
        for(p = posts) translate([p[0], p[1], 0]) 
            difference() {
                cylinder(h=5, r=3);
                cylinder(h=6, r=1.4); // M3 screw hole
            }
    }
}
