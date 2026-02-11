// ============================================================
// VERSION 10.6: THE "EVERYTHING" BUILD (FINAL PRODUCTION)
// FIXED: High-fidelity Antenna Elements + SMA Connector
// AUDITED: All 10 points (Bearings, Encoder, Gears, Handshakes)
// ============================================================

$fn = 64;           
mm = 25.4;

// --- 1. GLOBAL DIMENSIONS ---
wall         = 3;           
box_w        = 280; 
box_d        = 160; 
box_h        = 100; 
corner_r     = 5;       

// --- 2. MECHANICAL SPECS ---
mesh_dist      = 37.3; 
mech_center    = [180, 80, wall];    
rod_h          = 140; 
rod_dia        = 9.5;      
main_rod_dia   = 20;       
socket_depth   = 30;       
mast_h         = 10.5 * mm; 
arm_slide_down = 45; 
hole_spacing   = 4.56 * mm; 
reach          = 65;

// --- 3. VISIBILITY DASHBOARD ---
show_box           = true;
show_lid           = false;
lid_closed         = true; 
show_arduino       = true;
show_motor         = true;
show_encoder       = true; 
show_rod           = true;
show_bearings      = true;
show_antenna_mast  = false;
show_pcb_antenna   = false;
show_webcam_topper = false;

// ============================================================
// EXECUTION BLOCK
// ============================================================

if (show_box) main_box_final();

lid_z_pos = lid_closed ? box_h : box_h + 35;
if (show_lid) translate([0, 0, lid_z_pos]) interlocking_lid(); 

assembly();

// ============================================================
// ASSEMBLY LOGIC
// ============================================================

module assembly() {
    if (show_arduino) translate([wall, 40, wall]) arduino_uno_r3();

    translate(mech_center) {
        // CENTER ROD ASSEMBLY
        if (show_rod) {
            translate([0, 0, 5.2 - 0.5]) {
                color("LimeGreen") gear_rod_stepped(h=rod_h, th=80);
                
                if (show_antenna_mast) {
                    translate([0, 0, lid_z_pos + wall - (5.2 - 0.5)]) {
                        reinforced_mast_dual_keyed();
                        
                        // 9. THE DETAILED PCB ANTENNA
                        if (show_pcb_antenna) {
                            translate([0, reach, mast_h - (hole_spacing/2) - arm_slide_down]) 
                                rotate([90, 0, 90]) translate([-12, 0, 0]) 
                                directional_antenna_pcb_standalone();
                        }
                        
                        // 10. CAMERA MOUNT TOPPER
                        if (show_webcam_topper) {
                            translate([0, 0, mast_h]) webcam_cage_keyed_topper();
                        }
                    }
                }
            }
        }
        
        // 5. BEARINGS (Floor and Lid)
        if (show_bearings) {
            color("SteelBlue", 0.6) {
                translate([0, 0, 5.2 - 5]) ball_bearing_3d(); 
                translate([0, 0, lid_z_pos - wall - 5.2 + 0.2]) ball_bearing_3d();
            }
        }
        
        // 2, 3, 6. MOTOR & ENCODER & GEARS
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
}

// ============================================================
// 9. DETAILED ANTENNA MODULE
// ============================================================
module directional_antenna_pcb_standalone() {
    widest_len = 8.92 * mm; 
    hole_dist  = 4.56 * mm;
    hole_dia   = 0.15 * mm;
    pcb_thick  = 1.6; 
    margin     = 7; 
    num_elements = 12;  
    tau = 0.84;          
    antenna_span = widest_len * 1.45; 

