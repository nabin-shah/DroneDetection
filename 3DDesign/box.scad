// FILE: Chassis_3D_Print.scad
// This file is ready for STL export. 
// It integrates all mechanical supports into the floor of the box.

$fn = 64;           
wall = 3;           
box_w = 280;        
box_d = 160;        
box_h = 100;        
corner_r = 5;       

// --- SHAFT & MESH SPECS ---
mesh_dist = 37.3; 
mech_center = [180, 80, wall];      
arduino_pos = [wall, 40, wall];     
motor_size = 42.3;                 
encoder_rad = 19;                   
bearing_outer_dia = 19;    
bearing_depth = 5.2;

// ============================================================
// THE SOLID CHASSIS (PRINT THIS)
// ============================================================

union() {
    // 1. THE MAIN OUTER SHELL (Walls and Floor)
    difference() {
        color("Ivory") rounded_block(box_w, box_d, box_h, corner_r);
        
        // Hollow out the inside
        translate([wall, wall, wall]) 
            rounded_block(box_w - wall*2, box_d - wall*2, box_h + 1, corner_r - 1.5);
        
        // USB Port Cutout (Left Wall)
        translate([-1, arduino_pos[1] + 32, wall + 2.5]) cube([wall + 2, 12, 11]);
        
        // DC Power Jack Cutout (Left Wall)
        translate([-1, arduino_pos[1] + 3, wall + 2.5]) cube([wall + 2, 9.5, 11]);
        
        // Mounting Holes for Motor (NEMA 17)
        translate([mech_center[0] - mesh_dist, mech_center[1], -1]) 
            for(x=[-15.5, 15.5], y=[-15.5, 15.5]) translate([x, y, 0]) cylinder(h=wall+2, d=3.4);
        
        // Mounting Holes for Encoder (BRT38)
        translate([mech_center[0] + mesh_dist, mech_center[1], -1]) 
            for(a=[0, 120, 240]) rotate([0, 0, a]) translate([14, 0, 0]) cylinder(h=wall+2, d=3.4);
    }

    // 2. THE BEARING PODIUM (Center)
    // This is the raised hub that holds your floor ball bearing
    translate([mech_center[0], mech_center[1], wall])
        difference() {
            cylinder(h=bearing_depth, d=bearing_outer_dia + 6);
            // The pocket for the bearing (9.1mm radius for a snug 19mm press-fit)
            translate([0,0,-0.1]) cylinder(h=bearing_depth + 0.2, d=19.1);
            // The hole through the floor for the rod pin
            translate([0,0,-wall-1]) cylinder(h=wall+5, d=10.5);
        }

    // 3. THE MOTOR CRADLE (Left side of Rod)
    translate([mech_center[0] - mesh_dist, mech_center[1], wall]) 
        difference() {
            // The outer retaining wall
            translate([-23.15, -23.15, 0]) cube([46.3, 46.3, 10]);
            // The hollow space for the motor body
            translate([-21.15, -21.15, -1]) cube([42.3, 42.3, 12]);
            // Wire Exit Cutout (pointing away from gears)
            translate([-10, 21, 0]) cube([20, 10, 11]); 
        }

    // 4. THE ENCODER CRADLE (Right side of Rod)
    translate([mech_center[0] + mesh_dist, mech_center[1], wall]) 
        difference() {
            // The outer retaining wall (circular)
            cylinder(h=10, r=21);
            // The hollow space for the encoder body
            translate([0,0,-1]) cylinder(h=12, r=19);
            // Wire Exit Cutout (pointing away from gears)
            translate([-10, -28, 0]) cube([20, 10, 11]); 
        }
    
    // 5. ARDUINO STANDOFFS (Left Corner)
    translate([arduino_pos[0], arduino_pos[1], wall]) {
        // Standard Arduino Uno hole positions
        holes = [[14.0, 2.5], [15.3, 50.8], [66.1, 7.6], [66.1, 35.6]];
        for(h = holes) translate([h[0], h[1], 0]) 
            difference() {
                cylinder(h=5, r=3);               // The post
                translate([0,0,-1]) cylinder(h=7, r=1.5); // M3 screw path
            }
    }
}

// ============================================================
// UTILITIES (Required for the block shape)
// ============================================================
module rounded_block(w, d, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, d-r, 0]) cylinder(h=h, r=r);
        translate([r, d-r, 0]) cylinder(h=h, r=r);
    }
}