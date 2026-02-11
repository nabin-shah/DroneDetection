// ============================================================
// FINAL CORRECTED ASSEMBLY: INCH-BASED SHAFTS & CUSTOM CUTS
// ============================================================

$fn = 64;           
wall = 3;           
box_w = 260;        
box_d = 160;        
box_h = 130;        

// --- GEAR CONFIGURATION ---
gear_outer_r = 25; 
gear_inner_r = 22;
teeth_count = 30;

// Central Rod (The "Sun" Gear)
rod_outer_r = 8;
rod_inner_r = 6;
rod_teeth = 12;

// Mesh Distance (Center of Rod to Center of Motor/Encoder)
mesh_dist = 32.2; 

// --- SHAFT CONVERSIONS (Inches to mm + Tolerance) ---
motor_shaft_dia = (0.19 * 25.4) + 0.2;   // ~5.03mm
encoder_shaft_dia = (0.23 * 25.4) + 0.2; // ~6.04mm

// Positioning
mech_center = [150, 80, wall]; 
arduino_pos = [20, 40, wall];  

// ============================================================
// EXECUTION
// ============================================================

main_box();
assembly();
translate([0, 0, box_h + 10]) lid(); 

// ============================================================
// MAIN ASSEMBLY MODULE
// ============================================================
module assembly() {
    // 1. ARDUINO UNO
    translate(arduino_pos) arduino_uno_r3();

    // 2. MECHANICAL SYSTEM
    translate(mech_center) {
        // THE CENTRAL ROD (Pinion)
        color("LimeGreen") gear_rod_module(h=110);
        
        // STEPPER MOTOR (Left Side) - 0.19" CIRCULAR SHAFT
        translate([-mesh_dist, 0, 0]) {
            motor_body();
            color("Silver") translate([0, 0, 48 + 5]) 
                big_gear_for_shaft(dia=motor_shaft_dia, is_d=false); 
        }
        
        // ENCODER (Right Side) - 0.23" D-CUT SHAFT
        translate([mesh_dist, 0, 0]) {
            encoder_body();
            color("Silver") translate([0, 0, 35 + 10]) 
                big_gear_for_shaft(dia=encoder_shaft_dia, is_d=true);  
        }
    }
}

// ============================================================
// COMPONENT MODULES
// ============================================================

module gear_profile(teeth, r_out, r_in, flat=0.6) {
    angle_step = 360 / teeth;
    points = [for (i = [0 : teeth - 1]) each [
        [r_in * cos(i * angle_step - angle_step * flat/4), r_in * sin(i * angle_step - angle_step * flat/4)],
        [r_out * cos(i * angle_step - angle_step * flat/8), r_out * sin(i * angle_step - angle_step * flat/8)],
        [r_out * cos(i * angle_step + angle_step * flat/8), r_out * sin(i * angle_step + angle_step * flat/8)],
        [r_in * cos(i * angle_step + angle_step * flat/4), r_in * sin(i * angle_step + angle_step * flat/4)]
    ]];
    polygon(points);
}

module gear_rod_module(h) {
    linear_extrude(height = h) gear_profile(rod_teeth, rod_outer_r, rod_inner_r);
}

module big_gear_for_shaft(dia, is_d) {
    difference() {
        // Gear Body
        linear_extrude(height = 15) gear_profile(teeth_count, gear_outer_r, gear_inner_r);
        
        // Bore hole
        translate([0,0,-1]) {
            if(is_d) {
                // Encoder D-cut (removes 0.5mm from radius)
                intersection() {
                    cylinder(h=17, d=dia);
                    translate([-dia/2, -dia/2 + 0.7, 0]) cube([dia, dia, 17]);
                }
            } else {
                // Motor Circular hole
                cylinder(h=17, d=dia);
            }
        }
        // Set-screw hole for the Motor side (Mandatory for circular shafts)
        translate([0, 0, 7.5]) rotate([0, 90, 0]) cylinder(h=gear_outer_r+1, d=3.2);
    }
}

module motor_body() {
    color("SlateGray") {
        translate([-21.15, -21.15, 0]) cube([42.3, 42.3, 48]);
        translate([0,0,48]) cylinder(h=24, d=motor_shaft_dia); 
    }
}

module encoder_body() {
    color("DimGray") {
        cylinder(h=35, r=19); 
        // D-cut Shaft visualization for Encoder
        translate([0,0,35]) intersection() {
            cylinder(h=20, d=encoder_shaft_dia);
            translate([-5, -5 + 0.7, 0]) cube([10, 10, 20]);
        }
    }
}

module arduino_uno_r3() {
    color("DarkCyan") cube([68.6, 53.3, 1.6]);
    color("Silver") translate([-6, 35, 1.6]) cube([16, 12, 11]);
}

// ============================================================
// ENCLOSURE
// ============================================================

// module main_box() {
//     difference() {
//         color("Ivory", 0.3) cube([box_w, box_d, box_h]);
//         translate([wall, wall, wall]) cube([box_w-wall*2, box_d-wall*2, box_h]);
        
//         // Motor Mount Holes (Standard NEMA 17)
//         translate([mech_center[0] - mesh_dist, mech_center[1], 0]) 
//             for(x=[-15.5, 15.5], y=[-15.5, 15.5]) translate([x, y, -1]) cylinder(h=wall+2, d=3.4);
        
//         // Encoder Mount Holes (BRT38 Circular Pattern)
//         translate([mech_center[0] + mesh_dist, mech_center[1], 0]) 
//             for(a=[0, 120, 240]) rotate([0, 0, a]) translate([14, 0, -1]) cylinder(h=wall+2, d=3.4);
        
//         // Arduino Mounting Holes
//         translate([arduino_pos[0], arduino_pos[1], 0]) {
//             holes = [[14.0, 2.5], [15.3, 50.8], [66.1, 7.6], [66.1, 35.6]];
//             for(h = holes) translate([h[0], h[1], -1]) cylinder(h=wall+2, d=3.2);
//         }
        
//         // Arduino Port Cutout
//         translate([-1, arduino_pos[1]+35, wall+2]) cube([wall+2, 16, 12]);
//     }
// }

// module lid() {
//     color("Ivory", 0.6) difference() {
//         cube([box_w, box_d, wall]);
//         translate([box_w/2, 20, -1]) cylinder(h=wall+2, d=5.1); // LED
//         translate([mech_center[0], mech_center[1], -1]) cylinder(h=wall+2, r=rod_outer_r + 0.5); // Rod Stabilizer
//     }
// }