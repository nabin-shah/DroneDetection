// ============================================================
// FILE: Master_System_Simulation_V13.2.scad
// DESCRIPTION: Master Simulation with Variable Toggle Options (Show/Hide)
// ============================================================

$fn = 64;           
mm = 25.4;

// ============================================================
// 👁️ VISIBILITY TOGGLES (Set to true to SHOW, false to HIDE)
// ============================================================
show_chassis     = true;
show_brace       = true;
show_gear_rod    = true;
show_actuators   = true;
show_mast        = false;
show_webcam      = false;
show_electronics = true;

// --- 1. CHASSIS CONFIGURATION ---
wall     = 3;           
base_h   = 5;           
box_w    = 270;         
box_d    = 160;         
box_h    = 100;         
corner_r = 5;       

// --- 2. MECHANICS CONFIGURATION ---
mesh_dist   = 37.3;     
mech_center = [175, 80, base_h]; 
cradle_h    = 30;       

rod_h        = 140;     
th           = 80;      
rod_dia      = 9.5;     
top_pin_dia  = 9.1;     
bottom_pin_dia = 7.9;   
bottom_pin_h   = 6.7;   

antenna_h    = 10.5 * mm; 
socket_depth = 30;        

// --- 3. LIGHTWEIGHT BRACE COEFFICIENTS ---
brace_width     = 16;       
brace_thick     = 4;        
brace_boss_od   = 32.1;     
brace_boss_h    = 10;       
brace_bearing_od = 26.1;    
brace_bearing_h = 7.9;      
brace_thru_hole = 10.5;     

arduino_pos = [wall + 5, 80, base_h];      
pcb_pos     = [wall + 5, 20, base_h]; 

// ============================================================
// THE LIVE SIMULATION ASSEMBLY (CONDITIONAL RENDER)
// ============================================================

// A. Main Outer Chassis Enclosure
if (show_chassis) {
    render_chassis_base();
}

// B. Friction-Fit Stabilizer Brace
if (show_brace) {
    translate([mech_center[0], box_d/2, box_h]) 
        color("LightSteelBlue", 0.9) render_optimized_brace();
}

// C. Internal Components and Actuators
translate(mech_center) {
    
    // Central Gear Rod
    if (show_gear_rod) {
        color("LimeGreen") actual_gear_rod();
    }
    
    // Upper Bearing (Sits inside the brace boss, only shown if the brace or rod is on)
    if (show_brace && show_gear_rod) {
        translate([0, 0, box_h - base_h + (brace_boss_h - brace_bearing_h)]) 
            color("LightGray", 0.8) differential_upper_bearing();
    }
    
    // Antenna Mast
    if (show_mast) {
        translate([0, 0, 120]) color("Gold") actual_antenna_mast();
    }
    
    // Webcam Cage
    if (show_webcam) {
        translate([0, 0, 120 + (antenna_h - 35)]) actual_webcam_cage();
    }

    // Actuators & Drivetrain Motors
    if (show_actuators) {
        // NEMA 17 Stepper Motor
        translate([-mesh_dist, 0, 0]) {
            color("SlateGray") cube([42.3, 42.3, 48], center=true); 
            translate([0, 0, 24]) color("DarkSlateGray") cylinder(h=24, d=5); 
            translate([0, 0, 30]) color("Orange") spur_gear_36T(d_hole=5);   
        }
        // BRT38 Absolute Encoder
        translate([mesh_dist, 0, 0]) {
            color("DimGray") cylinder(h=35, r=19); 
            translate([0, 0, 35]) color("DarkSlateGray") cylinder(h=15, d=6); 
            translate([0, 0, 40]) color("Orange") spur_gear_36T(d_hole=6);   
        }
        // Lower Ball Bearing
        translate([0, 0, 0]) color("SteelBlue", 0.7) 
            difference() { cylinder(h=bottom_pin_h, d=19); translate([0,0,-1]) cylinder(h=bottom_pin_h+2, d=8); }
    }
}

// D. Computing Boards & Power Elements
if (show_electronics) {
    translate([arduino_pos[0], arduino_pos[1], base_h]) color("DarkCyan") cube([68.6, 53.3, 5]); 
    translate([pcb_pos[0], pcb_pos[1], base_h]) color("MediumSeaGreen") cube([60, 40, 5]);       
}

// ============================================================
// SOLID GEOMETRY MODULE GENERATIONS
// ============================================================

module render_optimized_brace() {
    difference() {
        union() {
            translate([-brace_width/2, -box_d/2, 0]) cube([brace_width, box_d, brace_thick]);
            cylinder(h = brace_boss_h, d = brace_boss_od);
            translate([-brace_width/2, -box_d/2 + wall, -20]) cube([brace_width, wall, 20]);
            translate([-brace_width/2, box_d/2 - wall - wall, -20]) cube([brace_width, wall, 20]);
        }
        translate([0, 0, brace_boss_h - brace_bearing_h]) cylinder(h = brace_bearing_h + 1, d = brace_bearing_od);
        translate([0, 0, -1]) cylinder(h = brace_boss_h + 2, d = brace_thru_hole);
    }
}

