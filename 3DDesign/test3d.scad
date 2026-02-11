// ============================================================
// FINAL REFINED ASSEMBLY: DUAL BEARING SUPPORT (TOP & BOTTOM)
// ============================================================

$fn = 64;           
wall = 3;           
box_w = 260;        
box_d = 160;        
box_h = 100; 

// --- BEARING SPECS (Updated for 0.6mm depth) ---
bearing_hole_dia = 9.5;    
bearing_outer_dia = 19;    
bearing_depth = 0.6;       // As requested: 0.6mm deep pocket

rod_outer_r = 8;     
rod_h = 110;         

// --- GEAR & MESH MATH ---
gear_outer_r = 25; 
teeth_count = 30;
mesh_dist = 32.2; 

motor_shaft_dia = (0.19 * 25.4) + 0.2;   
encoder_shaft_dia = (0.23 * 25.4) + 0.2; 

// Positioning
mech_center = [150, 80, wall]; 
arduino_pos = [20, 40, wall];  
motor_size = 42.6;  
encoder_rad = 19.3; 

// --- RENDER ---
main_box_with_bearing();
assembly();
translate([0, 0, box_h + 10]) lid_with_bearing();

// ============================================================
// MAIN ASSEMBLY
// ============================================================
module assembly() {
    translate(arduino_pos) arduino_uno_r3();

    translate(mech_center) {
        // THE ROD with Bearing Pins (Top and Bottom)
        color("LimeGreen") gear_rod_with_bearings(h=rod_h);
        
        // MOTOR (Circular Shaft)
        translate([-mesh_dist, 0, 0]) {
            motor_body();
            color("Silver") translate([0, 0, 48 + 5]) 
                big_gear_for_shaft(dia=motor_shaft_dia, is_d=false); 
        }
        
        // ENCODER (D-Cut Shaft)
        translate([mesh_dist, 0, 0]) {
            encoder_body();
            color("Silver") translate([0, 0, 35 + 10]) 
                big_gear_for_shaft(dia=encoder_shaft_dia, is_d=true);  
        }
    }
}

// ============================================================
// ROD WITH DUAL BEARING PINS
// ============================================================
module gear_rod_with_bearings(h) {
    // 1. The main gear body
    linear_extrude(height = h) gear_profile(12, 8, 6);
    
    // 2. BOTTOM PIN (Fits into floor bearing)
    translate([0, 0, -bearing_depth]) 
        cylinder(h = bearing_depth + 0.1, d = bearing_hole_dia - 0.1);

    // 3. TOP PIN (Fits into lid bearing)
    translate([0, 0, h - 0.1]) 
        cylinder(h = bearing_depth + 4, d = bearing_hole_dia - 0.1);
}

// ============================================================
// BOX WITH BOTTOM BEARING POCKET
// ============================================================
module main_box_with_bearing() {
    difference() {
        color("Ivory", 0.3) cube([box_w, box_d, box_h]);
        translate([wall, wall, wall]) cube([box_w - wall*2, box_d - wall*2, box_h + 1]);
        
        // BOTTOM BEARING POCKET
        translate([mech_center[0], mech_center[1], wall - bearing_depth]) 
            cylinder(h = bearing_depth + 0.1, d = bearing_outer_dia + 0.2);

        // Mounting holes and ports
        translate([-1, arduino_pos[1] + 35, wall + 2]) cube([wall + 2, 16, 12]);
        translate([mech_center[0] - mesh_dist, mech_center[1], -1]) 
            for(x=[-15.5, 15.5], y=[-15.5, 15.5]) translate([x, y, 0]) cylinder(h=wall+2, d=3.4);
        translate([mech_center[0] + mesh_dist, mech_center[1], -1]) 
            for(a=[0, 120, 240]) rotate([0, 0, a]) translate([14, 0, 0]) cylinder(h=wall+2, d=3.4);
    }

    // Cradles
    translate([mech_center[0] - mesh_dist, mech_center[1], wall]) 
        difference() {
            translate([-motor_size/2 - 2, -motor_size/2 - 2, 0]) cube([motor_size + 4, motor_size + 4, 10]);
            translate([-motor_size/2, -motor_size/2, -1]) cube([motor_size, motor_size, 12]);
            translate([-10, motor_size/2 - 1, 0]) cube([20, 10, 11]);
        }
    translate([mech_center[0] + mesh_dist, mech_center[1], wall]) 
        difference() {
            cylinder(h=10, r=encoder_rad + 2);
            translate([0,0,-1]) cylinder(h=12, r=encoder_rad);
            translate([-10, -encoder_rad - 9, 0]) cube([20, 10, 11]);
        }
}

// ============================================================
// LID WITH TOP BEARING POCKET
// ============================================================
module lid_with_bearing() {
    color("Ivory", 0.6) difference() {
        cube([box_w, box_d, wall]);
        
        // TOP BEARING POCKET (On the underside of the lid)
        translate([mech_center[0], mech_center[1], -0.1]) 
            cylinder(h = bearing_depth + 0.1, d = bearing_outer_dia + 0.2);
        
        // Hole for the top of the rod to pass through
        translate([mech_center[0], mech_center[1], -1])
            cylinder(h=wall+2, d=bearing_hole_dia + 0.5);

        // LED Hole
        translate([box_w/2, 20, -1]) cylinder(h=wall+2, d=5.1);
    }
}

// ============================================================
// SHARED MODULES (Gears, Bodies, Arduino)
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

module big_gear_for_shaft(dia, is_d) {
    difference() {
        linear_extrude(height = 15) gear_profile(30, 25, 22);
        translate([0,0,-1]) {
            if(is_d) {
                intersection() {
                    cylinder(h=17, d=dia);
                    translate([-dia/2, -dia/2 + 0.8, 0]) cube([dia, dia, 17]);
                }
            } else { cylinder(h=17, d=dia); }
        }
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
}