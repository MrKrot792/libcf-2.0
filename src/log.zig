const std = @import("std");

const logging: bool = false;

pub fn log(comptime fmt: []const u8, args: anytype) void {
    if (logging) std.debug.print(fmt, args);
}
