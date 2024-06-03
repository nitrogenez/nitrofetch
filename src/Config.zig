const std = @import("std");
const util = @import("util.zig");

const Config = @This();

text_offset: usize = 1,
always_tux: bool = false,
show_os: bool = true,
show_user: bool = true,
show_abi: bool = true,
show_arch: bool = true,
show_logo: bool = true,
show_obj_format: bool = true,
show_dir_size: bool = true,
show_libs: bool = true,
show_bins: bool = true,
show_session: bool = true,
logo: ?[]const u8 = null,
mum_ima_hukcer: bool = false,

fn getDir(gpa: std.mem.Allocator) ![]const u8 {
    return std.posix.getenv("XDG_CONFIG_HOME") orelse blk: {
        if (std.posix.getenv("HOME")) |path|
            break :blk std.fs.path.join(gpa, &.{ path, ".config" });
        break :blk error.ConfigPathNotFound;
    };
}

fn overrideBool(self: *Config, s: []const u8, v: bool) void {
    const e = std.mem.eql;
    if (e(u8, "os", s)) self.show_os = v;
    if (e(u8, "logo", s)) self.show_logo = v;
    if (e(u8, "user", s)) self.show_user = v;
    if (e(u8, "abi", s)) self.show_abi = v;
    if (e(u8, "arch", s)) self.show_arch = v;
    if (e(u8, "obj_format", s)) self.show_obj_format = v;
    if (e(u8, "libs", s)) self.show_libs = v;
    if (e(u8, "bins", s)) self.show_bins = v;
    if (e(u8, "session", s)) self.show_session = v;
    if (e(u8, "size", s)) self.show_dir_size = v;
}

pub fn parseArgvOverrides(self: *Config) !void {
    const e = std.mem.eql;
    var argv = std.process.args();
    _ = argv.skip();

    while (argv.next()) |arg| {
        if (e(u8, "--reset-to-default", arg)) {
            const c = Config{};
            try c.save(std.heap.page_allocator);
            self.* = c;
        } else if (e(u8, "--show", arg) or e(u8, "-s", arg)) {
            const next = argv.next() orelse return error.ExpectedValue;
            self.overrideBool(next, true);
        } else if (e(u8, "--hide", arg) or e(u8, "-h", arg)) {
            const next = argv.next() orelse return error.ExpectedValue;
            self.overrideBool(next, false);
        } else if (e(u8, "--logo", arg) or e(u8, "-l", arg)) {
            const next = argv.next();
            self.logo = next;
        } else if (e(u8, "--always-tux", arg) or e(u8, "-t", arg)) {
            self.always_tux = true;
        } else if (e(u8, "--mum-ima-hukcer", arg)) {
            self.mum_ima_hukcer = true;
        }
    }
}

pub fn save(self: *const Config, gpa: std.mem.Allocator) !void {
    const path = try getDir(gpa);
    const fpath = try std.fs.path.join(gpa, &.{ path, "nitrofetch.json" });
    const f = try std.fs.cwd().createFile(fpath, .{});
    const json = try std.json.stringifyAlloc(gpa, self, .{ .whitespace = .indent_4 });

    defer gpa.free(json);
    defer gpa.free(path);
    defer gpa.free(fpath);
    defer f.close();

    try f.writeAll(json);
}

pub fn loadOrDefault(gpa: std.mem.Allocator) !Config {
    const path = try getDir(gpa);
    const fpath = try std.fs.path.join(gpa, &.{ path, "nitrofetch.json" });

    if (!util.pathExists(fpath)) {
        const cfg = Config{};
        try cfg.save(gpa);
        return cfg;
    }

    const f = try std.fs.cwd().openFile(fpath, .{});
    const data = try f.readToEndAlloc(gpa, 4096);
    const cfg = try std.json.parseFromSliceLeaky(Config, gpa, data, .{
        .ignore_unknown_fields = true,
        .duplicate_field_behavior = .use_first,
    });

    defer gpa.free(path);
    defer gpa.free(fpath);
    defer gpa.free(data);
    defer f.close();

    return cfg;
}
