// FILE: Antenna_Mast_With_Top_Key_V9.2.scad
// UPDATED: Added an explicit 0.2mm clearance to the internal socket hole for an easy slide-fit.
// COMPATIBILITY: Links perfectly with your 9.1mm top gear rod section.

$fn = 64; 
mm = 25.4; 

// --- SHAFT & ANTENNA SPECS ---
gear_rod_dia   = 9.1;    // The physical rod diameter it mates with
hole_clearance = 0.2;    // NEW: 0.2mm slip-fit clearance added to the hole diameter
d_slice_depth  = 1.3;    // Maintains the flat interface wall at exactly 3.25mm from center
socket_depth   = 30;     
antenna_h      = 10.5 * mm; 
hole_spacing   = 4.56 * mm; 
hole_dia       = 3.6;    // Sized for standard nominal M3 hardware

// --- GEOMETRY ---
main_rod_dia           = 20; 
base_reinforcement_dia = 26; 
horizontal_reach       = 65; 
arm_height             = 30; 
arm_width              = 10; 
gusset_thick           = 6; 

// --- TOP D-CUT SPECS ---
top_dcut_depth = 3;   // Matches the 3mm flat in the webcam topper
top_dcut_h     = 30;  // Length of the flat at the tip

// --- ARM SLIDE ADJUSTMENT ---
arm_slide_down = 45; 

// ============================================================
// RENDER
// ============================================================
union() {
    // 1. REINFORCED D-SOCKET BASE (Females onto the 9.1mm Gear Rod)
    difference() {
        color("Gold") cylinder(h = socket_depth + 15, d = base_reinforcement_dia); 
        translate([0, 0, -1]) {
            difference() {
                // Main round hole with explicit 0.2mm clearance (Total 9.3mm diameter)
                cylinder(h = socket_depth + 2, d = gear_rod_dia + hole_clearance);
                
                // The D-flat internal mating wall
                translate([gear_rod_dia/2 - d_slice_depth, -gear_rod_dia - 1, 0])
                    cube([gear_rod_dia + 2, (gear_rod_dia * 2) + 2, socket_depth + 5]); 
            }
        }
        // Cross-bolt safety hole
        translate([0, 0, socket_depth / 2]) rotate([0, 90, 0]) 
            cylinder(h = base_reinforcement_dia + 2, d = 3.6, center=true); 
    }

    // 2. THE MAIN VERTICAL MAST (With Top D-Cut)
    color("Gold") translate([0, 0, socket_depth + 15]) {
        difference() {
            cylinder(h = antenna_h - (socket_depth + 15), d = main_rod_dia); 
            
            // THE TOP D-CUT FLAT (For Webcam Topper)
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