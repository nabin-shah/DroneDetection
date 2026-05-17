// FILE: Chassis_Production_V11.11.scad
// UPDATED: Base thickness increased to 5mm for maximum stability.
// UPDATED: All port cutouts auto-shifted to match the new floor height.
// SPECS: Width = 270mm (27cm), Cradle Height = 30mm.

$fn = 64;           
wall = 3;           // Side wall thickness
base_h = 5;         // NEW: Thicker base floor
box_w = 270; 
box_d = 160; 
box_h = 100; 
corner_r = 5;       

// --- COORDINATE SYSTEM (Now driven by base_h) ---
mesh_dist = 37.3; 
mech_center = [175, 80, base_h]; // Raised to sit on 5mm floor
arduino_pos = [wall + 5, 80, base_h];      
pcb_pos     = [wall + 5, 20, base_h]; 
cradle_h    = 30; 

// ============================================================
// THE SOLID CHASSIS
// ============================================================

union() {
    // 1. THE MAIN OUTER SHELL
    difference() {
        color("Ivory") rounded_block(box_w, box_d, box_h, corner_r);
        // Interior cutout starts at base_h (5mm)
        translate([wall, wall, base_h]) 
            rounded_block(box_w - wall*2, box_d - wall*2, box_h + 1, corner_r - 1.5);
        
        // --- FIXED PORT CUTOUTS (Shifted +2mm up) ---
        // Arduino USB & Power re-centered for 5mm base
        translate([-1, arduino_pos[1] + 32, base_h + 2.5]) cube([wall + 2, 12, 11]);
        translate([-1, arduino_pos[1] + 3, base_h + 2.5]) cube([wall + 2, 9.5, 11]);
        // 12V DC Input re-centered
        translate([-1, pcb_pos[1] + 13, base_h + 2.5]) cube([wall + 2, 10, 10]);
        
        // CALIBRATED Mounting Holes (3.7mm for M3)
        // Drills through the full 5mm base
        translate([mech_center[0] - mesh_dist, mech_center[1], -1]) 
            for(x=[-15.5, 15.5], y=[-15.5, 15.5]) translate([x, y, 0]) cylinder(h=base_h+2, d=3.7);
        translate([mech_center[0] + mesh_dist, mech_center[1], -1]) 
            for(a=[0, 120, 240]) rotate([0, 0, a]) translate([14, 0, 0]) cylinder(h=base_h+2, d=3.7);
    }

    // 2. BALLAST BINS (Fused to 5mm base)
    for(y_pos = [wall, box_d - wall - 40]) {
        translate([box_w - wall - 60, y_pos, base_h]) {
            difference() {
                color("DimGray") cube([60, 40, 30]); 
                translate([wall, wall, wall]) cube([60-wall*2, 40-wall*2, 35]);
            }
        }
    }

    // 3. REINFORCED MOTOR CRADLE (30mm Height)
    translate([mech_center[0] - mesh_dist, mech_center[1], base_h]) 
        difference() {
            translate([-23.35, -23.35, 0]) cube([46.7, 46.7, cradle_h]);
            translate([-21.35, -21.35, -1]) cube([42.7, 42.7, cradle_h + 2]);
            translate([-10, 21.2, 0]) cube([20, 10, cradle_h + 1]); 
        }

    // 4. REINFORCED ENCODER CRADLE (30mm Height)
    translate([mech_center[0] + mesh_dist, mech_center[1], base_h]) 
        difference() {
            cylinder(h=cradle_h, r=21.4);
            translate([0,0,-1]) cylinder(h=cradle_h + 2, r=19.4);
            translate([-10, -28.4, 0]) cube([20, 10, cradle_h + 1]); 
        }
    
    // 5. ARDUINO & 6. PCB STANDOFFS (Fused to 5mm base)
    translate([arduino_pos[0], arduino_pos[1], base_h]) 
        for(h = [[14, 2.5], [15.3, 50.8], [66.1, 7.6], [66.1, 35.6]]) translate([h[0], h[1], 0]) 
            difference() { cylinder(h=5, r=3); translate([0,0,-1]) cylinder(h=7, r=1.5); }
    
    translate([pcb_pos[0], pcb_pos[1], base_h]) 
        for(h = [[0, 0], [56, 0], [0, 36], [56, 36]]) translate([h[0], h[1], 0]) 
            difference() { color("Lime") cylinder(h=5, r=3); translate([0,0,-1]) cylinder(h=7, r=1.5); }

    // 7. BEARING PODIUM
    translate([mech_center[0], mech_center[1], base_h])
        difference() {
            cylinder(h=5.2, d=26);
            translate([0,0,-0.1]) cylinder(h=5.4, d=19.3);
            translate([0,0,-base_h-1]) cylinder(h=base_h+5, d=10.8);
        }

    // 8. WIRE MANAGEMENT HOOKS
    hook_coords = [[120, 157, 40], [210, 157, 40], [120, 3, 40], [210, 3, 40], [267, 120, 40], [267, 40, 40]];
    for(c = hook_coords) translate([c[0], c[1], c[2]]) 
        rotate([0, 0, (c[1]>100?180:(c[0]>260?90:0))]) wall_hook();
}

module wall_hook() {
    color("DimGray") union() {
        cube([10, 2, 15]); translate([0, 2, 0]) cube([10, 8, 2]); translate([0, 10, 0]) cube([10, 2, 8]);
    }
}

module rounded_block(w, d, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, d-r, 0]) cylinder(h=h, r=r);
        translate([r, d-r, 0]) cylinder(h=h, r=r);
    }
}