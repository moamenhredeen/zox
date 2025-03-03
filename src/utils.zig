const std = @import("std");

// TODO: difference between noreturn and void
pub fn panic(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    std.process.exit(1);
}
