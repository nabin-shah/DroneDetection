// ===============================
// Parametric Electronics Enclosure
// Base + Lid, with Arduino Uno mounts
// Units: millimeters
// ===============================

// --------- Global quality ----------
$fn = 64;

// --------- Main box dimensions ----------
outer_x = 120;
outer_y = 100;
outer_z = 40;

wall    = 3.5;   // 3–4mm recommended
floor_t = 3.5;

// Lid
lid_thickness   = 9;     // 8–10mm
lid_rim_depth   = 4;     // 3–5mm
lid_clearance   = 0.4;   // 0.3–0.5mm fit clearance

// --------- Arduino Uno mounting ----------
standoff_d = 6;
standoff_h = 7;          // 5–8mm
m3_hole_d  = 3.0;        // 2.5–3.0mm depending on printer

// Arduino mounting hole coordinates (from one corner of the Arduino PCB reference)
// User-provided typical: (14,2.5), (66,7.6), (66,35.6), (15.2,50.8)
arduino_holes = [
  [14.0,  2.5],
  [66.0,  7.6],
  [66.0, 35.6],
  [15.2, 50.8]
];

// Place Arduino inside box: offset from inner corner (bottom-left inside)
arduino_offset_x = 10;
arduino_offset_y = 10;

// --------- Cutouts (edit as needed) ----------
// USB cutout (rectangular) on side wall
usb_w = 12;
usb_h = 12;
usb_wall = "x-"; // "x-", "x+", "y-", "y+"
usb_center_from_bottom = 14; // height from bottom
usb_center_along_edge  = 35; // position along the edge

// Power cable hole (circular)
pwr_d = 8;             // cable diameter + ~2mm
pwr_wall = "y-";
pwr_center_from_bottom = 14;
pwr_center_along_edge  = 40;

// Motor shaft exit (circular)
shaft_d = 10;          // shaft + clearance
shaft_wall = "x+";
shaft_center_from_bottom = 22;
shaft_center_along_edge  = 50;

// Vent holes pattern (on top face of base)
vent_d = 5;
vent_rows = 2;
vent_cols = 6;
vent_spacing = 10;
vent_margin_x = 25;
vent_margin_y = 25;

// --------- Derived ----------
inner_x = outer_x - 2*wall;
inner_y = outer_y - 2*wall;
inner_z = outer_z - floor_t;

// ----------------- Helpers -----------------
module hollow_box_base() {
  difference() {
    // Outer solid
    cube([outer_x, outer_y, outer_z], center=false);

    // Hollow interior (leave floor thickness)
    translate([wall, wall, floor_t])
      cube([inner_x, inner_y, outer_z], center=false);
  }
}

module standoff_with_hole(px, py) {
  // standoff body
  translate([px, py, floor_t])
    cylinder(d=standoff_d, h=standoff_h, center=false);

  // screw hole
  translate([px, py, floor_t - 0.1])
    cylinder(d=m3_hole_d, h=standoff_h + 1 + 0.2, center=false);
}

module add_arduino_standoffs() {
  // Place all standoffs relative to the inner corner (wall,wall)
  for (p = arduino_holes) {
    standoff_with_hole(
      wall + arduino_offset_x + p[0],
      wall + arduino_offset_y + p[1]
    );
  }
}

module wall_rect_cutout(which, w, h, zc, along) {
  // Cuts a rectangle through a wall
  // which: "x-", "x+", "y-", "y+"
  depth = wall + 1; // ensure it passes fully through wall

  if (which == "x-") {
    translate([-0.5, along - w/2, zc - h/2])
      cube([depth, w, h], center=false);
  } else if (which == "x+") {
    translate([outer_x - depth + 0.5, along - w/2, zc - h/2])
      cube([depth, w, h], center=false);
  } else if (which == "y-") {
    translate([along - w/2, -0.5, zc - h/2])
      cube([w, depth, h], center=false);
  } else if (which == "y+") {
    translate([along - w/2, outer_y - depth + 0.5, zc - h/2])
      cube([w, depth, h], center=false);
  }
}

module wall_round_cutout(which, d, zc, along) {
  depth = wall + 1;

  if (which == "x-") {
    translate([-0.5, along, zc])
      rotate([0,90,0]) cylinder(d=d, h=depth, center=false);
  } else if (which == "x+") {
    translate([outer_x - depth + 0.5, along, zc])
      rotate([0,90,0]) cylinder(d=d, h=depth, center=false);
  } else if (which == "y-") {
    translate([along, -0.5, zc])
      rotate([90,0,0]) cylinder(d=d, h=depth, center=false);
  } else if (which == "y+") {
    translate([along, outer_y - depth + 0.5, zc])
      rotate([90,0,0]) cylinder(d=d, h=depth, center=false);
  }
}

module vent_holes_top() {
  // Vent holes through the "ceiling" of base box (top face)
  // We'll cut them near the top surface but stop before open? Actually base is open at top.
  // So vent holes are better on side walls; but if you add a lid, vents on lid are common.
  // Here we place vents on side wall y+ by default? We'll instead place vents on x- wall as slots?
  // To keep simple: Put vents on y+ wall.
  for (r=[0:vent_rows-1])
    for (c=[0:vent_cols-1]) {
      x = vent_margin_x + c*vent_spacing;
      z = 12 + r*vent_spacing;
      wall_round_cutout("y+", vent_d, z, x);
    }
}

// ----------------- Base assembly -----------------
module base() {
  difference() {
    union() {
      hollow_box_base();
      add_arduino_standoffs();
      // You can add motor mount geometry here later (platform/clamp)
    }

    // Cutouts
    wall_rect_cutout(usb_wall, usb_w, usb_h, usb_center_from_bottom, usb_center_along_edge);
    wall_round_cutout(pwr_wall, pwr_d, pwr_center_from_bottom, pwr_center_along_edge);
    wall_round_cutout(shaft_wall, shaft_d, shaft_center_from_bottom, shaft_center_along_edge);

    // Vents
    vent_holes_top();
  }
}

// ----------------- Lid -----------------
module lid() {
  // Lid plate sits on top of box opening and has a rim that slides inside
  // Outer footprint matches outer_x/outer_y. Rim fits inner opening minus clearance.

  rim_x = inner_x - 2*lid_clearance;
  rim_y = inner_y - 2*lid_clearance;

  difference() {
    union() {
      // main lid plate
      cube([outer_x, outer_y, lid_thickness], center=false);

      // inner rim (ledge)
      translate([wall + lid_clearance, wall + lid_clearance, 0])
        cube([rim_x, rim_y, lid_rim_depth], center=false);
    }

    // Optional: add vents in lid instead (uncomment if preferred)
    // for (r=[0:1]) for (c=[0:5]) {
    //   translate([30 + c*12, 30 + r*12, -0.5])
    //     cylinder(d=5, h=lid_thickness+1, center=false);
    // }
  }
}

// ----------------- Render selection -----------------
show = "base"; // "base" or "lid" or "both"

// Put lid next to base if "both"
if (show == "base") {
  base();
} else if (show == "lid") {
  lid();
} else {
  base();
  translate([outer_x + 15, 0, 0]) lid();
}
