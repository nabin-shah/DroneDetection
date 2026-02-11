// ============================================================
// VERSION 8.3: FIXED SOCKET POSITION - LOWERED ARMS ONLY
// ============================================================

$fn = 64;           
wall = 3;           
box_w = 280;       
box_d = 160;       
box_h = 100;       
corner_r = 5;      
mm = 25.4;

// --- DASHBOARD ---
lid_closed            = true; 
show_box              = true;
show_lid              = false;
show_arduino          = true;
show_motor            = true;
show_encoder          = true;
show_rod              = true;
show_bearings         = true;
show_antenna_assembly = true; 

// --- NEW ARM ADJUSTMENT ---
// Increase this to slide the arms closer to the mast base (the lid)
arm_slide_down = 45; 

// --- SPECS ---
mesh_dist      = 37.3;
mech_center    = [180, 80, wall];     
rod_h          = 110; 
mast_h         = 10.5 * mm;
hole_spacing   = 4.56 * mm;
reach          = 65;
rod_dia        = 9.5;

// ============================================================
// EXECUTION
// ============================================================

if (show_box) main_box_final();

lid_z_pos = lid_closed ? box_h : box_h + 25;
if (show_lid) translate([0, 0, lid_z_pos]) interlocking_lid(); 

assembly();

// ============================================================
// ASSEMBLY LOGIC
// ============================================================

module assembly() {
    if (show_arduino) translate([wall, 40, wall]) arduino_uno_r3();

    translate(mech_center) {
        if (show_rod) {
            // Gear rod sitting in the floor bearing
            translate([0, 0, 5.2 - 0.5]) {
                color("LimeGreen") gear_rod_stepped(h=rod_h, th=80);
                
                if (show_antenna_assembly) {
                    // THE SOCKET stays at the very top of the rod (110mm)
                    translate([0, 0, rod_h]) {
                        reinforced_mast_sliding_arms();
                        
                        // THE ANTENNA moves down to match the new lowered arm positions
                        translate([0, reach, mast_h - (hole_spacing/2) - arm_slide_down]) 
                        rotate([90, 0, 90]) 
                        translate([-12, 0, 0]) 
                        final_antenna_standalone();
                    }
                }
            }
        }
        
        if (show_bearings) {
            translate([0, 0, 5.2 - 5]) ball_bearing_3d(); 
            translate([0, 0, lid_z_pos - wall - 5.2 + 0.2]) ball_bearing_3d();
        }
        
        if (show_motor) translate([-mesh_dist, 0, 0]) {
            motor_body();
            color("Silver") translate([0, 0, 48 + 10]) 
                big_gear_for_shaft(dia=4.826 + 0.2, is_d=false); 
        }
        
        if (show_encoder) translate([mesh_dist, 0, 0]) {
            encoder_body();
            color("Silver") translate([0, 0, 35 + 15]) 
                big_gear_for_shaft(dia=5.842 + 0.2, is_d=true);  
        }
    }
}

// ============================================================
// MAST MODULE: SLIDING THE ARMS INDEPENDENTLY
// ============================================================
module reinforced_mast_sliding_arms() {
    socket_depth  = 30;  
    main_rod_dia  = 20;
    arm_height    = 30;
    arm_width     = 10;
    gusset_thick  = 6;

    union() {
        // 1. Socket Base (D-cut stays fixed to engage the rod)
        difference() {
            color("Gold") cylinder(h = socket_depth + 15, d = 26);
            translate([0, 0, -1]) intersection() {
                cylinder(h = socket_depth + 1, d = 9.8);
                translate([-15, -10 + (9.5/2 - 1.5), 0]) cube([30, 20, socket_depth + 1]);
            }
        }
        // 2. Main Mast
        color("Gold") translate([0, 0, socket_depth + 15])
            cylinder(h = mast_h - (socket_depth + 15), d = main_rod_dia);
        
        // 3. Sliding Reinforced Arms
        // We subtract arm_slide_down from z_pos to move the "bracket" down the shaft
        for (z_pos = [mast_h - hole_spacing - arm_slide_down, mast_h - arm_slide_down]) {
            translate([0, 0, z_pos - arm_height/2]) {
                color("Gold") difference() {
                    translate([-arm_width/2, 0, 0]) cube([arm_width, reach + 10, arm_height]);
                    translate([-10, reach, arm_height/2]) rotate([0, 90, 0]) cylinder(h=20, d=0.15*mm);
                }
                
                // Mirrored Red Gusset - Moves with the arm
                color("Red") 
                translate([-gusset_thick/2, 1, 0]) 
                rotate([90, 0, 90]) 
                linear_extrude(gusset_thick) 
                polygon([[0, 0], [0, -35], [reach - 5, 0]]);
            }
        }
    }
}

// ============================================================
// FINAL PCB ANTENNA MODULE
// ============================================================
module final_antenna_standalone() {
    widest_len = 8.92 * mm; 
    hole_dist  = 4.56 * mm;
    pcb_thick  = 1.6; 
    antenna_span = widest_len * 1.45; 

