// FILE: 24_Webcam_Cage_Keyed_D_Socket.scad
// Sized for: Large webcams (up to 11cm wide)
// KEYED: Added internal D-Socket to match the 20mm Mast D-cut.
// FEATURES: 50mm walls, 75% roof, Drop-in wire channel.

$fn = 64;
mm = 25.4;

// --- DIMENSIONS ---
mast_dia       = 20;      
socket_depth   = 35;      
clearance_h    = 3.5 * mm; // Shortened slightly per previous request for better proportions

// --- BALCONY/BOX SPECS ---
balcony_w    = 110;       
balcony_d    = 55;        
wall_h       = 50;        
wall_t       = 4;         
floor_t      = 6;         

// --- ROOF & CHANNEL SPECS ---
roof_coverage = 0.75;     
channel_w     = 20;       

// ============================================================
// RENDER
// ============================================================
union() {
    // 1. THE KEYED MAST SOCKET (Females onto 20mm Mast)
    difference() {
        color("Gold") cylinder(h = socket_depth, d = mast_dia + 10);
        
        // Internal D-Hole Logic
        translate([0, 0, -1]) {
            difference() {
                // Round hole with 0.4mm tolerance
                cylinder(h = socket_depth + 2, d = mast_dia + 0.4);
                
                // The D-Flat "Wall"
                // Matches a 3mm cut on the 20mm mast (10mm radius - 3mm = 7mm from center)
                translate([mast_dia/2 - 3, -mast_dia, 0]) 
                    cube([10, mast_dia*2, socket_depth + 5]);
            }
        }
        
        // M4 Set-screw hole for absolute safety
        translate([0, 0, socket_depth / 2]) rotate([0, 90, 0]) 
            cylinder(h = mast_dia + 20, d = 4.2, center=true);
    }

    // 2. THE EXTENSION STEM
    color("Gold") translate([0, 0, socket_depth]) {
        cylinder(h = clearance_h, d = mast_dia);
        
        // CABLE TIE HUB (On the back)
        translate([0, -mast_dia/2, clearance_h/2]) {
            difference() {
                color("Silver") cube([12, 8, 15], center=true);
                cube([8, 12, 4], center=true);
            }
        }
    }

    // 3. THE DEEP CAMERA CAGE
    translate([0, 0, socket_depth + clearance_h]) {
        union() {
            // FLOOR
            color("Silver") translate([-balcony_w/2 - wall_t, 0, 0]) 
                cube([balcony_w + (wall_t*2), balcony_d + wall_t, floor_t]);
            
            // WALLS & ROOF
            color("DimGray") translate([0, 0, floor_t]) {
                difference() {
                    union() {
                        // Back Wall
                        translate([-balcony_w/2 - wall_t, 0, 0]) 
                            cube([balcony_w + (wall_t*2), wall_t, wall_h]);
                        // Left Wall
                        translate([-balcony_w/2 - wall_t, 0, 0]) 
                            cube([wall_t, balcony_d + wall_t, wall_h]);
                        // Right Wall
                        translate([balcony_w/2, 0, 0]) 
                            cube([wall_t, balcony_d + wall_t, wall_h]);
                        
                        // THE ROOF (75% Coverage)
                        translate([-balcony_w/2 - wall_t, 0, wall_h])
                            cube([balcony_w + (wall_t*2), balcony_d * roof_coverage, wall_t]);
                    }
                    
                    // THE U-CHANNEL (Drops through back wall and roof)
                    translate([-channel_w/2, -1, -1]) 
                        cube([channel_w, balcony_d + 2, wall_h + wall_t + 2]);
                }
            }

            // --- REINFORCEMENT GUSSETS (Fused to Rod) ---
            for(x_pos = [-8, 2]) { 
                translate([x_pos, 2, 0]) 
                rotate([90, 0, 90]) 
                linear_extrude(6)
                polygon([
                    [0, 0],             
                    [0, -45],           
                    [balcony_d - 5, 0]  
                ]);
            }
        }
    }
}