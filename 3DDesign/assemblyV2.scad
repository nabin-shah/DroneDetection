// ============================================================
// ALL-IN-ONE ASSEMBLY: 10cm BOX + 11cm ROD + FULL MECHANICS
// ============================================================

$fn = 64;           
wall = 3;           
box_w = 260;        
box_d = 160;        
box_h = 100; // Requested 10cm height

// --- GEAR & SHAFT MATH ---
gear_outer_r = 25;   // Large gear to clear bodies
teeth_count = 30;
rod_outer_r = 8;     // Small rod gear
rod_h = 110;         // Rod is 11cm
mesh_dist = 32.2;    // Distance for teeth engagement

motor_shaft_dia = (0.19 * 25.4) + 0.2;   // ~5.03mm
encoder_shaft_dia = (0.23 * 25.4) + 0.2; // ~6.04mm

// Positioning
mech_center = [150, 80, wall]; 
arduino_pos = [20, 40, wall];  
motor_size = 42.6;  
encoder_rad = 19.3; 

// --- RENDER CONTROL ---
show_box = true;
show_lid = false;
show_components = true; // Set to false to see just the box for printing

if (show_box) main_box_final();
if (show_lid) translate([0, 0, box_h + 20]) lid_final();
if (show_components) assembly();

// ============================================================
// MAIN ASSEMBLY: BRINGING COMPONENTS TOGETHER
// ============================================================
module assembly() {
    // 1. ARDUINO UNO
    translate(arduino_pos) arduino_uno_r3();

    // 2. MECHANICAL SYSTEM
    translate(mech_center) {
        // THE CENTRAL ROD (The Pinion)
        color("LimeGreen") gear_rod_module(h=rod_h);
        
        // STEPPER MOTOR (Left Side) - 0.19" CIRCULAR
        translate([-mesh_dist, 0, 0]) {
            motor_body();
            color("Silver") translate([0, 0, 48 + 5]) 
                big_gear_for_shaft(dia=motor_shaft_dia, is_d=false); 
        }
        
        // ENCODER (Right Side) - 0.23" D-CUT
        translate([mesh_dist, 0, 0]) {
            encoder_body();
            color("Silver") translate([0, 0, 35 + 10]) 
                big_gear_for_shaft(dia=encoder_shaft_dia, is_d=true);  
        }
    }
}

// ============================================================
// ENCLOSURE MODULE
// ============================================================
module main_box_final() {
    difference() {
        color("Ivory", 0.3) cube([box_w, box_d, box_h]);
        translate([wall, wall, wall]) cube([box_w - wall*2, box_d - wall*2, box_h + 1]);
        
        // USB port for Arduino
        translate([-1, arduino_pos[1] + 35, wall + 2]) cube([wall + 2, 16, 12]);
        
        // Floor Holes for Motor
        translate([mech_center[0] - mesh_dist, mech_center[1], -1]) 
            for(x=[-15.5, 15.5], y=[-15.5, 15.5]) translate([x, y, 0]) cylinder(h=wall+2, d=3.4);
        
        // Floor Holes for Encoder
        translate([mech_center[0] + mesh_dist, mech_center[1], -1]) 
            for(a=[0, 120, 240]) rotate([0, 0, a]) translate([14, 0, 0]) cylinder(h=wall+2, d=3.4);
    }

    // Motor Cradle (Wire exit pointing Y+)
    translate([mech_center[0] - mesh_dist, mech_center[1], wall]) 
        difference() {
            translate([-motor_size/2 - 2, -motor_size/2 - 2, 0]) cube([motor_size + 4, motor_size + 4, 10]);
            translate([-motor_size/2, -motor_size/2, -1]) cube([motor_size, motor_size, 12]);
            translate([-10, motor_size/2 - 1, 0]) cube([20, 10, 11]);
        }

    // Encoder Cradle (Wire exit pointing Y-)
    translate([mech_center[0] + mesh_dist, mech_center[1], wall]) 
        difference() {
            cylinder(h=10, r=encoder_rad + 2);
            translate([0,0,-1]) cylinder(h=12, r=encoder_rad);
            translate([-10, -encoder_rad - 9, 0]) cube([20, 10, 11]);
        }
    
    // Arduino Standoffs
    translate([arduino_pos[0], arduino_pos[1], wall]) {
        holes = [[14.0, 2.5], [15.3, 50.8], [66.1, 7.6], [66.1, 35.6]];
        for(h = holes) translate([h[0], h[1], 0]) 
            difference() { cylinder(h=5, r=3); translate([0,0,-1]) cylinder(h=7, r=1.5); }
    }
}

module lid_final() {
    color("Ivory", 0.6) difference() {
        cube([box_w, box_d, wall]);
        // Rod Hole with Lead-in Chamfer
        translate([mech_center[0], mech_center[1], -1]) {
            cylinder(h=wall+2, r=rod_outer_r + 0.5);
            translate([0,0,-0.1]) cylinder(h=2.5, r1=rod_outer_r + 4, r2=rod_outer_r + 0.5);
        }
        // LED Hole
        translate([box_w/2, 20, -1]) cylinder(h=wall+2, d=5.1);
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
    linear_extrude(height = h) gear_profile(12, 8, 6);
}

module big_gear_for_shaft(dia, is_d) {
    difference() {
        linear_extrude(height = 15) gear_profile(30, 25, 22);
        translate([0,0,-1]) {
            if(is_d) {
                intersection() {
                    cylinder(h=17, d=dia);
                    translate([-dia/2, -dia/2 + 0.7, 0]) cube([dia, dia, 17]);
                }
            } else { cylinder(h=17, d=dia); }
        }
        // Set-screw hole
        translate([0, 0, 7.5]) rotate([0, 90, 0]) cylinder(h=30, d=3.2);
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
        translate([0,0,35]) cylinder(h=20, d=encoder_shaft_dia);
    }
}

module arduino_uno_r3() {
    color("DarkCyan") cube([68.6, 53.3, 1.6]);
    color("Silver") translate([-6, 35, 1.6]) cube([16, 12, 11]);
}