    union() {
        difference() {
            color("DarkGreen") hull() {
                translate([0, -(widest_len/2 + 7), 0]) cube([5, widest_len + 14, pcb_thick]);
                translate([antenna_span + 25, -10, 0]) cube([5, 20, pcb_thick]);
            }
            translate([12, hole_dist/2, -1])  cylinder(h=10, d=0.15*mm);
            translate([12, -hole_dist/2, -1]) cylinder(h=10, d=0.15*mm);
        }
        color("Silver") translate([0, -2.5, pcb_thick]) cube([antenna_span + 20, 5, 5]);
    }
}

// ============================================================
// CORE SYSTEM MODULES
// ============================================================
module gear_rod_stepped(h, th) {
    d_cut_h = 15;
    translate([0, 0, -4.5]) cylinder(h = 5, d = rod_dia - 0.1);
    linear_extrude(height = th) gear_profile(12, 8, 6);
    translate([0, 0, th]) difference() {
        cylinder(h = h - th + 5, d = rod_dia - 0.1);
        translate([rod_dia/2 - 1.5, -5, h - th - d_cut_h + 5]) cube([5, 10, d_cut_h + 1]);
    }
}

module main_box_final() {
    difference() {
        color("Red", 0.3) rounded_block(box_w, box_d, box_h, corner_r);
        translate([wall, wall, wall]) rounded_block(box_w - wall*2, box_d - wall*2, box_h + 1, corner_r - 1.5);
        // Port cutouts
        translate([-1, 72, wall + 2.5]) cube([wall + 2, 12, 11]);
        translate([-1, 43, wall + 2.5]) cube([wall + 2, 9.5, 11]);
    }
    // Floor Hub
    translate([mech_center[0], mech_center[1], wall]) difference() {
        cylinder(h=5.2, d=25);
        translate([0,0,-0.1]) cylinder(h=5.4, d=19.1);
        translate([0,0,-wall]) cylinder(h=wall+2, d=10.5);
    }
    // Motor Cradle
    translate([mech_center[0] - mesh_dist, mech_center[1], wall]) difference() {
        translate([-23.15, -23.15, 0]) cube([46.3, 46.3, 10]);
        translate([-21.15, -21.15, -1]) cube([42.3, 42.3, 12]);
    }
    // Encoder Cradle
    translate([mech_center[0] + mesh_dist, mech_center[1], wall]) difference() {
        cylinder(h=10, r=21);
        translate([0,0,-1]) cylinder(h=12, r=19);
    }
}

module interlocking_lid() {
    color("Ivory", 0.7) union() {
        difference() {
            rounded_block(box_w, box_d, wall, corner_r);
            translate([mech_center[0], mech_center[1], -1]) cylinder(h=wall+2, d=10);
        }
        translate([mech_center[0], mech_center[1], -5.2]) difference() {
            cylinder(h=5.2, d=25);
            translate([0,0,-0.1]) cylinder(h=5.4, d=19.1);
        }
    }
}

// --- UTILITIES ---
module rounded_block(w, d, h, r) { hull() { translate([r, r, 0]) cylinder(h=h, r=r); translate([w-r, r, 0]) cylinder(h=h, r=r); translate([w-r, d-r, 0]) cylinder(h=h, r=r); translate([r, d-r, 0]) cylinder(h=h, r=r); } }
module ball_bearing_3d() { color("SteelBlue") difference() { cylinder(h = 5, d = 19); translate([0, 0, -1]) cylinder(h = 7, d = 11.5); } color("Silver") for(i=[0:45:360]) rotate([0,0,i]) translate([7.5, 0, 2.5]) sphere(d=1, $fn=12); }
module gear_profile(teeth, r_out, r_in, flat=0.6) { angle_step = 360/teeth; points = [for (i = [0:teeth-1]) each [[r_in*cos(i*angle_step-angle_step*flat/4), r_in*sin(i*angle_step-angle_step*flat/4)], [r_out*cos(i*angle_step-angle_step*flat/8), r_out*sin(i*angle_step-angle_step*flat/8)], [r_out*cos(i*angle_step+angle_step*flat/8), r_out*sin(i*angle_step+angle_step*flat/8)], [r_in*cos(i*angle_step+angle_step*flat/4), r_in*sin(i*angle_step+angle_step*flat/4)]]]; polygon(points); }
module big_gear_for_shaft(dia, is_d) { difference() { linear_extrude(height = 15) gear_profile(36, 30, 27); translate([0,0,-1]) { if(is_d) intersection() { cylinder(h=17, d=dia); translate([-dia/2, -dia/2 + 0.8, 0]) cube([dia, dia, 17]); } else cylinder(h=17, d=dia); } translate([0, 0, 7.5]) rotate([0, 90, 0]) cylinder(h=30, d=3.2); } }
module motor_body() { color("SlateGray") { translate([-21.15, -21.15, 0]) cube([42.3, 42.3, 48]); translate([0,0,48]) cylinder(h=24, d=5); } }
module encoder_body() { color("DimGray") { cylinder(h=35, r=19); translate([0,0,35]) cylinder(h=20, d=6); } }
module arduino_uno_r3() { color("DarkCyan") cube([68.6, 53.3, 1.6]); color("Silver") translate([-6, 35, 1.6]) cube([16, 12, 11]); color("Black") translate([-2, 5, 1.6]) cube([14, 9, 11]); }