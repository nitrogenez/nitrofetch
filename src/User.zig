const std = @import("std");

uid: u32,
name: []const u8,
hostname: []const u8,

pub fn get(gpa: std.mem.Allocator) !@This() {
    var buf: [std.posix.HOST_NAME_MAX]u8 = .{0} ** std.posix.HOST_NAME_MAX;
    const hostname = try std.posix.gethostname(&buf);
    const username = std.posix.getenv("USER") orelse "unknown";
    return .{
        .uid = @intCast(std.os.linux.getuid()),
        .name = username,
        .hostname = try gpa.dupe(u8, hostname),
    };
}

pub fn deinit(self: *const @This(), gpa: std.mem.Allocator) void {
    gpa.free(self.hostname);
}

pub fn format(self: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
    try w.print(@import("main.zig").fmt_user, .{ self.uid, self.name, self.hostname });
}
