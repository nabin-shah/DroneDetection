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
view_mode = 2; 

if (view_mode == 1 || view_mode == 3) main_box();
if (view_mode == 2) lid();
if (view_mode == 3) translate([0, 0, box_h + 20]) lid();


module lid() {
    difference() {
        union() {
            // Main flat lid
            cube([box_w, box_d, wall]);
            // Lip to keep it from sliding
            translate([wall+0.5, wall+0.5, -wall])
                difference() {
                    cube([box_w-wall*2-1, box_d-wall*2-1, wall]);
                    translate([wall, wall, -1]) 
                        cube([box_w-wall*4-1, box_d-wall*4-1, wall+2]);
                }
        }
        
        // 1. LED HOLE (Top Center)
        translate([box_w/2, 20, -1]) 
            cylinder(h=wall+2, r=2.55); // 5.1mm hole for 5mm LED
            
        // 2. GEAR ROD TOP SUPPORT HOLE
        // This acts as a "bushing" to keep the rod vertical
        translate([mech_center[0], mech_center[1], -1])
            cylinder(h=wall+2, r=8.5); // Slightly larger than gear radius
    }
}