module render_chassis_base() {
    union() {
        difference() {
            color("Ivory", 0.5) rounded_block(box_w, box_d, box_h, corner_r); 
            translate([wall, wall, base_h]) rounded_block(box_w - wall*2, box_d - wall*2, box_h + 1, corner_r - 1.5);
            translate([-1, arduino_pos[1] + 32, base_h + 2.5]) cube([wall + 2, 12, 11]);
            translate([-1, arduino_pos[1] + 3, base_h + 2.5]) cube([wall + 2, 9.5, 11]);
            translate([-1, pcb_pos[1] + 13, base_h + 2.5]) cube([wall + 2, 10, 10]);
        }
        for(y_pos = [wall, box_d - wall - 40]) translate([box_w-wall-60, y_pos, base_h]) 
            difference() { cube([60, 40, 30]); translate([wall, wall, wall]) cube([54, 34, 35]); }
        translate([mech_center[0] - mesh_dist, mech_center[1], base_h]) 
            difference() { translate([-23.35, -23.35, 0]) cube([46.7, 46.7, cradle_h]); translate([-21.35, -21.35, -1]) cube([42.7, 42.7, cradle_h + 2]); }
        translate([mech_center[0] + mesh_dist, mech_center[1], base_h]) 
            difference() { cylinder(h=cradle_h, r=21.4); translate([0,0,-1]) cylinder(h=cradle_h + 2, r=19.4); }
        translate([mech_center[0], mech_center[1], base_h])
            difference() { cylinder(h=6.5, d=26); translate([0,0,-0.1]) cylinder(h=6.7, d=19.3); translate([0,0,-base_h-1]) cylinder(h=base_h+8, d=10.8); }
    }
}

module actual_gear_rod() {
    translate([0, 0, -bottom_pin_h]) cylinder(h = bottom_pin_h, d = bottom_pin_dia);
    linear_extrude(height = th) gear_geometry(12, 8, 6);
    translate([0, 0, th]) {
        difference() {
            cylinder(h = rod_h - th + 5, d = top_pin_dia);
            translate([top_pin_dia/2 - 1.5, -5, rod_h - th - socket_depth + 5]) cube([5, 10, socket_depth + 1]);
        }
    }
}

module differential_upper_bearing() {
    difference() { cylinder(h=brace_bearing_h, d=25.9); translate([0,0,-1]) cylinder(h=brace_bearing_h+2, d=10); }
}

module actual_antenna_mast() {
    difference() {
        cylinder(h = socket_depth + 15, d = 26); 
        translate([0, 0, -1]) {
            difference() {
                cylinder(h = socket_depth + 2, d = 9.1 + 0.2); 
                translate([9.1/2 - 1.3, -9.1, 0]) cube([9.1, 9.1*2, socket_depth + 5]); 
            }
        }
    }
    translate([0, 0, socket_depth + 15]) cylinder(h = antenna_h - (socket_depth + 15), d = 20); 
    translate([0, 0, socket_depth + 15]) mirror([0,0,1]) cylinder(h=15, d1=26, d2=20); 
}

module actual_webcam_cage() {
    difference() { cylinder(h = 35, d = 30); translate([0, 0, -1]) cylinder(h = 37, d = 20.6); }
    translate([0, 0, 35]) cylinder(h = 88.9, d = 20);
    translate([0, 0, 35 + 88.9]) translate([-59, 0, 0]) cube([118, 59, 6]);
}

module spur_gear_36T(d_hole) {
    difference() { linear_extrude(15) gear_geometry(36, 30, 27); translate([0,0,-1]) cylinder(h=17, d=d_hole); }
}

module gear_geometry(teeth, r_out, r_in, flat=0.6) {
    angle_step = 360/teeth;
    points = [for (i = [0:teeth-1]) each [
        [r_in*cos(i*angle_step-angle_step*flat/4), r_in*sin(i*angle_step-angle_step*flat/4)],
        [r_out*cos(i*angle_step-angle_step*flat/8), r_out*sin(i*angle_step-angle_step*flat/8)],
        [r_out*cos(i=angle_step+angle_step*flat/8), r_out*sin(i*angle_step+angle_step*flat/8)],
        [r_in*cos(i*angle_step+angle_step*flat/4), r_in*sin(i*angle_step+angle_step*flat/4)]
    ]];
    polygon(points);
}

module rounded_block(w, d, h, r) {
    hull() { for(x=[r, w-r], y=[r, d-r]) translate([x, y, 0]) cylinder(h=h, r=r); }
}