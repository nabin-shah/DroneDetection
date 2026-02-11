// FILE: Antenna_Mast_With_Top_Key.scad
// UPDATED: Added a 30mm D-cut at the top to lock the webcam topper.

$fn = 64; 
mm = 25.4; 

// --- SHAFT & ANTENNA SPECS ---
gear_rod_dia  = 9.5;    
d_slice_depth = 1.5;    
socket_depth  = 30;     
antenna_h     = 10.5 * mm; 
hole_spacing  = 4.56 * mm; 
hole_dia      = 0.15 * mm; 

// --- GEOMETRY ---
main_rod_dia           = 20; 
base_reinforcement_dia = 26; 
horizontal_reach       = 65; 
arm_height             = 30; 
arm_width              = 10; 
gusset_thick           = 6; 

// --- NEW: TOP D-CUT SPECS ---
top_dcut_depth = 3;   // Matches the 3mm flat in the webcam topper
top_dcut_h     = 30;  // Length of the flat at the tip

// --- ARM SLIDE ADJUSTMENT ---
arm_slide_down = 45; 

// ============================================================
// RENDER
// ============================================================
union() {
    // 1. REINFORCED D-SOCKET BASE (To Gear Rod)
    difference() {
        color("Gold") cylinder(h = socket_depth + 15, d = base_reinforcement_dia); 
        translate([0, 0, -1]) {
            difference() {
                cylinder(h = socket_depth + 2, d = gear_rod_dia + 0.3);
                translate([gear_rod_dia/2 - d_slice_depth, -gear_rod_dia, 0])
                    cube([gear_rod_dia, gear_rod_dia*2, socket_depth + 5]); 
            }
        }
        translate([0, 0, socket_depth / 2]) rotate([0, 90, 0]) 
            cylinder(h = base_reinforcement_dia + 2, d = 3.6, center=true); 
    }

    // 2. THE MAIN VERTICAL MAST (With Top D-Cut)
    color("Gold") translate([0, 0, socket_depth + 15]) {
        difference() {
            // The Main 20mm Cylinder
            cylinder(h = antenna_h - (socket_depth + 15), d = main_rod_dia); 
            
            // THE TOP D-CUT FLAT
            // Positioned at the very top (antenna_h - socket_depth - 15)
            translate([main_rod_dia/2 - top_dcut_depth, -main_rod_dia, antenna_h - (socket_depth + 15) - top_dcut_h])
                cube([10, main_rod_dia*2, top_dcut_h + 1]);
        }
    }
    
    // Conical transition at base
    color("Gold") translate([0, 0, socket_depth + 15])
        mirror([0,0,1]) cylinder(h=15, d1=base_reinforcement_dia, d2=main_rod_dia); 

    // 3. THE TWO REINFORCED FIN ARMS
    for (z_pos = [antenna_h - hole_spacing - arm_slide_down, antenna_h - arm_slide_down]) { 
        translate([0, 0, z_pos - arm_height/2]) {
            color("Gold") difference() {
                translate([-arm_width/2, 0, 0]) 
                    cube([arm_width, horizontal_reach + 10, arm_height]); 
                translate([-arm_width/2 - 1, horizontal_reach, arm_height/2])
                    rotate([0, 90, 0]) 
                        cylinder(h = arm_width + 2, d = hole_dia); 
            }
            color("Red") 
            translate([-gusset_thick/2, 1, 0]) 
            rotate([90, 0, 90]) 
            linear_extrude(gusset_thick)
            polygon([[0, 0], [0, -35], [horizontal_reach - 5, 0]]); 
        }
    }
}