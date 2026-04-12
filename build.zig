const std = @import("std");
const protobuf = @import("protobuf");
const zon = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const version = std.SemanticVersion.parse(zon.version) catch |err| {
        std.debug.print("Failed to get version name: {}", .{err});
        std.process.exit(1);
    };

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = b.addOptions();
    options.addOption(std.SemanticVersion, "version", version);

    const exe = b.addExecutable(.{
        .name = "staploy",
        .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize, .imports = &.{} }),
    });

    exe.root_module.addImport("args", b.dependency("args", .{ .target = target, .optimize = optimize }).module("args"));
    exe.root_module.addImport("websocket", b.dependency("websocket", .{ .target = target, .optimize = optimize }).module("websocket"));
    exe.root_module.addImport("protobuf", b.dependency("protobuf", .{ .target = target, .optimize = optimize }).module("protobuf"));

    exe.root_module.addOptions("build_options", options);
    b.installArtifact(exe);

    const gen_proto = b.step("gen-proto", "generates zig files from protocol buffer definitions");
    const protobuf_dep = b.dependency("protobuf", .{
        .target = target,
        .optimize = optimize,
    });

    const proto_files = getProtoFiles(b.allocator, "protobuf");
    const protoc_step = protobuf.RunProtocStep.create(protobuf_dep.builder, target, .{
        .destination_directory = b.path("src/protobuf"),
        .source_files = proto_files catch |err| {
            std.debug.print("Failed to get proto files: {}\n", .{err});
            std.process.exit(1);
        },
        .include_directories = &.{"protobuf"},
    });
    gen_proto.dependOn(&protoc_step.step);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}

fn getProtoFiles(allocator: std.mem.Allocator, directory: []const u8) ![]const []const u8 {
    var file_list: std.ArrayList([]const u8) = .empty;
    defer file_list.deinit(allocator);

    var dir = try std.fs.cwd().openDir(directory, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".proto")) {
            const full_path = try std.fs.path.join(allocator, &.{ directory, entry.path });
            try file_list.append(allocator, full_path);
        }
    }
    return file_list.toOwnedSlice(allocator);
}