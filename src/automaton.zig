const std = @import("std");
const rl = @import("raylib");
const lcf = @import("lcf");

pub const state = bool;

pub fn tick(previous: [9]?state) state {
    var neighbors: u32 = 0;

    for (previous) |value| { 
        if( value orelse false ) neighbors += 1; 
    }

    if (neighbors == 0) return false;

    if (previous[4].?) neighbors -= 1;

    if (previous[4].?) {
        return (neighbors == 2 or neighbors == 3);
    } else {
        return neighbors == 3;
    }
}

pub fn drawAs(cell: state) rl.Color {
    if (cell) return rl.Color.red
    else return rl.Color.black;
}

pub fn fill(pos: lcf.vec2, random: std.Random) state {
    _ = pos;
    return random.boolean();
}
