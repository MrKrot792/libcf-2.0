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

const position: lcf.vec2 = .{0, 0};

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

    var timer: std.time.Timer = try .start();
    var frameTimer: std.time.Timer = try .start();

    while (!rl.windowShouldClose()) {
        frameTimer.reset();
        if (rl.isKeyPressed(.r)) { for (grid.data) |*value| { value.* = random.random().boolean(); } }
        //if (rl.isWindowResized()) try grid.resize(.{rl.getRenderWidth(), rl.getRenderHeight()});

        std.debug.print("-----\nFrame: {d}\n", .{frame});

        std.debug.print("Ticking...\n", .{});
        timer.reset();
        try grid.tick(allocator);
        std.debug.print("Done ticking, took: {D}\n", .{timer.read()});

        std.debug.print("Rendering the grid...\n", .{});
        timer.reset();
        try grid.renderGrid(position);
        std.debug.print("Done rendering the grid, took: {D}\n", .{timer.read()});

        rl.beginDrawing();
        rl.clearBackground(.ray_white);

            std.debug.print("Drawing...\n", .{});
            timer.reset();
            try grid.draw(position);
            std.debug.print("Done drawing, took: {D}\n", .{timer.read()});

        rl.drawFPS(0, 0);
        rl.endDrawing();
        frame += 1;

        std.debug.print("The whole frame took {D}.\n", .{frameTimer.lap()});
    }
}
