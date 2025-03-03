const std = @import("std");
const mem = @import("std").mem;
const io = @import("std").io;
const log = @import("std").log;
const heap = @import("std").heap;
const process = @import("std").process;
const build_options = @import("build_options");

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
;

pub fn main() anyerror!void {
    var arenaInstance = heap.ArenaAllocator.init(heap.page_allocator);
    const arena = arenaInstance.allocator();
    const args = try process.argsAlloc(arena);
    try parseArgs(arena, args);
}

pub fn parseArgs(allocator: mem.Allocator, args: [][]u8) !void {
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
        try io.getStdOut().writeAll(usage);
    } else if (mem.eql(u8, cmd, "version")) {
        try io.getStdOut().writeAll(build_options.version ++ "\n");
    } else {
        log.info("{s}", .{usage});
        panic("unknown command: {s}", .{args[1]});
    }
}

/// run command
pub fn cmdRun(_: mem.Allocator, args: [][]u8) !void {
    const writer = io.getStdOut().writer();
    for (args) |arg| {
        try writer.writeAll(arg);
    }
}

pub fn cmdRepl(allocator: mem.Allocator, _: [][]u8) !void {
    const writer = io.getStdOut().writer();
    const reader = io.getStdIn().reader();
    while (true) {
        try writer.writeAll("> ");
        const input = reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(u32)) catch "";
        if (mem.eql(u8, input, "exit")) {
            return;
        } else if (mem.startsWith(u8, input, "echo")) {
            try writer.print("{s}\n", .{input[4..]});
        } else {
            const result = try eval(allocator, input);
            try writer.print("{s}\n", .{result});
        }
    }
}

pub fn cmdEval(allocator: mem.Allocator, args: [][]const u8) !void {
    if (args.len != 1) {
        panic("eval takes only 1 argument, which the script to evaluate", .{});
    }
    const result = try eval(allocator, args[0]);
    try io.getStdOut().writer().print("result: {s}\n", .{result});
}

pub fn eval(_: mem.Allocator, _: []const u8) ![]const u8 {
    return "evaluating script ...";
}
