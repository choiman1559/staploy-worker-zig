const std = @import("std");
const ws = @import("websocket");

const protocol = @import("../protobuf/com/staploy.pb.zig");
const session = @import("session.zig");
const workerInfo = @import("../utils/worker_info.zig");

pub fn packetProcess(init: std.process.Init, wsSession: *session.Handler, data: []u8) !void {
    var buf_reader = std.Io.Reader.fixed(data);
    var incomingPacket = try protocol.ServerPacket.decode(&buf_reader, init.arena.allocator());
    defer incomingPacket.deinit(init.arena.allocator());
    try routePacket(init,wsSession, incomingPacket);
}

fn routePacket(init: std.process.Init, wsSession: *session.Handler, incomingPacket: protocol.ServerPacket) !void {
    if(incomingPacket.packetInfo) |dataPacket|{
        switch (dataPacket.procedure) {
            protocol.ProtocolProcedure.PROCEDURE_SERVER_HELLO => {
                std.debug.print("Connected to server, responding WorkerInfo...", .{});
                try replyWorkerData(init, wsSession, incomingPacket);
            },
            protocol.ProtocolProcedure.PROCEDURE_REQUEST_TASK => {

            },
            protocol.ProtocolProcedure.PROCEDURE_CHECK_TASK => {

            },
            protocol.ProtocolProcedure.PROCEDURE_CANCEL_TASK => {

            },
            else => {

            }
        }
    } //TODO: reply error packet
}

fn replyWorkerData(init: std.process.Init, wsSession: *session.Handler, incomingPacket: protocol.ServerPacket) !void {
    var requireDetailInfo: bool = false;
    if(incomingPacket.packetInfo.?.actionProcedure) |actionType| {
        requireDetailInfo = switch (actionType) {
            protocol.ActionProcedure.PROCEDURE_NONE => false,
            protocol.ActionProcedure.PROCEDURE_REQUEST_WORKER_INFO => true,
            protocol.ActionProcedure.PROCEDURE_ACK => {
                std.debug.print("Server handshake done!", .{});
                session.isConnected = true;
                return;
            },
            else => false
        };
    }

    const responsePacket = protocol.WorkerPacket {
        .workerInfo = workerInfo.createDefaultWorkerInfo(init.io, requireDetailInfo),
        .packetInfo = incomingPacket.packetInfo,
        .taskResult = protocol.Result {
            .resultFinished = true,
            .resultSuccessful = true
        }
    };

    var w = std.Io.Writer.Allocating.init(init.arena.allocator());
    defer w.deinit();
    try responsePacket.encode(&w.writer, init.arena.allocator());
    std.debug.print("{s}", .{try responsePacket.jsonEncode(.{.whitespace = .indent_3 }, .{}, init.arena.allocator())});

    const result: []u8 = w.written();
    try wsSession.client.write(result);
}