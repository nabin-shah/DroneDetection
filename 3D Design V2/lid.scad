// FILE: Calibrated_Lid_V11.9.scad
// UPDATED: Width = 270mm, Mech_Center = 175
// TOLERANCE: Bearing hub adjusted for 0.3mm shrink.

$fn = 64;
wall = 3;
box_w = 270; // UPDATED: Matches 27cm Chassis
box_d = 160; 
corner_r = 5;
mech_center = [175, 80, wall]; // UPDATED: Re-aligned to center

union() {
    // 1. MAIN LID SURFACE
    difference() {
        color("Ivory", 0.8) rounded_block(box_w, box_d, wall, corner_r);
        // Central hole for the antenna mast shaft
        translate([mech_center[0], mech_center[1], -1]) cylinder(h=wall+2, d=10.5);
    }

    // 2. LOCKING INSET RIM
    // This rim drops into the box to prevent the lid from sliding.
    // 0.5mm clearance added to the perimeter for easier fit.
    translate([wall + 0.5, wall + 0.5, -wall])
    difference() {
        rounded_block(box_w - wall*2 - 1, box_d - wall*2 - 1, wall, corner_r - 1.5);
        translate([2, 2, -1]) rounded_block(box_w - wall*2 - 5, box_d - wall*2 - 5, wall + 2, corner_r - 2);
        // Clearance for the central mechanical zone
        translate([mech_center[0]-50, mech_center[1]-50, -1]) cube([100, 100, wall+2]);
    }

    // 3. UPPER BEARING HUB
    // Seated against the lid to support the top of the rotating rod.
    translate([mech_center[0], mech_center[1], -5.2])
        difference() {
            cylinder(h=5.2, d=25);
            // CALIBRATED: 19.3mm for a 19mm bearing
            translate([0,0,-0.1]) cylinder(h=5.4, d=19.3); 
        }
}

// --- UTILITIES ---
module rounded_block(w, d, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, r, 0]) cylinder(h=h, r=r);
        translate([w-r, d-r, 0]) cylinder(h=h, r=r);
        translate([r, d-r, 0]) cylinder(h=h, r=r);
    }
}