// ============================================================
// FILE: Master_System_Simulation_V12.9.scad
// DESCRIPTION: Complete 3D Assembly Simulation (No Lid Edition)
// ALL UPDATES INCLUDED: 5mm Base, 30mm Cradles, 7.9mm Bottom Pin, 9.1mm Top Pin.
// ============================================================

$fn = 64;           
mm = 25.4;

// --- GLOBAL DIMENSIONS ---
wall     = 3;           // Side wall thickness (0.3 cm)
base_h   = 5;           // Heavy base thickness (0.5 cm)
box_w    = 270;         // Shrunk to fit 27cm printer bed
box_d    = 160; 
box_h    = 100; 
corner_r = 5;       

// --- TRANSMISSION & GEOMETRY SPECS ---
mesh_dist   = 37.3;     // Calibrated center-to-center distance
mech_center = [175, 80, base_h]; 
cradle_h    = 30;       // Increased height for motor/encoder stability

rod_h        = 140;     // Total gear rod height
th           = 80;      // Gear teeth height
rod_dia      = 9.5;     // Main rod core diameter
top_pin_dia  = 9.1;     // Your updated top shaft diameter
bottom_pin_dia = 7.9;   // Your updated bottom bearing pin diameter
bottom_pin_h   = 6.7;   // Your updated physical bearing height

antenna_h    = 10.5 * mm; // Total height of the mast
socket_depth = 30;        // Depth the gear rod inserts into mast

// --- ELECTRONICS POSITIONS ---
arduino_pos = [wall + 5, 80, base_h];      
pcb_pos     = [wall + 5, 20, base_h]; 

// ============================================================
// THE LIVE SIMULATION ASSEMBLY
// ============================================================

// 1. Render the static Chassis Enclosure
render_chassis_base();

// 2. Render the internal mechanical and electrical components in place
translate(mech_center) {
    
    // CENTRAL TRANSMISSION CORE
    // Gear Rod sits perfectly on the floor, dropping its pin into the podium pocket
    color("LimeGreen") actual_gear_rod();
    
    // Antenna Mast slides down onto the top 30mm D-Cut of the gear rod
    translate([0, 0, 115]) color("Gold") actual_antenna_mast();
    
    // Webcam Cage drops onto the top D-cut of the 20mm antenna mast
    translate([0, 0, 115 + (antenna_h - 35)]) actual_webcam_cage();

    // ACTUATORS (Positioned at exact meshing distances)
    // NEMA 17 Stepper Motor (Model: 17HE19-2004S)
    translate([-mesh_dist, 0, 0]) {
        color("SlateGray") cube([42.3, 42.3, 48], center=true); // 42.3mm Max Body
        translate([0, 0, 24]) color("DarkSlateGray") cylinder(h=24, d=5); // 24mm Motor Shaft
        translate([0, 0, 30]) color("Orange") spur_gear_36T(d_hole=5);   // Motor Drive Gear
    }
    
    // BRT38 Absolute Encoder
    translate([mesh_dist, 0, 0]) {
        color("DimGray") cylinder(h=35, r=19); // Encoder Main Body
        translate([0, 0, 35]) color("DarkSlateGray") cylinder(h=15, d=6); // Encoder Shaft
        translate([0, 0, 40]) color("Orange") spur_gear_36T(d_hole=6);   // Encoder Slave Gear
    }
    
    // LOWER BALL BEARING (Seated flush inside the podium floor)
    translate([0, 0, 0]) color("SteelBlue", 0.7) 
        difference() { cylinder(h=bottom_pin_h, d=19); translate([0,0,-1]) cylinder(h=bottom_pin_h+2, d=8); }
}

// ELECTRONICS VISUALIZER
translate([arduino_pos[0], arduino_pos[1], base_h]) color("DarkCyan") cube([68.6, 53.3, 5]); // Arduino Uno Shape
translate([pcb_pos[0], pcb_pos[1], base_h]) color("MediumSeaGreen") cube([60, 40, 5]);       // Custom PCB Shape


// ============================================================
// COMPONENT MODULES DEFINITIONS
// ============================================================