    union() {
        difference() {
            // Substrate
            color("DarkGreen") hull() {
                translate([0, -(widest_len/2 + margin), 0]) cube([5, widest_len + 14, pcb_thick]);
                final_L = widest_len * pow(tau, num_elements - 1);
                translate([antenna_span + 25, -(final_L/2 + 4), 0]) cube([5, final_L + 10, pcb_thick]);
            }
            // Mounting Holes
            translate([12, hole_dist/2, -1])  cylinder(h=pcb_thick + 5, d=hole_dia);
            translate([12, -hole_dist/2, -1]) cylinder(h=pcb_thick + 5, d=hole_dia);
        }
        // Copper Elements
        color("Gold") for (i = [0 : num_elements - 1]) {
            L = widest_len * pow(tau, i);
            pos_x = 25 + (antenna_span * pow(i/(num_elements-1), 0.95));
            element_w = 7 * pow(tau, i*0.4); 
            translate([pos_x, -L/2, 0.1]) cube([element_w, L, pcb_thick]);
        }
        // Boom and SMA
        translate([0, -2.5, pcb_thick]) color("Silver") cube([antenna_span + 20, 5, 5]);
        translate([-15, 0, pcb_thick + 2.5]) rotate([0, 90, 0]) color("Gold") {
            cylinder(h=18, d=6.5);
            translate([0,0,3]) cylinder(h=2.5, d=11, $fn=6); 
        }
    }
}

// ============================================================
// 8. TOP ROD (MAST) & 10. CAMERA TOPPER
// ============================================================
module reinforced_mast_dual_keyed() {
    top_flat_h = 30;
    union() {
        difference() {
            color("Gold") cylinder(h = socket_depth + 15, d = 26);
            translate([0, 0, -1]) difference() {
                cylinder(h = socket_depth + 2, d = rod_dia + 0.3);
                translate([rod_dia/2 - 1.5, -10, 0]) cube([10, 20, socket_depth + 5]);
            }
        }
        color("Gold") translate([0, 0, socket_depth + 15]) difference() {
            cylinder(h = mast_h - (socket_depth + 15), d = main_rod_dia);
            translate([main_rod_dia/2 - 3, -15, mast_h - (socket_depth+15) - top_flat_h]) cube([10, 30, top_flat_h + 1]);
        }
        for (z_pos = [mast_h - hole_spacing - arm_slide_down, mast_h - arm_slide_down]) {
            translate([0, 0, z_pos - 15]) {
                color("Gold") difference() {
                    translate([-5, 0, 0]) cube([10, reach + 10, 30]);
                    translate([-10, reach, 15]) rotate([0, 90, 0]) cylinder(h=20, d=3.8);
                }
                color("Red") translate([-3, 1, 0]) rotate([90, 0, 90]) linear_extrude(6) polygon([[0,0], [0,-35], [reach-5, 0]]);
            }
        }
    }
}

module webcam_cage_keyed_topper() {
    stem_h = 3.5 * mm; 
    bw = 110; bd = 55; wh = 50; wt = 4; ft = 6; chan_w = 20;
    union() {
        difference() {
            color("Gold") cylinder(h = socket_depth, d = main_rod_dia + 10);
            translate([0, 0, -1]) difference() {
                cylinder(h = socket_depth + 2, d = main_rod_dia + 0.4);
                translate([main_rod_dia/2 - 3, -15, 0]) cube([10, 30, socket_depth + 5]);
            }
        }
        color("Gold") translate([0, 0, socket_depth]) cylinder(h = stem_h, d = 20);
        translate([0, 0, socket_depth + stem_h]) {
            color("Silver") translate([-bw/2 - wt, 0, 0]) cube([bw + (wt*2), bd + wt, ft]);
            color("DimGray") translate([0, 0, ft]) difference() {
                union() {
                    translate([-bw/2 - wt, 0, 0]) cube([bw + (wt*2), wt, wh]); 
                    translate([-bw/2 - wt, 0, 0]) cube([wt, bd + wt, wh]);      
                    translate([bw/2, 0, 0]) cube([wt, bd + wt, wh]);           
                    translate([-bw/2 - wt, 0, wh]) cube([bw + (wt*2), bd * 0.75, wt]); 
                }
                translate([-chan_w/2, -1, -1]) cube([chan_w, bd + 2, wh + wt + 2]); 
            }
            for(x = [-8, 2]) translate([x, 2, 0]) rotate([90, 0, 90]) linear_extrude(6) polygon([[0, 0], [0, -45], [bd - 5, 0]]);
        }
    }
}

// ============================================================
// 1-7. BOX, RODS, GEARS, INTERNALS
// ============================================================
module main_box_final() {
    difference() {
        color("Red", 0.3) rounded_block(box_w, box_d, box_h, corner_r);
        translate([wall, wall, wall]) rounded_block(box_w - wall*2, box_d - wall*2, box_h + 1, corner_r - 1.5);
        translate([-1, 72, wall + 2.5]) cube([wall + 2, 12, 11]);
        translate([-1, 43, wall + 2.5]) cube([wall + 2, 9.5, 11]);
    }
    // Floor Bearing Hub
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

module gear_rod_stepped(h, th) {
    translate([0, 0, -4.5]) cylinder(h = 5, d = 9.4);
    linear_extrude(height = th) gear_profile(12, 8, 6);
    translate([0, 0, th]) difference() {
        cylinder(h = h - th + 5, d = 9.4);
        translate([rod_dia/2 - 1.5, -5, h - th - 30 + 5]) cube([5, 10, 31]);
    }
}

module interlocking_lid() {
    color("Ivory", 0.7) union() {
        difference() {
            rounded_block(box_w, box_d, wall, corner_r);
            translate([mech_center[0], mech_center[1], -1]) cylinder(h=wall+2, d=10.5);
        }
        translate([mech_center[0], mech_center[1], -5.2]) difference() {
            cylinder(h=5.2, d=25);
            translate([0,0,-0.1]) cylinder(h=5.4, d=19.1);
        }
    }
}

// --- UTILITIES ---
module ball_bearing_3d() { difference() { cylinder(h = 5, d = 19); translate([0, 0, -1]) cylinder(h = 7, d = 11.5); } }
module motor_body() { color("SlateGray") { translate([-21.15, -21.15, 0]) cube([42.3, 42.3, 48]); translate([0,0,48]) cylinder(h=24, d=5); } }
module encoder_body() { color("DimGray") { cylinder(h=35, r=19); translate([0,0,35]) cylinder(h=20, d=6); } }
module arduino_uno_r3() { color("DarkCyan") cube([68.6, 53.3, 1.6]); color("Silver") translate([-6, 35, 1.6]) cube([16, 12, 11]); color("Black") translate([-2, 5, 1.6]) cube([14, 9, 11]);}
module big_gear_for_shaft(dia, is_d) { difference() { linear_extrude(height = 15) gear_profile(36, 30, 27); translate([0,0,-1]) { if(is_d) intersection() { cylinder(h=17, d=dia); translate([-dia/2, -dia/2 + 0.8, 0]) cube([dia, dia, 17]); } else cylinder(h=17, d=dia); } } }
module rounded_block(w, d, h, r) { hull() { translate([r, r, 0]) cylinder(h=h, r=r); translate([w-r, r, 0]) cylinder(h=h, r=r); translate([w-r, d-r, 0]) cylinder(h=h, r=r); translate([r, d-r, 0]) cylinder(h=h, r=r); } }
module gear_profile(teeth, r_out, r_in, flat=0.6) { angle_step = 360/teeth; points = [for (i = [0:teeth-1]) each [[r_in*cos(i*angle_step-angle_step*flat/4), r_in*sin(i*angle_step-angle_step*flat/4)], [r_out*cos(i*angle_step-angle_step*flat/8), r_out*sin(i*angle_step-angle_step*flat/8)], [r_out*cos(i*angle_step+angle_step*flat/8), r_out*sin(i*angle_step+angle_step*flat/8)], [r_in*cos(i*angle_step+angle_step*flat/4), r_in*sin(i*angle_step+angle_step*flat/4)]]]; polygon(points); }