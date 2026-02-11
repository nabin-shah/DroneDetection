// FILE: 05_Directional_Antenna_PCB_Standalone.scad
// Reference: Final PCB Design with 4.56" hole spacing.

$fn = 64;
mm = 25.4;

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
        // Mounting Holes (at X=12mm)
        translate([12, hole_dist/2, -1])  cylinder(h=pcb_thick + 5, d=hole_dia);
        translate([12, -hole_dist/2, -1]) cylinder(h=pcb_thick + 5, d=hole_dia);
    }
    // Copper Elements
    color("DarkSeaGreen") for (i = [0 : num_elements - 1]) {
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