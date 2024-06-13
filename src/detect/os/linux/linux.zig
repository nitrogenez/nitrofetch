const std = @import("std");
const ubuntu = @import("ubuntu.zig");

const Info = @import("../Info.zig");

pub fn detectDistro(ctx: *Info, gpa: std.mem.Allocator) bool {
    if (parseOsRelease(ctx, gpa)) {
        if (std.mem.eql(u8, ctx.id, "ubuntu")) _ = ubuntu.getFlavor(ctx);
        return true;
    }

    if (parseLsbRelease(ctx, gpa)) {
        if (std.mem.eql(u8, ctx.id, "ubuntu")) _ = ubuntu.getFlavor(ctx);
        return true;
    }
    return false;
}

fn parseLsbRelease(ctx: *Info, gpa: std.mem.Allocator) bool {
    const f = std.fs.openFileAbsolute("/etc/lsb-release", .{}) catch return false;
    defer f.close();

    var data_buf: [4096]u8 = undefined;
    const bytes = f.readAll(&data_buf) catch return false;

    return parseProperties(ctx, gpa, lsb_release_field_map, data_buf[0..bytes]);
}

fn parseOsRelease(ctx: *Info, gpa: std.mem.Allocator) bool {
    const f = std.fs.openFileAbsolute("/etc/os-release", .{}) catch blk: {
        break :blk std.fs.openFileAbsolute("/usr/lib/os-release", .{}) catch return false;
    };
    defer f.close();

    var data_buf: [4096]u8 = undefined;
    const bytes = f.readAll(&data_buf) catch return false;

    return parseProperties(ctx, gpa, os_release_field_map, data_buf[0..bytes]);
}

fn parsePropertiesLine(ctx: *Info, gpa: std.mem.Allocator, comptime field_map: anytype, name: []const u8, value: []const u8) bool {
    return inline for (field_map) |kv| {
        if (std.mem.eql(u8, name, kv.@"0")) {
            @field(ctx, kv.@"1") = gpa.dupe(u8, value) catch @panic("OOM");
            return true;
        }
    } else false;
}

fn parseProperties(ctx: *Info, gpa: std.mem.Allocator, comptime field_map: anytype, src: []const u8) bool {
    var stream = std.io.fixedBufferStream(src);
    var lines_processed: usize = 0;

    while (true) {
        var linebuf: [1024]u8 = undefined;
        const line = stream.reader().readUntilDelimiter(&linebuf, '\n') catch |e| switch (e) {
            error.EndOfStream => break,
            else => unreachable,
        };
        var line_it = std.mem.splitScalar(u8, line, '=');
        const name = std.mem.trim(u8, line_it.first(), " \t\r\n");
        const value = std.mem.trim(u8, line_it.next() orelse continue, " \t\r\n\"");

        if (parsePropertiesLine(ctx, gpa, field_map, name, value)) lines_processed += 1;
    }
    return lines_processed > 0;
}

const os_release_field_map = .{
    .{ "PRETTY_NAME", "pretty_name" },
    .{ "NAME", "name" },
    .{ "ID", "id" },
    .{ "ID_LIKE", "id_like" },
    .{ "VARIANT", "variant" },
    .{ "VARIANT_ID", "variant_id" },
    .{ "VERSION", "version" },
    .{ "VERSION_ID", "version_id" },
    .{ "VERSION_CODENAME", "codename" },
    .{ "CODENAME", "codename" },
    .{ "BUILD_ID", "build_id" },
};

const lsb_release_field_map = .{
    .{ "DISTRIB_ID", "id" },
    .{ "DISTRIB_DESCRIPTION", "pretty_name" },
    .{ "DISTRIB_RELEASE", "version" },
    .{ "DISTRIB_CODENAME", "codename" },
};
