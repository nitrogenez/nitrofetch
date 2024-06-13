const std = @import("std");
const Module = @import("../../Module.zig");
const linux = @import("linux/linux.zig");

name: []const u8,
pretty_name: []const u8,
id: []const u8,
id_like: ?[]const u8 = null,
variant: ?[]const u8 = null,
variant_id: ?[]const u8 = null,
version: ?[]const u8 = null,
version_id: ?[]const u8 = null,
codename: ?[]const u8 = null,
build_id: ?[]const u8 = null,

// TODO: Colors, NO_COLOR envvar
/// Returns `Module` with printed line. Caller owns the memory.
pub fn module(self: *@This(), gpa: std.mem.Allocator) !Module {
    const data = try std.fmt.allocPrint(gpa, "{s} ({s})", .{ self.pretty_name, self.id });

    return Module{
        .id = "os",
        .line = data,
    };
}

pub fn detect(self: *@This(), gpa: std.mem.Allocator) void {
    // Detect Linux
    if (linux.detectDistro(self, gpa)) return;

    // Detect Windows
    // WIP
}
