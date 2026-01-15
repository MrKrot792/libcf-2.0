const std = @import("std");
const lcf = @import("root.zig");
const rl = @import("raylib");

// Conway's game of life:
// const state = bool;
//
// pub fn tick(previous: [9]?state) state {
//     var neighbors: u32 = 0;
//
//     for (previous) |value| { 
//         if( value orelse false ) neighbors += 1; 
//     }
//
//     if (previous[4].?) neighbors -= 1;
//
//     if (previous[4].?) {
//         return (neighbors == 2 or neighbors == 3);
//     } else {
//         return neighbors == 3;
//     }
// }
//
// pub fn drawAs(cell: state) rl.Color {
//     if (cell) return rl.Color.red
//     else return rl.Color.black;
// }

const state = u8;

pub fn tick(previous: [9]?state) state {
    var sum: u32 = 0;

    for (previous) |value| sum += value orelse previous[4].?;

    const avg: u8 = @intCast(sum / 9);
    var new_val: i16 = @as(i16, @intCast(avg)) + 5 - (@rem(@as(i16, @intCast(avg)), 10));
    if (new_val < 0) new_val = 0;
    if (new_val > 255) new_val = 255;

    var random = std.Random.DefaultPrng.init(@bitCast(std.time.microTimestamp()));
    if (random.random().float(f32) > 0.995) new_val = 255;
    if (random.random().float(f32) > 0.995) new_val = 0;

    return @intCast(new_val);
}

pub fn drawAs(cell: state) rl.Color {
    return .init(
        cell, 255 - cell, cell / 2, 255,
    );
}

pub fn main() !void {

    const allocator = std.heap.smp_allocator;
    rl.initWindow(800, 800, "libCF test");

    // Cellular automaton initialization
    var grid: lcf.grid(.{100, 100}, state) = try .init(allocator, tick, drawAs);
    defer grid.deinit(allocator);

    // Filling the grid with random values
    var random = std.Random.DefaultPrng.init(@bitCast(std.time.microTimestamp()));
    for (grid.data) |*value| { value.* = random.random().int(u8); }

    var frame: u64 = 0;
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(.ray_white);

        std.debug.print("Ticking... x{d}\n", .{frame});
        
        try grid.tick(allocator); 

        grid.draw(.{ 
            .position = .{0, 0}, 
            .dimensions = .{800, 800}
        });

        rl.drawFPS(0, 0);

        if (rl.isKeyPressed(.r)) { for (grid.data) |*value| { value.* = random.random().int(u8); } }

        rl.endDrawing();

        frame += 1;
    }
}
