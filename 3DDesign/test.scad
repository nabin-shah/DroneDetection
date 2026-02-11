// ============================================================
// FINAL FIXED ASSEMBLY: STEPPED ROD FOR FLUSH LID CLOSURE
// ============================================================

$fn = 64;           
wall = 3;           
box_w = 260;        
box_d = 160;        
box_h = 100;        // 10cm height
corner_r = 5;       

// --- SHAFT & BEARING SPECS ---
motor_shaft_dia = (0.19 * 25.4) + 0.2;     
encoder_shaft_dia = (0.23 * 25.4) + 0.2;   

bearing_hole_dia = 9.5;    
bearing_outer_dia = 19;    
bearing_depth = 0.6;       
bearing_real_thick = 1.5;  

rod_outer_r = 8;     
rod_h = 110;         
gear_teeth_h = 90;   // Teeth stop here to allow lid to close

// --- POSITIONING ---
mech_center = [150, 80, wall]; 
mesh_dist = 32.2; 
arduino_pos = [20, 40, wall];  
motor_size = 42.6;  
encoder_rad = 19.3; 

// ============================================================
// EXECUTION
// ============================================================

main_box_final();
translate([0, 0, box_h]) interlocking_lid(); // Lid is now flush
assembly();

// ============================================================
// MAIN ASSEMBLY
// ============================================================
module assembly() {
    translate(arduino_pos) arduino_uno_r3();

    translate(mech_center) {
        // 1. THE STEPPED ROD
        color("LimeGreen") gear_rod_stepped(h=rod_h, th=gear_teeth_h);
        
        // 2. 3D BEARINGS
        translate([0, 0, -bearing_depth]) ball_bearing_3d();
        translate([0, 0, box_h - wall - bearing_depth]) ball_bearing_3d();
        
        // 3. MOTOR & ENCODER (Logic same as before)
        translate([-mesh_dist, 0, 0]) {
            motor_body();
            color("Silver") translate([0, 0, 48 + 5]) 
                big_gear_for_shaft(dia=motor_shaft_dia, is_d=false); 
        }
        translate([mesh_dist, 0, 0]) {
            encoder_body();
            color("Silver") translate([0, 0, 35 + 10]) 
                big_gear_for_shaft(dia=encoder_shaft_dia, is_d=true);  
        }
    }
}

// ============================================================
// FIXED MODULE: STEPPED GEAR ROD
// ============================================================
module gear_rod_stepped(h, th) {
    // Bottom Pin (fits in floor bearing)
    translate([0, 0, -bearing_real_thick + 0.5]) 
        cylinder(h = bearing_real_thick, d = bearing_hole_dia - 0.1);

    // Main Gear Section (Stops before the lid)
    linear_extrude(height = th) gear_profile(12, 8, 6);
    
    // Smooth Upper Shaft (Passes through bearing and lid)
    translate([0, 0, th]) 
        cylinder(h = h - th + 5, d = bearing_hole_dia - 0.1);
}

// ============================================================
// ENCLOSURE: ROUNDED BOX
// ============================================================
module main_box_final() {
    difference() {
        color("Ivory", 0.3) rounded_block(box_w, box_d, box_h, corner_r);
        translate([wall, wall, wall]) 
            rounded_block(box_w - wall*2, box_d - wall*2, box_h + 1, corner_r - 1.5);
        
        translate([mech_center[0], mech_center[1], wall - bearing_depth]) 
            cylinder(h = wall, d = bearing_outer_dia + 0.2);

        translate([-1, arduino_pos[1] + 35, wall + 2]) cube([wall + 2, 16, 12]);
        
        translate([mech_center[0] - mesh_dist, mech_center[1], -1]) 
            for(x=[-15.5, 15.5], y=[-15.5, 15.5]) translate([x, y, 0]) cylinder(h=wall+2, d=3.4);
        translate([mech_center[0] + mesh_dist, mech_center[1], -1]) 
            for(a=[0, 120, 240]) rotate([0, 0, a]) translate([14, 0, 0]) cylinder(h=wall+2, d=3.4);
    }

    // Cradles (Wire Exits point away from rod)
    translate([mech_center[0] - mesh_dist, mech_center[1], wall]) 
        difference() {
            translate([-motor_size/2-2, -motor_size/2-2, 0]) cube([motor_size+4, motor_size+4, 10]);
            translate([-motor_size/2, -motor_size/2, -1]) cube([motor_size, motor_size, 12]);
            translate([-10, motor_size/2-1, 0]) cube([20, 10, 11]);
        }
    translate([mech_center[0] + mesh_dist, mech_center[1], wall]) 
        difference() {
            cylinder(h=10, r=encoder_rad+2);
            translate([0,0,-1]) cylinder(h=12, r=encoder_rad);
            translate([-10, -encoder_rad-9, 0]) cube([20, 10, 11]);
        }
    
    // Arduino Standoffs
    translate([arduino_pos[0], arduino_pos[1], wall]) {
        holes = [[14.0, 2.5], [15.3, 50.8], [66.1, 7.6], [66.1, 35.6]];
        for(h = holes) translate([h[0], h[1], 0]) 
            difference() { cylinder(h=5, r=3); translate([0,0,-1]) cylinder(h=7, r=1.5); }
    }
}

// ============================================================
// ENCLOSURE: INTERLOCKING LID
// ============================================================
module interlocking_lid() {
    color("Ivory", 0.7) union() {
        difference() {
            rounded_block(box_w, box_d, wall, corner_r);
            translate([mech_center[0], mech_center[1], -1])
                cylinder(h=wall+2, d=bearing_hole_dia + 0.5);
            translate([box_w/2, 20, -1]) cylinder(h=wall+2, d=5.1);
        }
        
        // The Rim
        translate([wall + 0.5, wall + 0.5, -wall])
        difference() {
            rounded_block(box_w - wall*2 - 1, box_d - wall*2 - 1, wall, corner_r - 1.5);
            translate([2, 2, -1]) 
                rounded_block(box_w - wall*2 - 5, box_d - wall*2 - 5, wall + 2, corner_r - 2);
            // Clearance for Gear transition
            translate([mech_center[0]-35, mech_center[1]-35, -1]) cube([70, 70, wall+2]);
        }
        
        // Underside Bearing Hub
        translate([mech_center[0], mech_center[1], -bearing_depth])
            difference() {
                cylinder(h=bearing_depth + 1, d=bearing_outer_dia + 4);
                translate([0,0,-0.1]) cylinder(h=bearing_depth + 1.2, d=bearing_outer_dia + 0.2);
            }
    }
}

// ============================================================
// VISUALS & UTILITIES
// ============================================================
module ball_bearing_3d() {
    color("SteelBlue") difference() {
        cylinder(h = bearing_real_thick, d = bearing_outer_dia);
        translate([0, 0, -1]) cylinder(h = bearing_real_thick + 2, d = bearing_hole_dia + 1);
    }
    color("Silver") for(i=[0:45:360]) rotate([0,0,i]) 
        translate([(bearing_outer_dia + bearing_hole_dia)/4, 0, bearing_real_thick/2]) sphere(d=1, $fn=12);
}

module rounded_block(w, d, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, d-r, 0]) cylinder(h=h, r=r);
        translate([r, d-r, 0]) cylinder(h=h, r=r);
    }
}

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
            if(is_d) intersection() {
                    cylinder(h=17, d=dia);
                    translate([-dia/2, -dia/2 + 0.8, 0]) cube([dia, dia, 17]);
                }
            else cylinder(h=17, d=dia);
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
    color("Silver") translate([-6, 35, 1.6]) cube([16, 12, 11]);
}