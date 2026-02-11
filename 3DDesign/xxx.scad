// ============================================================
// VERSION 8.8: PRODUCTION READY - FINAL AUDIT COMPLETE
// ============================================================

$fn = 64;           
wall = 3;           
box_w = 280; box_d = 160; box_h = 100; corner_r = 5;       
mm = 25.4;

// --- VISIBILITY DASHBOARD ---
show_box              = true;
show_lid              = false;
lid_closed            = true; 
show_arduino          = true;
show_motor            = true;
show_encoder          = true;
show_gear_rod         = true; 
show_bearings         = true;
show_antenna_mast     = true;
show_pcb_antenna      = true;

// --- MECHANICAL SPECS ---
arm_slide_down = 45; 
mesh_dist      = 37.3; 
mech_center    = [180, 80, wall];    
rod_h          = 140;         
mast_h         = 10.5 * mm;   
hole_spacing   = 4.56 * mm;   
reach          = 65;          
rod_dia        = 9.5;

// ============================================================
// EXECUTION
// ============================================================

if (show_box) {
    difference() {
        color("Red", 0.3) rounded_block(box_w, box_d, box_h, corner_r);
        translate([wall, wall, wall]) 
            rounded_block(box_w - wall*2, box_d - wall*2, box_h + 1, corner_r - 1.5);
    }
}

lid_z_pos = lid_closed ? box_h : box_h + 35;
if (show_lid) translate([0, 0, lid_z_pos]) {
    color("Ivory", 0.7) difference() {
        rounded_block(box_w, box_d, wall, corner_r);
        translate([mech_center[0], mech_center[1], -1]) cylinder(h=wall+2, d=11);
    }
}

translate(mech_center) {
    if (show_gear_rod) {
        translate([0, 0, 5.2 - 0.5]) {
            color("LimeGreen") gear_rod_stepped(h=rod_h, th=80);
            if (show_antenna_mast) {
                translate([0, 0, lid_z_pos + wall - (5.2 - 0.5)]) {
                    reinforced_mast_sliding_arms();
                    if (show_pcb_antenna) {
                        translate([0, reach, mast_h - (hole_spacing/2) - arm_slide_down]) 
                            rotate([90, 0, 90]) 
                            translate([-12, 0, 0]) 
                            final_antenna_standalone();
                    }
                }
            }
        }
    }

    if (show_bearings) {
        translate([0, 0, 0.2]) ball_bearing_3d(); 
        translate([0, 0, lid_z_pos - wall - 5.2 + 0.2]) ball_bearing_3d();
    }
    
    if (show_motor) translate([-mesh_dist, 0, 0]) {
        motor_body();
        color("Silver") translate([0, 0, 48 + 10]) 
            big_gear_for_shaft(dia=5.03, is_d=false);
    }
    
    if (show_encoder) translate([mesh_dist, 0, 0]) {
        encoder_body();
        color("Silver") translate([0, 0, 35 + 15]) 
            big_gear_for_shaft(dia=6.04, is_d=true); 
    }
}

if (show_arduino) translate([wall, 40, wall]) arduino_uno_r3();

// ============================================================
// MODULES
// ============================================================

module reinforced_mast_sliding_arms() {
    socket_depth = 30; main_rod_dia = 20; arm_height = 30;
    arm_width = 10; gusset_thick = 6;
    union() {
        difference() {
            color("Gold") cylinder(h = socket_depth + 15, d = 26);
            translate([0, 0, -1]) {
                difference() {
                    cylinder(h = socket_depth + 2, d = 9.8);
                    translate([rod_dia/2 - 1.5, -10, 0]) cube([10, 20, socket_depth + 5]);
                }
            }
        }
        color("Gold") translate([0, 0, socket_depth + 15])
            cylinder(h = mast_h - (socket_depth + 15), d = main_rod_dia);
        for (z_pos = [mast_h - hole_spacing - arm_slide_down, mast_h - arm_slide_down]) {
            translate([0, 0, z_pos - arm_height/2]) {
                color("Gold") difference() {
                    translate([-arm_width/2, 0, 0]) cube([arm_width, reach + 10, arm_height]);
                    translate([-10, reach, arm_height/2]) rotate([0, 90, 0]) cylinder(h=20, d=3.8);
                }
                color("Red") translate([-gusset_thick/2, 1, 0]) rotate([90, 0, 90])
                    linear_extrude(gusset_thick) polygon([[0, 0], [0, -35], [reach - 5, 0]]);
            }
        }
    }
}

