//! zox root module

pub const tokenizer = @import("./tokenizer.zig");

comptime {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
