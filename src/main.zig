const std = @import("std");
const argsParser = @import("args");
const build_options = @import("build_options");
const builtin = @import("builtin");
const session = @import("session.zig");

pub fn main() !u8 {
    const argsAllocator = std.heap.page_allocator;
    const options = argsParser.parseForCurrentProcess(session.Options, argsAllocator, .print) catch return 1;
    defer options.deinit();

    if(options.options.help) {
        const v = build_options.version;
        std.debug.print("staploy-worker {d}.{d}.{d} ({s})\n", .{ v.major, v.minor, v.patch, @tagName(builtin.target.cpu.arch)});
        return 0;
    }

    if(options.options.@"bin-dir") |bin_dir| {
        var dir = std.fs.cwd().openDir(bin_dir, .{}) catch |err| {
            if (err == error.FileNotFound) {
                std.log.err("Specified path not exists, Abort.\n", .{});
            } else if (err == error.AccessDenied) {
                std.log.err("Specified path access denied, Abort.\n", .{});
            } else {
                std.log.err("Specified path not accessible, Abort.\n", .{});
            }
            return 1;
        };
        defer dir.close();
    } else {
        std.log.err("Binary path not specified, Abort.\n", .{});
        return 1;
    }

    return session.startSession(options.options);
}