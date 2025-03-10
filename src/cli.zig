//! zig command line interface

const std = @import("std");

const Commands = enum {
    help,
    version,
    run,
    repl,
    eval,
};

const CommandLineError = error{CommandNotFound};

pub fn parse(cmd: []const u8) CommandLineError!void {
    const c: Commands = std.meta.stringToEnum(Commands, cmd) orelse {
        return CommandLineError.CommandNotFound;
    };

    _ = switch (c) {
        .help => {
            std.debug.print("help command", .{});
        },
    };
}
