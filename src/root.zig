const std = @import("std");
const rl = @import("raylib");

const vec2 = [2]i32;

const square: type = struct {
    position: vec2,
    dimensions: vec2,
};

pub fn grid(comptime grid_size: vec2, comptime cell_type: type) type {
    return struct {
        /// Pointer to the grid of cells
        data: []cell_type,

        /// For internal use only.
        tickFn: *const fn ([9]?cell_type) cell_type,
        /// For internal use only.
        drawFn: *const fn (cell_type) rl.Color,
        
        /// You always gotta call `deinit()`.
        /// BTW, fourth element of the first argument in `tickFn` is always available (.? is always safe to use)
        pub fn init(
            allocator: std.mem.Allocator,
            tickFn: *const fn ([9]?cell_type) cell_type,
            drawFn: *const fn (cell_type) rl.Color
        ) !@This() {
            return .{ 
                .data = try allocator.alloc(cell_type, grid_size[0] * grid_size[1]),
                .tickFn = tickFn, .drawFn = drawFn
            };
        }

        /// Call this after using the object
        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(this.data);
        }

        /// You gotta call ts in a loop btw
        /// BTW, `where.dimensions` is absolute 
        pub fn draw(this: @This(), where: square) void {
            for (0..grid_size[1]) |y_u| {
                for (0..grid_size[0]) |x_u| {
                    const y: i32 = @intCast(y_u);
                    const x: i32 = @intCast(x_u);
                    
                    const square_size_x = @divFloor(where.dimensions[0], grid_size[0]);
                    const square_size_y = @divFloor(where.dimensions[1], grid_size[1]);
                    
                    // Current cell
                    rl.drawRectangle(
                        where.position[0] + square_size_x * x,  // Position X
                        where.position[1] + square_size_y * y,  // Position Y
                        square_size_x, // Width
                        square_size_y, // Height
                        this.drawFn(this.data[y_u * @as(usize, grid_size[0]) + x_u])   // Color (we get it from a user-defined function)
                    );
                }
            }
        }

        /// Hopefully this works 🙏
        pub fn tick(this: *@This(), allocator: std.mem.Allocator) !void {
            var data: []cell_type = try allocator.alloc(cell_type, grid_size[0] * grid_size[1]);
            defer allocator.free(data);

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

                    data[y * grid_size[0] + x] = this.tickFn(current_neihbors);
                }
            }

            @memmove(this.data, data);
        }

        inline fn getAt(this: @This(), x: i32, y: i32) cell_type {
            return this.data[@intCast((@mod(y, grid_size[1])) * grid_size[0] + (@mod(x, grid_size[0])))];
        }

        
        inline fn setAt(this: @This(), x: i32, y: i32, new: cell_type) void {
            this.data[@intCast((@mod(y, grid_size[1])) * grid_size[0] + (@mod(x, grid_size[0])))] = new;
        }
    };
}
