// --- Arduino Uno R3 Dimensions ---
pcb_width = 68.6;
pcb_depth = 53.3;
pcb_thick = 1.6;

// Mounting Hole Positions (relative to bottom-left corner)
// Standard Arduino mounting hole coordinates
holes = [
    [14.0, 2.5],   // Near DC Jack
    [15.3, 50.8],  // Near USB
    [66.1, 7.6],   // Bottom Right
    [66.1, 35.6]   // Top Right
];

$fn = 32;

// --- Render ---
arduino_uno_r3();

module arduino_uno_r3() {
    color("DarkCyan") {
        difference() {
            // Main PCB body with slightly rounded corners
            hull() {
                translate([2, 2, 0]) cylinder(h=pcb_thick, r=2);
                translate([pcb_width-2, 2, 0]) cylinder(h=pcb_thick, r=2);
                translate([pcb_width-2, pcb_depth-2, 0]) cylinder(h=pcb_thick, r=2);
                translate([2, pcb_depth-2, 0]) cylinder(h=pcb_thick, r=2);
            }
            
            // Mounting Holes (3.2mm for M3 screws)
            for(h = holes) {
                translate([h[0], h[1], -1]) 
                    cylinder(h=pcb_thick+2, d=3.2);
            }
        }
    }

    // USB Port (Silver)
    color("Silver")
        translate([-6.5, pcb_depth - 18, pcb_thick]) 
            cube([16, 12, 11]);

    // DC Power Jack (Black)
    color("Black")
        translate([-2, 3, pcb_thick]) 
            cube([14, 9, 11]);

    // Header Pins (Black)
    color("DimGray") {
        translate([26, 2, pcb_thick]) cube([38, 2.5, 9]); // Bottom rail
        translate([26, pcb_depth - 4.5, pcb_thick]) cube([38, 2.5, 9]); // Top rail 1
        translate([16, pcb_depth - 4.5, pcb_thick]) cube([8, 2.5, 9]);  // Top rail 2
    }
}