const std = @import("std");
const lcf = @import("root.zig");
const rl = @import("raylib");
const at = @import("automaton.zig");

const position: lcf.vec2 = .{0, 0};

const shouldUseCamera: bool = false;

pub fn main() !void {
    const allocator = std.heap.smp_allocator;
    rl.setConfigFlags(.{ .window_maximized = true });
    rl.initWindow(1920, 1080, "libCF test");

    // Cellular automaton initialization
    var grid: lcf.grid(.{480, 270}, at.state) = try .init(allocator, at.tick, at.drawAs, at.fill, .{1920, 1080});
    defer grid.deinit(allocator);
    // Filing the grid with a predefined function
    grid.fill(null);

    var frame: u64 = 0;
    rl.setTargetFPS(60);

    var timer: std.time.Timer = try .start();
    var frameTimer: std.time.Timer = try .start();

    var camera: rl.Camera2D = undefined;

    if (shouldUseCamera) {
        camera = .{ .offset = .init(1920/2, 1080/2), .rotation = 0, .target = .init(0, 0), .zoom = 1 };
    }

    const move_speed: f32 = 200;

    while (!rl.windowShouldClose()) {
        frameTimer.reset();
        if (rl.isKeyPressed(.r))  grid.fill(null);
        if (shouldUseCamera) {
            if (rl.isKeyDown(.left))  camera.target.x -= move_speed / camera.zoom * rl.getFrameTime();
            if (rl.isKeyDown(.right)) camera.target.x += move_speed / camera.zoom * rl.getFrameTime();
            if (rl.isKeyDown(.down))  camera.target.y += move_speed / camera.zoom * rl.getFrameTime();
            if (rl.isKeyDown(.up))    camera.target.y -= move_speed / camera.zoom * rl.getFrameTime();
            if (rl.isKeyDown(.a))     camera.zoom += camera.zoom / 5;
            if (rl.isKeyDown(.d))     camera.zoom -= camera.zoom / 5;
        }

        std.debug.print("-----\nFrame: {d}\n", .{frame});

        std.debug.print("Ticking...\n", .{});
        timer.reset();
        try grid.tick();
        std.debug.print("Done ticking, took: {D}\n", .{timer.read()});

        std.debug.print("Rendering the grid...\n", .{});
        timer.reset();
        try grid.renderGrid();
        std.debug.print("Done rendering the grid, took: {D}\n", .{timer.read()});

        rl.beginDrawing();
            if(shouldUseCamera) {
            rl.beginMode2D(camera);
            }
                rl.clearBackground(.black);
                std.debug.print("Drawing...\n", .{});
                timer.reset();
                try grid.draw(position);
                std.debug.print("Done drawing, took: {D}\n", .{timer.read()});
            if(shouldUseCamera) {
            rl.endMode2D();
            }
            rl.drawFPS(0, 0);
        rl.endDrawing();
        frame += 1;

        std.debug.print("The whole frame took {D}.\n", .{frameTimer.lap()});
    }
}
