//! useful utilities

const std = @import("std");

/// panic exit with an error message
/// log the error message and exit the program immediatly
pub fn panic(comptime format: []const u8, args: anytype) noreturn {
    std.log.err(format, args);
    std.process.exit(1);
}
