const std = @import("std");
const ws = @import("websocket");
const serviceConst = @import("service_const.zig");

pub var globalOptions: Options = .{};
pub const Options = struct {
    help: bool = false,
    address: []const u8 = "127.0.0.1",
    port: u16 = 18090,
    @"bin-dir": ?[]const u8 = null,
    @"profile-dir": ?[]const u8 = null,
    @"cache-dir": ?[]const u8 = null,

    pub const shorthands = .{ .h = "help", .a = "address", .p = "port", .b = "bin-dir", .d = "profile-dir", .c = "cache-dir" };
};

const Handler = struct {
    client: ws.Client,

    fn init(processInit: std.process.Init) !Handler {
        var client = try ws.Client.init(processInit.io, processInit.arena.allocator(), .{
            .port = globalOptions.port,
            .host = globalOptions.address,
            .tls = false,
        });

        const request_path = try std.fmt.allocPrint(processInit.arena.allocator(), serviceConst.API_ROUTE_SCHEMA, .{ "v1", serviceConst.CONN_TYPE_NODE });
        std.debug.print("REQ => {s}:{d}{s}\n", .{globalOptions.address, globalOptions.port, request_path});
        try client.handshake(request_path, .{
            .timeout_ms = 30000,
            //.headers = "Stub!", //TODO: implement auth token into header (Bearer?)
        });

        return .{
            .client = client,
        };
    }

    pub fn startLoop(self: *Handler) !void {
        try self.client.readLoop(self);
    }

    pub fn serverMessage(self: *Handler, data: []u8) !void {
        std.debug.print("incomming packet: {s}", .{data});
        return self.client.write(data);
    }

    pub fn close(self: *Handler) void {
        self.client.close(.{}) catch {};
        defer self.client.deinit();
    }
};

pub fn startSession(init: std.process.Init, options: Options) !u8 {
    globalOptions = options;
    var sessionHandler = try Handler.init(init);
    sessionHandler.startLoop() catch |err| {
        std.log.err("error while connecting websocket => {}", .{err});
        return 1;
    };
    return 0;
}
