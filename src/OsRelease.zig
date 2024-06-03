const std = @import("std");

const OsRelease = @This();

const release_info: []const u8 = "/etc/lsb_release";
const release_info_alt: []const u8 = "/etc/os-release";

name: []const u8 = undefined,
pretty_name: []const u8 = undefined,
id: []const u8 = undefined,
build_id: []const u8 = undefined,
ansi_color: []const u8 = undefined,
home_url: []const u8 = undefined,
documentation_url: []const u8 = undefined,
support_url: []const u8 = undefined,
bug_report_url: []const u8 = undefined,
privacy_policy_url: []const u8 = undefined,
logo: []const u8 = undefined,

fn parseLine(s: []const u8) struct { key: []const u8, value: []const u8 } {
    var split = std.mem.splitScalar(u8, s, '=');

    const key = split.first();
    const value = split.rest();

    const v = blk: {
        if (value[0] == '"' and value[value.len - 1] == '"')
            break :blk value[1 .. value.len - 1];
        break :blk value;
    };

    return .{
        .key = key,
        .value = v,
    };
}

pub fn parse(gpa: std.mem.Allocator) !OsRelease {
    var o = OsRelease{};
    const f = try std.fs.openFileAbsolute(release_info_alt, .{});
    defer f.close();

    const data = try f.readToEndAlloc(gpa, 4086);
    var data_split = std.mem.splitScalar(u8, data, '\n');

    while (data_split.next()) |i| {
        if (i.len == 0)
            continue;

        const kv = parseLine(i);

        inline for (std.meta.fields(OsRelease)) |field| {
            if (std.ascii.eqlIgnoreCase(field.name, kv.key))
                @field(o, field.name) = try gpa.dupe(u8, kv.value);
        }
    }
    defer gpa.free(data);
    return o;
}

pub fn deinit(self: *const OsRelease, gpa: std.mem.Allocator) void {
    inline for (std.meta.fields(OsRelease)) |field| {
        gpa.free(@field(self, field.name));
    }
}

pub fn format(self: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, w: anytype) !void {
    try w.print(@import("main.zig").fmt_os, .{ self.pretty_name, self.build_id, self.id });
}
