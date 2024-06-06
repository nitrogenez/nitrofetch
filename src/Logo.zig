const std = @import("std");
const Config = @import("Config.zig");

data: []const u8,
offset: usize = 0,
max_line_len: usize = 0,
text_offset: usize = 1,
hck: bool = false,

pub fn init(data: []const u8) @This() {
    return .{
        .data = data,
        .max_line_len = getMaxLineLen(data),
    };
}

pub fn fromId(distro_id: []const u8) @This() {
    return init(logos.get(distro_id) orelse "");
}

pub fn printLine(self: *@This(), w: anytype, comptime fmt: []const u8, args: anytype) !void {
    var written: usize = 0;

    for (self.data[self.offset..]) |i| {
        if (i == '\n') {
            self.offset += 1;
            break;
        }
        try w.writeByte(i);
        self.offset += 1;
        written += 1;
    }

    const offset = self.max_line_len - written + self.text_offset;
    try printRepeat(' ', offset, w);
    if (!self.hck) try w.print(fmt, args) else try hckrPrint(fmt, args, w);
    try w.writeByte('\n');
}

pub fn printRest(self: *@This(), w: anytype) !void {
    try w.writeAll(self.data[self.offset..]);
}

fn printRepeat(c: u8, times: usize, w: anytype) !void {
    for (0..times) |_| {
        try w.writeByte(c);
    }
}

fn getMaxLineLen(data: []const u8) usize {
    var max: usize = 0;
    var len: usize = 0;

    for (data) |c| {
        if ('\n' == c) {
            max = @max(max, len);
            len = 0;
            continue;
        }
        len += 1;
    }
    return max;
}

fn hckrPrint(comptime fmt: []const u8, args: anytype, w: anytype) !void {
    var buf: [4096]u8 = .{0} ** 4096;
    var ally = std.heap.FixedBufferAllocator.init(&buf);
    const s = try std.fmt.allocPrint(ally.allocator(), fmt, args);
    const hackr = "mumimahukcer";
    var hackr_index: usize = 0;

    for (s, 0..) |c, i| {
        switch (c) {
            'a'...'z', 'A'...'Z' => {
                if (hackr_index < hackr.len) {
                    hackr_index += 1;
                } else if (hackr_index >= hackr.len) {
                    hackr_index = 0;
                }
                s[i] = hackr[hackr_index];
            },
            else => {},
        }
    }
    try w.writeAll("\x1B[0;32m");
    try w.writeAll(s);
    try w.writeAll("\x1B[0m");
}

pub const logos = std.ComptimeStringMap([]const u8, .{
    .{ "aix", @embedFile("logos/aix.ascii") },
    .{ "arch", @embedFile("logos/arch.ascii") },
    .{ "linux", @embedFile("logos/linux.ascii") },
    .{ "debian", @embedFile("logos/debian.ascii") },
    .{ "ubuntu", @embedFile("logos/ubuntu.ascii") },
    .{ "fedora", @embedFile("logos/fedora.ascii") },
    .{ "crystal", @embedFile("logos/crystal.ascii") },
    .{ "endeavouros", @embedFile("logos/endeavouros.ascii") },
    .{ "elbrus", @embedFile("logos/elbrus.ascii") },
    .{ "nixos", @embedFile("logos/nixos.ascii") },
    .{ "parabola", @embedFile("logos/parabola.ascii") },
    .{ "popos", @embedFile("logos/popos.ascii") },
    .{ "ukraine", @embedFile("logos/ukraine.ascii") },
});
