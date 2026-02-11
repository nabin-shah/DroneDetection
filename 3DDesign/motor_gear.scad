// --- Gear Parameters ---
gear_height = 20;       // Length of the gear rod
number_of_teeth = 12;
outer_radius = 8;       // Total size of the gear
inner_radius = 6;       // Root of the teeth
$fn = 64;

// --- Motor Shaft Fit Parameters ---
shaft_dia = 5.2;        // 5mm shaft + 0.2mm tolerance for 3D printing
flat_depth = 0.5;       // How much the "D" cut takes off the radius
screw_hole_dia = 3.2;   // For an M3 set screw

// --- Final Assembly ---
difference() {
    // 1. The Gear Body
    linear_extrude(height = gear_height) {
        gear_profile(number_of_teeth, outer_radius, inner_radius, 0.6);
    }

    // 2. Subtract the "D-Shaft" Hole
    translate([0, 0, -1]) 
        d_shaft_hole(h = gear_height + 2);

    // 3. Subtract the Set-Screw Hole (positioned halfway up)
    translate([0, 0, gear_height / 2])
        rotate([0, 90, 0])
            cylinder(h = outer_radius + 1, r = screw_hole_dia / 2);
}

// --- Modules ---

module gear_profile(teeth, r_out, r_in, flat) {
    angle_step = 360 / teeth;
    points = [
        for (i = [0 : teeth - 1]) 
            each [
                [r_in * cos(i * angle_step - angle_step * flat/4), r_in * sin(i * angle_step - angle_step * flat/4)],
                [r_out * cos(i * angle_step - angle_step * flat/8), r_out * sin(i * angle_step - angle_step * flat/8)],
                [r_out * cos(i * angle_step + angle_step * flat/8), r_out * sin(i * angle_step + angle_step * flat/8)],
                [r_in * cos(i * angle_step + angle_step * flat/4), r_in * sin(i * angle_step + angle_step * flat/4)]
            ]
    ];
    polygon(points);
}

module d_shaft_hole(h) {
    intersection() {
        cylinder(h = h, r = shaft_dia / 2);
        // The "D" flat cut
        translate([-shaft_dia/2, -shaft_dia/2 + flat_depth, 0])
            cube([shaft_dia, shaft_dia, h]);
    }
}