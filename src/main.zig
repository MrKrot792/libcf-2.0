const std = @import("std");
const lcf = @import("root.zig");
const rl = @import("raylib");

const state = bool;

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

const position: lcf.vec2 = .{0, 0};

pub fn main() !void {
    const allocator = std.heap.smp_allocator;
    rl.setConfigFlags(.{ .window_maximized = true });
    rl.initWindow(1920, 1080, "libCF test");

    // Cellular automaton initialization
    var grid: lcf.grid(.{480*2, 270*2}, state) = try .init(allocator, tick, drawAs, fill, .{1920, 1080});
    defer grid.deinit(allocator);
    // Filing the grid with a predefined function
    grid.fill(null);

    var frame: u64 = 0;
    rl.setTargetFPS(60);

    var timer: std.time.Timer = try .start();
    var frameTimer: std.time.Timer = try .start();

    var camera: rl.Camera2D = .{ .offset = .init(1920/2, 1080/2), .rotation = 0, .target = .init(0, 0), .zoom = 1 };

    const move_speed: f32 = 200;

    while (!rl.windowShouldClose()) {
        frameTimer.reset();
        if (rl.isKeyPressed(.r)) grid.fill(null);
        if (rl.isKeyDown(.left))  camera.target.x -= move_speed * rl.getFrameTime();
        if (rl.isKeyDown(.right)) camera.target.x += move_speed * rl.getFrameTime();
        if (rl.isKeyDown(.down))  camera.target.y += move_speed * rl.getFrameTime();
        if (rl.isKeyDown(.up))    camera.target.y -= move_speed * rl.getFrameTime();
        if (rl.isKeyDown(.a))     camera.zoom += camera.zoom / 5;
        if (rl.isKeyDown(.d))     camera.zoom -= camera.zoom / 5;

        std.debug.print("-----\nFrame: {d}\n", .{frame});

        std.debug.print("Ticking...\n", .{});
        timer.reset();
        try grid.tick(allocator);
        std.debug.print("Done ticking, took: {D}\n", .{timer.read()});

        std.debug.print("Rendering the grid...\n", .{});
        timer.reset();
        try grid.renderGrid();
        std.debug.print("Done rendering the grid, took: {D}\n", .{timer.read()});

        rl.beginDrawing();
            rl.beginMode2D(camera);
                rl.clearBackground(.black);
                std.debug.print("Drawing...\n", .{});
                timer.reset();
                try grid.draw(position);
                std.debug.print("Done drawing, took: {D}\n", .{timer.read()});
            rl.endMode2D();
            rl.drawFPS(0, 0);
        rl.endDrawing();
        frame += 1;

        std.debug.print("The whole frame took {D}.\n", .{frameTimer.lap()});
    }
}
