// FILE: 03_Gear_Rod_D_Cut_V8.5.scad
// UPDATED: Calibrated bearing pins for 0.3mm printer error.
// COMPATIBILITY: V11.9 Chassis & Lid.

$fn = 64;
h = 140;        // Total height
th = 80;        // Gear teeth height
d_cut_h = 30;   // Mast engagement depth
rod_dia = 9.5;
pin_dia = 9.2;  // CALIBRATED: Adjusted from 9.4 to 9.2 for 10mm bearing ID

// 1. Bottom Bearing Pin (Fits into Chassis Podium)
translate([0, 0, -4.5]) cylinder(h = 5, d = pin_dia);

// 2. Gear Teeth (12 teeth)
linear_extrude(height = th) gear_profile(12, 8, 6);

// 3. Top Section (Lid bearing interface and D-cut)
translate([0, 0, th]) {
    difference() {
        // This cylinder passes through the Lid bearing
        cylinder(h = h - th + 5, d = pin_dia);
        
        // The D-cut: Standard flat for mast orientation
        translate([pin_dia/2 - 1.5, -5, h - th - d_cut_h + 5]) 
            cube([5, 10, d_cut_h + 1]);
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