const std = @import("std");
const builtit = @import("builtin");
const uuid = @import("uuid");

const session = @import("../session/session.zig");
const protocol = @import("../protobuf/com/staploy.pb.zig");

pub fn createDefaultWorkerInfo(io: std.Io, requireDetail: bool) protocol.WorkerInfo {
    var workerInfo: protocol.WorkerInfo = protocol.WorkerInfo {
        .workerId = getWorkerUniqueId(io),
    };

    if(requireDetail) {
        workerInfo.binLocation = session.globalOptions.@"bin-dir";
        workerInfo.cpuArch = getWorkerCpuArch();
        workerInfo.cpuCoreCount = getCpuCoreCount();
        workerInfo.memoryInBytes = getTotalMemorySizeInBytes();
    }
    return workerInfo;
}

pub fn getWorkerUniqueId(io: std.Io) []const u8 {
    return &uuid.urn.serialize(uuid.v4.new(io));
}

pub fn getTotalMemorySizeInBytes() ?i64 {
    const mem = std.process.totalSystemMemory() catch return null;
    return @intCast(mem);
}

pub fn getCpuCoreCount() ?i64 {
    const cores = std.Thread.getCpuCount() catch return null;
    return @intCast(cores);
}

pub fn getWorkerCpuArch() protocol.CpuArch {
    return switch (builtit.cpu.arch) {
        std.Target.Cpu.Arch.x86 => protocol.CpuArch.i386,
        std.Target.Cpu.Arch.x86_64 => protocol.CpuArch.x86_64,
        std.Target.Cpu.Arch.arm => protocol.CpuArch.arm,
        std.Target.Cpu.Arch.aarch64 => protocol.CpuArch.aarch64,
        std.Target.Cpu.Arch.riscv32 => protocol.CpuArch.riscv32,
        std.Target.Cpu.Arch.riscv64 => protocol.CpuArch.riscv64,
        std.Target.Cpu.Arch.mipsel => protocol.CpuArch.mipsel,
        std.Target.Cpu.Arch.mips64el => protocol.CpuArch.mips64el,
        else => unreachable
    };
}