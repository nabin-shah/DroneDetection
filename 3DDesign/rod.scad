// FILE: 03_Gear_Rod_D_Cut_V8.4.scad
// UPDATED: Extended to 140mm with 30mm D-cut for mast engagement.

$fn = 64;
h = 140;        // INCREASED from 110 to allow mast to seat above lid
th = 80;        // Gear teeth height stays at 80
d_cut_h = 30;   // INCREASED to 30 to match mast socket depth
rod_dia = 9.5;

// 1. Bottom Bearing Pin
translate([0, 0, -4.5]) cylinder(h = 5, d = rod_dia - 0.1);

// 2. Gear Teeth (12 teeth)
linear_extrude(height = th) gear_profile(12, 8, 6);

// 3. Top Pin (Transition to D-cut)
translate([0, 0, th]) {
    difference() {
        cylinder(h = h - th + 5, d = rod_dia - 0.1);
        // The D-cut: Matched to the mast's internal flat wall
        translate([rod_dia/2 - 1.5, -5, h - th - d_cut_h + 5]) 
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