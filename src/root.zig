//! zox is general purpose scripting langauge implemented in zig
//! it's my first attempt to write a programming langauge from scratch
//! this project is for learning puposes only

pub const cli = @import("./cli.zig");
pub const tokenizer = @import("./tokenizer.zig");

comptime {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