module render_chassis_base() {
    union() {
        // Outer box shell with integrated port cutouts
        difference() {
            color("Ivory", 0.8) rounded_block(box_w, box_d, box_h, corner_r);
            translate([wall, wall, base_h]) 
                rounded_block(box_w - wall*2, box_d - wall*2, box_h + 1, corner_r - 1.5);
            
            // Parametric Port Openings (Auto-shifted up for the 5mm base)
            translate([-1, arduino_pos[1] + 32, base_h + 2.5]) cube([wall + 2, 12, 11]);
            translate([-1, arduino_pos[1] + 3, base_h + 2.5]) cube([wall + 2, 9.5, 11]);
            translate([-1, pcb_pos[1] + 13, base_h + 2.5]) cube([wall + 2, 10, 10]);
        }

        // Dual Ballast Compartments
        for(y_pos = [wall, box_d - wall - 40]) {
            translate([box_w - wall - 60, y_pos, base_h]) {
                difference() {
                    color("DimGray") cube([60, 40, 30]); 
                    translate([wall, wall, wall]) cube([60-wall*2, 40-wall*2, 35]);
                }
            }
        }

        // Heavy-Duty 30mm Motor Cradle
        translate([mech_center[0] - mesh_dist, mech_center[1], base_h]) 
            difference() {
                translate([-23.35, -23.35, 0]) cube([46.7, 46.7, cradle_h]);
                translate([-21.35, -21.35, -1]) cube([42.7, 42.7, cradle_h + 2]);
                translate([-10, 21.2, 0]) cube([20, 10, cradle_h + 1]); 
            }

        // Heavy-Duty 30mm Encoder Cradle
        translate([mech_center[0] + mesh_dist, mech_center[1], base_h]) 
            difference() {
                cylinder(h=cradle_h, r=21.4);
                translate([0,0,-1]) cylinder(h=cradle_h + 2, r=19.4);
                translate([-10, -28.4, 0]) cube([20, 10, cradle_h + 1]); 
            }
        
        // Arduino Uno Mounting Standoffs
        translate([arduino_pos[0], arduino_pos[1], base_h]) 
            for(h = [[14, 2.5], [15.3, 50.8], [66.1, 7.6], [66.1, 35.6]]) translate([h[0], h[1], 0]) 
                difference() { cylinder(h=5, r=3); translate([0,0,-1]) cylinder(h=7, r=1.5); }
        
        // Sensor PCB Mounting Standoffs
        translate([pcb_pos[0], pcb_pos[1], base_h]) 
            for(h = [[0, 0], [56, 0], [0, 36], [56, 36]]) translate([h[0], h[1], 0]) 
                difference() { color("Lime") cylinder(h=5, r=3); translate([0,0,-1]) cylinder(h=7, r=1.5); }

        // Lower Bearing Podium (Deepened to 6.7mm for flush seating)
        translate([mech_center[0], mech_center[1], base_h])
            difference() {
                cylinder(h=6.5, d=26);
                translate([0,0,-0.1]) cylinder(h=6.7, d=19.3); 
                translate([0,0,-base_h-1]) cylinder(h=base_h+8, d=10.8); 
            }

        // Cable Harnessing Wall Hooks
        hook_coords = [[120, 157, 40], [210, 157, 40], [120, 3, 40], [210, 3, 40], [267, 120, 40], [267, 40, 40]];
        for(c = hook_coords) translate([c[0], c[1], c[2]]) 
            rotate([0, 0, (c[1]>100?180:(c[0]>260?90:0))]) wall_hook();
    }
}

module actual_gear_rod() {
    // 1. Bottom Pin (7.9mm diameter, drops into floor pocket)
    translate([0, 0, -bottom_pin_h]) cylinder(h = bottom_pin_h, d = bottom_pin_dia);

    // 2. Central 12-Tooth Gear Core
    linear_extrude(height = th) gear_geometry(12, 8, 6);

