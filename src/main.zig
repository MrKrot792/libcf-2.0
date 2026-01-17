const std = @import("std");
const lcf = @import("root.zig");
const rl = @import("raylib");

const state = bool;

pub fn tick(previous: [9]?state) state {
    var neighbors: u32 = 0;

    for (previous) |value| { 
        if( value orelse false ) neighbors += 1; 
    }

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

pub fn main() !void {
    const allocator = std.heap.smp_allocator;
    rl.initWindow(800, 800, "libCF test");

    // Cellular automaton initialization
    var grid: lcf.grid(.{400, 400}, state) = try .init(allocator, tick, drawAs, .{800, 800});
    defer grid.deinit(allocator);

    // Filling the grid with random values
    var random = std.Random.DefaultPrng.init(@bitCast(std.time.microTimestamp()));
    for (grid.data) |*value| { value.* = random.random().boolean(); }

    var frame: u64 = 0;
    rl.setTargetFPS(60);

    const position: lcf.vec2 = .{0, 0};

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.r)) { for (grid.data) |*value| { value.* = random.random().boolean(); } }
        //if (rl.isWindowResized()) try grid.resize(.{rl.getRenderWidth(), rl.getRenderHeight()});

        try grid.tick(allocator);
        try grid.renderGrid(position);

        rl.beginDrawing();
        rl.clearBackground(.ray_white);
        std.debug.print("Ticking... x{d}\n", .{frame});

        try grid.draw(position);

        rl.drawFPS(0, 0);
        rl.endDrawing();

        frame += 1;
    }
}
