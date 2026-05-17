// STANDALONE DRIVE GEAR 
// CALIBRATED FOR: NEMA 17 (17HE19-2004S) 
// TOLERANCE: +0.3mm for uncalibrated printers

$fn = 64;

// --- PARAMETERS ---
// dia: 5mm shaft + 0.3mm error + 0.1mm fit = 5.4mm
// d_offset: Calculated for 4.5mm flat thickness (5.4 - 4.5 = 0.9)
drive_gear(dia = 5.4, is_d = true, d_offset = 0.9);

module drive_gear(dia, is_d, d_offset) {
    difference() {
        // Gear Body
        linear_extrude(height = 15) gear_profile(36, 30, 27);
        
        // Internal Shaft Hole (D-cut)
        translate([0,0,-1]) {
            if(is_d) intersection() {
                cylinder(h=17, d=dia);
                // The D-cut creates the 4.5mm flat needed for the motor shaft
                translate([-dia/2, -dia/2 + d_offset, 0]) cube([dia, dia, 17]);
            } else {
                cylinder(h=17, d=dia);
            }
        }
        
        // Grub Screw Hole (Enlarged to 3.6mm for M3 screw fit)
        translate([0, 0, 7.5]) rotate([0, 90, 0]) cylinder(h=30, d=3.6);
    }
}

module gear_profile(teeth, r_out, r_in, flat=0.6) {
    angle_step = 360/teeth;
    points = [for (i = [0:teeth-1]) each [
        [r_in*cos(i*angle_step-angle_step*flat/4), r_in*sin(i*angle_step-angle_step*flat/4)],
        [r_out*cos(i*angle_step-angle_step*flat/8), r_out*sin(i*angle_step-angle_step*flat/8)],
        [r_out*cos(i*angle_step+angle_step*flat/8), r_out*sin(i*angle_step+angle_step*flat/8)],
        [r_in*cos(i*angle_step+angle_step*flat/4), r_in*sin(i*angle_step+angle_step*flat/4)]
    ]];
    polygon(points);
}