const std = @import("std");
const mem = @import("std").mem;
const io = @import("std").io;
const log = @import("std").log;
const heap = @import("std").heap;
const process = @import("std").process;
const build_options = @import("build_options");
const lexer = @import("compiler/lexer.zig");

const panic = @import("utils.zig").panic;

const usage =
    \\Usage: zox [command] [option]
    \\
    \\Commands:
    \\  version          Print version number and exit
    \\  help             Print this help and exit
    \\
    \\General Options:
    \\
    \\  -h, --help       Print command-specific usage
    \\
;

pub fn main() anyerror!void {
    var arena_allocator = heap.ArenaAllocator.init(heap.page_allocator);
    const allocator = arena_allocator.allocator();
    const args = try process.argsAlloc(allocator);
    try parseArgs(allocator, args);
}

pub fn parseArgs(
    allocator: std.mem.Allocator,
    args: []const []const u8,
) !void {
    if (args.len <= 1) {
        log.info("{s}", .{usage});
        panic("expected command argument", .{});
    }

    const cmd = args[1];
    const cmdArgs = args[2..];
    if (mem.eql(u8, cmd, "run")) {
        try cmdRun(allocator, cmdArgs);
    } else if (mem.eql(u8, cmd, "repl")) {
        try cmdRepl(allocator, cmdArgs);
    } else if (mem.eql(u8, cmd, "eval")) {
        try cmdEval(allocator, cmdArgs);
    } else if (mem.eql(u8, cmd, "help") or mem.eql(u8, cmd, "-h") or mem.eql(u8, cmd, "--help")) {
        try std.io.getStdOut().writeAll(usage);
    } else if (mem.eql(u8, cmd, "version")) {
        try std.io.getStdOut().writeAll(build_options.version ++ "\n");
    } else {
        log.info("{s}", .{usage});
        panic("unknown command: {s}", .{args[1]});
    }
}

/// run command
pub fn cmdRun(
    allocator: mem.Allocator,
    args: []const []const u8,
) !void {
    if (args.len < 1) {
        panic("file name is required. please provide file name when using the run the command", .{});
    } else if (args.len > 1) {
        panic("too many arguments. run command requires only the file name to run", .{});
    }

    const file = try std.fs.cwd().openFile(args[0], .{ .mode = .read_write });
    const content = try file.readToEndAlloc(allocator, std.math.maxInt(u32));
    try std.io.getStdOut().writeAll(content);
}

pub fn cmdRepl(
    allocator: mem.Allocator,
    _: []const []const u8,
) !void {
    while (true) {
        try std.io.getStdOut().writeAll("> ");
        const input = std.io.getStdIn().reader().readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(u32)) catch "";
        if (mem.eql(u8, input, "exit")) {
            return;
        } else if (mem.startsWith(u8, input, "echo")) {
            try std.io.getStdOut().writeAll(input[4..]);
            try std.io.getStdOut().writeAll("\n");
        } else {
            const result = try eval(allocator, input);
            try std.io.getStdOut().writeAll(result);
            try std.io.getStdOut().writeAll("\n");
        }
    }
}

pub fn cmdEval(
    allocator: mem.Allocator,
    args: []const []const u8,
) !void {
    if (args.len != 1) {
        panic("eval takes only 1 argument, which the script to evaluate", .{});
    }
    const result = try eval(allocator, args[0]);
    try std.io.getStdOut().writeAll(result);
    try std.io.getStdOut().writeAll("\n");
}

pub fn eval(allocator: mem.Allocator, script: []const u8) ![]const u8 {
    const m = "\nevaluating script ...";
    const res = try std.mem.concat(allocator, u8, &[_][]const u8{ script, m });
    return res;
}
