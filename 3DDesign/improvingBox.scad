// ============================================================
// FINAL ENCLOSURE: 10cm Height, Cradles, Standoffs, & Lead-in Lid
// ============================================================

$fn = 64;           
wall = 3;           
box_w = 260;        
box_d = 160;        
box_h = 100; // Updated to 10cm as requested

// Positioning (Ensuring the gear rod is central to the gears)
mech_center = [150, 80, wall]; 
mesh_dist = 32.2; 
arduino_pos = [20, 40, wall];  

// Component Sizes for Cradles
motor_size = 42.6;   // NEMA 17 + tolerance
encoder_rad = 19.3;  // BRT38 + tolerance
rod_outer_r = 8;     // Gear rod radius for the lid hole

// --- RENDER CONTROL ---
// Change to true/false to see/hide parts
show_box = true;
show_lid = true;

if (show_box) main_box_final();
if (show_lid) translate([0, 0, box_h + 20]) lid_final();

// ============================================================
// MODULES
// ============================================================

module main_box_final() {
    difference() {
        // 1. The Main Shell
        color("Ivory") cube([box_w, box_d, box_h]);
        
        // 2. Internal Cavity
        translate([wall, wall, wall]) 
            cube([box_w - wall*2, box_d - wall*2, box_h + 1]);
        
        // 3. Arduino USB Cutout
        translate([-1, arduino_pos[1] + 35, wall + 2]) cube([wall + 2, 16, 12]);
        
        // 4. Mounting Holes (M3) through the floor
        // Motor Holes
        translate([mech_center[0] - mesh_dist, mech_center[1], -1]) 
            for(x=[-15.5, 15.5], y=[-15.5, 15.5]) translate([x, y, 0]) cylinder(h=wall+2, d=3.4);
        
        // Encoder Holes
        translate([mech_center[0] + mesh_dist, mech_center[1], -1]) 
            for(a=[0, 120, 240]) rotate([0, 0, a]) translate([14, 0, 0]) cylinder(h=wall+2, d=3.4);
    }

    // --- CRADLE FOR MOTOR (Left) ---
    // Rotated wire exit pointing toward the BACK (Y+)
    translate([mech_center[0] - mesh_dist, mech_center[1], wall]) {
        difference() {
            translate([-motor_size/2 - 2, -motor_size/2 - 2, 0]) cube([motor_size + 4, motor_size + 4, 10]);
            translate([-motor_size/2, -motor_size/2, -1]) cube([motor_size, motor_size, 12]);
            translate([-10, motor_size/2 - 1, 0]) cube([20, 10, 11]);
        }
    }

    // --- CRADLE FOR ENCODER (Right) ---
    // Rotated wire exit pointing toward the FRONT (Y-)
    translate([mech_center[0] + mesh_dist, mech_center[1], wall]) {
        difference() {
            cylinder(h=10, r=encoder_rad + 2);
            translate([0,0,-1]) cylinder(h=12, r=encoder_rad);
            translate([-10, -encoder_rad - 9, 0]) cube([20, 10, 11]);
        }
    }
    
    // --- ARDUINO STANDOFFS ---
    translate([arduino_pos[0], arduino_pos[1], wall]) {
        holes = [[14.0, 2.5], [15.3, 50.8], [66.1, 7.6], [66.1, 35.6]];
        for(h = holes) translate([h[0], h[1], 0]) 
            difference() {
                cylinder(h=5, r=3);
                translate([0,0,-1]) cylinder(h=7, r=1.5); // Hole for mounting screw
            }
    }
}

// module lid_final() {
//     color("Ivory", 0.7) difference() {
//         // Main flat lid
//         cube([box_w, box_d, wall]);
        
//         // 1. ROD HOLE with Lead-in Chamfer
//         translate([mech_center[0], mech_center[1], -1]) {
//             // The actual hole (tight fit)
//             cylinder(h=wall+2, r=rod_outer_r + 0.5);
            
//             // The Chamfer/Taper on the bottom side to guide the rod in
//             translate([0,0,-0.1])
//                 cylinder(h=2.5, r1=rod_outer_r + 4, r2=rod_outer_r + 0.5);
//         }
        
//         // 2. LED Hole (5mm)
//         translate([box_w/2, 20, -1]) cylinder(h=wall+2, d=5.1);
        
//         // 3. Optional: Screw holes in corners of lid (M3)
//         for(x=[8, box_w-8], y=[8, box_d-8])
//             translate([x, y, -1]) cylinder(h=wall+2, d=3.2);
//     }
// }