    // 3. Top Pin Section (Uniform 9.1mm Diameter)
    translate([0, 0, th]) {
        difference() {
            cylinder(h = rod_h - th + 5, d = top_pin_dia);
            // D-cut flat engagement face
            translate([top_pin_dia/2 - 1.5, -5, rod_h - th - socket_depth + 5]) 
                cube([5, 10, socket_depth + 1]);
        }
    }
}

module actual_antenna_mast() {
    difference() {
        cylinder(h = socket_depth + 15, d = 26); 
        translate([0, 0, -1]) {
            difference() {
                cylinder(h = socket_depth + 2, d = 9.1 + 0.2); // Sized to 9.3mm internal hole
                translate([9.1/2 - 1.3, -9.1, 0]) cube([9.1, 9.1*2, socket_depth + 5]); 
            }
        }
        translate([0, 0, socket_depth / 2]) rotate([0, 90, 0]) cylinder(h = 28, d = 3.6, center=true); 
    }
    translate([0, 0, socket_depth + 15]) {
        difference() {
            cylinder(h = antenna_h - (socket_depth + 15), d = 20); 
            translate([20/2 - 3, -20, antenna_h - (socket_depth + 15) - 30]) cube([10, 40, 31]);
        }
    }
    translate([0, 0, socket_depth + 15]) mirror([0,0,1]) cylinder(h=15, d1=26, d2=20); 
    // Dual Fin Support Arms
    for (z_pos = [antenna_h - 115.8 - 45, antenna_h - 45]) { 
        translate([0, 0, z_pos - 15]) {
            difference() {
                translate([-5, 0, 0]) cube([10, 75, 30]); 
                translate([-6, 65, 15]) rotate([0, 90, 0]) cylinder(h = 12, d = 3.6); 
            }
            translate([-3, 1, 0]) rotate([90, 0, 90]) linear_extrude(6) polygon([[0, 0], [0, -35], [60, 0]]); 
        }
    }
}

module actual_webcam_cage() {
    difference() {
        cylinder(h = 35, d = 30);
        translate([0, 0, -1]) difference() {
            cylinder(h = 37, d = 20.6);
            translate([10 - 3, -20, 0]) cube([10, 40, 42]);
        }
        translate([0, 0, 17.5]) rotate([0, 90, 0]) cylinder(h = 40, d = 4.2, center=true);
    }
    translate([0, 0, 35]) cylinder(h = 88.9, d = 20);
    translate([0, 0, 35 + 88.9]) {
        translate([-59, 0, 0]) cube([118, 59, 6]);
        translate([0, 0, 6]) difference() {
            union() {
                translate([-59, 0, 0]) cube([118, 4, 50]);
                translate([-59, 0, 0]) cube([4, 59, 50]);
                translate([55, 0, 0]) cube([4, 59, 50]);
                translate([-59, 0, 50]) cube([118, 41.25, 4]);
            }
            translate([-10, -1, -1]) cube([20, 61, 56]);
        }
    }
}

module spur_gear_36T(d_hole) {
    difference() {
        linear_extrude(15) gear_geometry(36, 30, 27);
        translate([0,0,-1]) cylinder(h=17, d=d_hole);
    }
}

module gear_geometry(teeth, r_out, r_in, flat=0.6) {
    angle_step = 360/teeth;
    points = [for (i = [0:teeth-1]) each [
        [r_in*cos(i*angle_step-angle_step*flat/4), r_in*sin(i*angle_step-angle_step*flat/4)],
        [r_out*cos(i*angle_step-angle_step*flat/8), r_out*sin(i*angle_step-angle_step*flat/8)],
        [r_out*cos(i*angle_step+angle_step*flat/8), r_out*sin(i*angle_step+angle_step*flat/8)],
        [r_in*cos(i*angle_step+angle_step*flat/4), r_in*sin(i*angle_step+angle_step*flat/4)]
    ]];
    polygon(points);
}

module rounded_block(w, d, h, r) {
    hull() {
        for(x=[r, w-r], y=[r, d-r]) translate([x, y, 0]) cylinder(h=h, r=r);
    }
}

module wall_hook() {
    union() { cube([10, 2, 15]); translate([0, 2, 0]) cube([10, 8, 2]); translate([0, 10, 0]) cube([10, 2, 8]); }
}