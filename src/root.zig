//! zox root module

pub const lexer = @import("./tokenizer.zig");

comptime {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
