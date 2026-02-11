// FILE: 10_Final_Antenna_Mast_Fixed_Render.scad
// FIXED: Rendering issues resolved by simplifying the D-socket logic.

$fn = 64; 
mm = 25.4; 

// --- SHAFT & ANTENNA SPECS ---
gear_rod_dia  = 9.5;    // Matches your rod.scad [cite: 91, 100]
d_slice_depth = 1.5;    // Matches the 1.5mm slice in your rod [cite: 91, 100]
socket_depth  = 30;     // [cite: 100]
antenna_h     = 10.5 * mm; // [cite: 101]
hole_spacing  = 4.56 * mm; // [cite: 101]
hole_dia      = 0.15 * mm; // [cite: 102]

// --- GEOMETRY ---
main_rod_dia           = 20; // [cite: 103]
base_reinforcement_dia = 26; // [cite: 103]
horizontal_reach       = 65; // [cite: 104]
arm_height             = 30; // [cite: 104]
arm_width              = 10; // [cite: 105]
gusset_thick           = 6;  // [cite: 106]

// --- ARM SLIDE ADJUSTMENT ---
arm_slide_down = 45; 

// ============================================================
// RENDER
// ============================================================
union() {
    // 1. REINFORCED D-SOCKET BASE
    difference() {
        // Outer Body
        color("Gold") cylinder(h = socket_depth + 15, d = base_reinforcement_dia); // [cite: 107]
        
        // THE D-SOCKET BORE (Simplified logic for rendering)
        translate([0, 0, -1]) {
            difference() {
                // Main Hole
                cylinder(h = socket_depth + 2, d = gear_rod_dia + 0.3); // [cite: 108]
                
                // The D-flat "Wall" 
                // We place a block inside the cylinder to create the flat side
                translate([gear_rod_dia/2 - d_slice_depth, -gear_rod_dia, 0])
                    cube([gear_rod_dia, gear_rod_dia*2, socket_depth + 5]); // [cite: 109]
            }
        }
        
        // Set-screw hole
        translate([0, 0, socket_depth / 2]) rotate([0, 90, 0]) 
            cylinder(h = base_reinforcement_dia + 2, d = 3.6, center=true); // 
    }

    // 2. THE MAIN VERTICAL MAST
    color("Gold") translate([0, 0, socket_depth + 15])
        cylinder(h = antenna_h - (socket_depth + 15), d = main_rod_dia); // [cite: 111]
    
    // Conical transition
    color("Gold") translate([0, 0, socket_depth + 15])
        mirror([0,0,1]) cylinder(h=15, d1=base_reinforcement_dia, d2=main_rod_dia); // [cite: 112]

    // 3. THE TWO REINFORCED FIN ARMS
    // Adjusted loop to ensure arms and antenna holes move together [cite: 113]
    for (z_pos = [antenna_h - hole_spacing - arm_slide_down, antenna_h - arm_slide_down]) { 
        translate([0, 0, z_pos - arm_height/2]) {
            
            // THE HORIZONTAL ARM
            color("Gold") difference() {
                translate([-arm_width/2, 0, 0]) 
                    cube([arm_width, horizontal_reach + 10, arm_height]); // [cite: 114]
                
                // Horizontal Mounting Hole
                translate([-arm_width/2 - 1, horizontal_reach, arm_height/2])
                    rotate([0, 90, 0]) 
                        cylinder(h = arm_width + 2, d = hole_dia); // [cite: 115]
            }
            
            // THE CENTERED MIRRORED SUPPORT GUSSET
            color("Red") 
            translate([-gusset_thick/2, 1, 0]) // [cite: 116]
            rotate([90, 0, 90]) 
            linear_extrude(gusset_thick)
            polygon([[0, 0], [0, -35], [horizontal_reach - 5, 0]]); // [cite: 117]
        }
    }
}