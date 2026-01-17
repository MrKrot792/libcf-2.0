const std = @import("std");
const rl = @import("raylib");

pub const vec2 = [2]i32;

const square: type = struct {
    position: vec2,
    dimensions: vec2,
};

/// Grid size must be divisible by the rendered texture size
pub fn grid(comptime grid_size: vec2, comptime cell_type: type) type {
    return struct {
        /// Pointer to the grid of cells
        data: []cell_type,
        /// Hidden data pointer, we write to it and then we swap the `data` and `dataBack`
        dataBack: []cell_type,

        /// For internal use only.
        tickFn: *const fn ([9]?cell_type) cell_type,
        /// For internal use only.
        drawFn: *const fn (cell_type) rl.Color,
        /// For internal use only.
        fillFn: *const fn (vec2, std.Random) cell_type,

        /// Size of the whole texture
        textureSize: vec2,
        /// The grid texture
        texture: rl.Texture,

        /// CPU image, we first draw pixels to it, then turn it to a texture, then draw the texture
        image: rl.Image,
        
        /// You always gotta call `deinit()` when you stop using this lib.
        /// BTW, fourth element of the first argument in `tickFn` is always available (.? is always safe to use)
        pub fn init(
            allocator: std.mem.Allocator,
            tickFn: *const fn ([9]?cell_type) cell_type,
            drawFn: *const fn (cell_type) rl.Color,
            fillFn: *const fn (vec2, std.Random) cell_type,
            size: vec2,
        ) !@This() {
            var result: @This() = .{ 
                .data = try allocator.alloc(cell_type, grid_size[0] * grid_size[1]),
                .dataBack = try allocator.alloc(cell_type, grid_size[0] * grid_size[1]),
                .tickFn = tickFn, .drawFn = drawFn, .fillFn = fillFn,
                .textureSize = size,
                .texture = undefined,
                .image = .genColor(size[0], size[1], .black),
            };

            result.texture = try .fromImage(result.image);

            return result;
        }

        /// The new size should be divisible by grid_size. If it's not, it'll look ugly.
        pub fn resize(this: *@This(), new_size: vec2) !void {
            this.texture.unload();
            this.texture = try rl.loadRenderTexture(new_size[0], new_size[1]);
            this.textureSize = new_size;
        }

        /// Call this after using the object
        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(this.data);
            allocator.free(this.dataBack);
            this.texture.unload();
            this.image.unload();
        }

        /// You must render the grid before drawing it inside `rl.beginDrawing`
        pub fn renderGrid(this: *@This()) !void {
            var timer: std.time.Timer = try .start();

            const square_size_x = @divFloor(this.textureSize[0], grid_size[0]);
            const square_size_y = @divFloor(this.textureSize[1], grid_size[1]);
            std.debug.print("   Other things took: {D}\n", .{timer.lap()});

            timer.reset();
            for (0..grid_size[1]) |y_u| {
                for (0..grid_size[0]) |x_u| {
                    const y: i32 = @intCast(y_u);
                    const x: i32 = @intCast(x_u);
                    // Current cell
                    this.image.drawRectangle(
                        square_size_x * x,  // Position X
                        square_size_y * y,  // Position Y
                        square_size_x, // Width 
                        square_size_y, // Height
                        this.drawFn(this.data[y_u * @as(usize, grid_size[0]) + x_u])   // Color (we get it from a user-defined function)
                    );
                }
            }
            std.debug.print("   Rendering took: {D}.\n", .{timer.lap()});

            timer.reset();
            rl.updateTexture(this.texture, this.image.data);
            std.debug.print("   Sending rendered texture to GPU took: {D}\n", .{timer.lap()});
        }

        /// Call this _INSIDE_ `rl.beginDrawing`.
        pub fn draw(this: *@This(), position: vec2) !void {
            std.debug.print("Drawing texture!\n", .{}); 
            this.texture.draw(position[0], position[1], .white); 
        }

        /// This function is really heavy.
        pub fn tick(this: *@This()) !void {
            for (0..grid_size[1]) |y| {
                for (0..grid_size[0]) |x| {
                    var current_neihbors: [9]?cell_type = @splat(null);

                    var count: u32 = 0;
                    inline for ([_]i32{-1, 0, 1}) |i| {
                        inline for ([_]i32{-1, 0, 1}) |j| {
                            current_neihbors[count] = this.getAt(@as(i32, @intCast(x)) + i, @as(i32, @intCast(y)) + j);
                            count += 1;
                        }
                    }

                    this.dataBack[y * grid_size[0] + x] = this.tickFn(current_neihbors);
                }
            }

            @memmove(this.data, this.dataBack);
        }

        /// Call this before the main loop, as it sets all the pixel
        /// This function is using DefaultPrng, you can set the seed if you want to, but `null` defaults to time based seed.
        pub fn fill(this: *@This(), seed: ?u64) void {
            var random = std.Random.DefaultPrng.init(seed orelse @bitCast(std.time.microTimestamp()));
            for (0..grid_size[1]) |y| {
                for (0..grid_size[0]) |x| {
                    this.setAt(@intCast(x), @intCast(y), this.fillFn(.{@intCast(x), @intCast(y)}, random.random()));
                }
            }
        }

        inline fn getAt(this: @This(), x: i32, y: i32) cell_type {
            return this.data[@intCast((@mod(y, grid_size[1])) * grid_size[0] + (@mod(x, grid_size[0])))];
        }
        
        inline fn setAt(this: @This(), x: i32, y: i32, new: cell_type) void {
            this.data[@intCast((@mod(y, grid_size[1])) * grid_size[0] + (@mod(x, grid_size[0])))] = new;
        }
    };
}