module gear_rod_stepped(h, th) {
    d_cut_h = 30;
    translate([0, 0, -4.5]) cylinder(h = 5, d = 9.4);
    linear_extrude(height = th) gear_profile(12, 8, 6);
    translate([0, 0, th]) difference() {
        cylinder(h = h - th + 5, d = 9.4);
        translate([4.75 - 1.5, -5, h - th - d_cut_h + 5]) cube([5, 10, d_cut_h + 1]);
    }
}

module final_antenna_standalone() {
    widest_len = 8.92 * mm; hole_dist = 4.56 * mm; pcb_thick = 1.6;
    antenna_span = widest_len * 1.45;
    union() {
        difference() {
            color("DarkGreen") hull() {
                translate([0, -(widest_len/2 + 7), 0]) cube([5, widest_len + 14, pcb_thick]);
                translate([antenna_span + 25, -10, 0]) cube([5, 20, pcb_thick]);
            }
            translate([12, hole_dist/2, -1]) cylinder(h=10, d=3.8);
            translate([12, -hole_dist/2, -1]) cylinder(h=10, d=3.8);
        }
        color("Silver") translate([0, -2.5, pcb_thick]) cube([antenna_span + 20, 5, 5]);
    }
}

module rounded_block(w, d, h, r) { hull() { translate([r, r, 0]) cylinder(h=h, r=r); translate([w-r, r, 0]) cylinder(h=h, r=r); translate([w-r, d-r, 0]) cylinder(h=h, r=r); translate([r, d-r, 0]) cylinder(h=h, r=r); } }
module ball_bearing_3d() { color("SteelBlue") difference() { cylinder(h = 5, d = 19); translate([0, 0, -1]) cylinder(h = 7, d = 11.5); } }
module gear_profile(teeth, r_out, r_in, flat=0.6) { angle_step = 360/teeth; points = [for (i = [0:teeth-1]) each [[r_in*cos(i*angle_step-angle_step*flat/4), r_in*sin(i*angle_step-angle_step*flat/4)], [r_out*cos(i*angle_step-angle_step*flat/8), r_out*sin(i*angle_step-angle_step*flat/8)], [r_out*cos(i*angle_step+angle_step*flat/8), r_out*sin(i*angle_step+angle_step*flat/8)], [r_in*cos(i*angle_step+angle_step*flat/4), r_in*sin(i*angle_step+angle_step*flat/4)]]]; polygon(points); }
module big_gear_for_shaft(dia, is_d) { difference() { linear_extrude(height = 15) gear_profile(36, 30, 27); translate([0,0,-1]) { if(is_d) intersection() { cylinder(h=17, d=dia); translate([-dia/2, -dia/2 + 0.8, 0]) cube([dia, dia, 17]); } else cylinder(h=17, d=dia); } } }
module motor_body() { color("SlateGray") { translate([-21.15, -21.15, 0]) cube([42.3, 42.3, 48]); translate([0,0,48]) cylinder(h=24, d=5); } }
module encoder_body() { color("DimGray") { cylinder(h=35, r=19); translate([0,0,35]) cylinder(h=20, d=6); } }
module arduino_uno_r3() { color("DarkCyan") cube([68.6, 53.3, 1.6]); color("Silver") translate([-6, 35, 1.6]) cube([16, 12, 11]); color("Black") translate([-2, 5, 1.6]) cube([14, 9, 11]); }