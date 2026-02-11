// FILE: 02_Lid_Independent.scad

$fn = 64;
wall = 3;
box_w = 280; box_d = 160; corner_r = 5;
mech_center = [180, 80, wall];

union() {
    difference() {
        rounded_block(box_w, box_d, wall, corner_r);
        translate([mech_center[0], mech_center[1], -1]) cylinder(h=wall+2, d=10.5);
    }
    // Locking Inset Rim
    translate([wall + 0.5, wall + 0.5, -wall])
    difference() {
        rounded_block(box_w - wall*2 - 1, box_d - wall*2 - 1, wall, corner_r - 1.5);
        translate([2, 2, -1]) rounded_block(box_w - wall*2 - 5, box_d - wall*2 - 5, wall + 2, corner_r - 2);
        translate([mech_center[0]-50, mech_center[1]-50, -1]) cube([100, 100, wall+2]);
    }
    // Upper Bearing Hub
    translate([mech_center[0], mech_center[1], -5.2])
        difference() {
            cylinder(h=5.2, d=25);
            translate([0,0,-0.1]) cylinder(h=5.4, d=19.1);
        }
}

module rounded_block(w, d, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, d-r, 0]) cylinder(h=h, r=r);
        translate([r, d-r, 0]) cylinder(h=h, r=r);
    }
}