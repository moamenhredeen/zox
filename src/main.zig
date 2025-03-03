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
    var arena_instance = heap.ArenaAllocator.init(heap.page_allocator);
    const arena = arena_instance.allocator();
    const args = try process.argsAlloc(arena);
    try parse_args(args);
}

pub fn parse_args(args: [][]u8) !void {
    if (args.len <= 1) {
        log.info("{s}", .{usage});
        panic("expected command argument", .{});
    }

    const cmd = args[1];
    const cmd_args = args[2..];
    if (mem.eql(u8, cmd, "run")) {
        try io.getStdOut().writeAll("running some script ...\n");
        try io.getStdOut().writeAll(cmd_args[0]);
    } else if (mem.eql(u8, cmd, "repl")) {
        try io.getStdOut().writeAll("starting the repl\n");
    } else if (mem.eql(u8, cmd, "help") or mem.eql(u8, cmd, "-h") or mem.eql(u8, cmd, "--help")) {
        try io.getStdOut().writeAll(usage);
    } else if (mem.eql(u8, cmd, "version")) {
        try io.getStdOut().writeAll(build_options.version ++ "\n");
    } else {
        log.info("{s}", .{usage});
        panic("unknown command: {s}", .{args[1]});
    }
}


pub fn cmdRun()
