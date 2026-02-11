// FILE: 04_Drive_Gears_Independent.scad

$fn = 64;
mode = "motor"; // CHANGE TO "encoder" TO RENDER THE OTHER ONE

if (mode == "motor") drive_gear(dia = 5.03, is_d = false);
if (mode == "encoder") drive_gear(dia = 6.04, is_d = true);

module drive_gear(dia, is_d) {
    difference() {
        linear_extrude(height = 15) gear_profile(36, 30, 27);
        translate([0,0,-1]) {
            if(is_d) intersection() {
                cylinder(h=17, d=dia);
                translate([-dia/2, -dia/2 + 0.8, 0]) cube([dia, dia, 17]);
            } else cylinder(h=17, d=dia);
        }
        translate([0, 0, 7.5]) rotate([0, 90, 0]) cylinder(h=30, d=3.2);
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