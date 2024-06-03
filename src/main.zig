const std = @import("std");
const alloc = std.heap.page_allocator;
const builtin = @import("builtin");
const util = @import("util.zig");

const Config = @import("Config.zig");
const OsRelease = @import("OsRelease.zig");
const User = @import("User.zig");
const Logo = @import("Logo.zig");

pub const fmt_os = "| os: {2s} ({0s} - {1s})";
pub const fmt_user = "| user: {1s}@{2s} ({0d})";
pub const fmt_abi = "| c abi: {s}";
pub const fmt_arch = "| architecture: {s}";
pub const fmt_obj_format = "| object format: {s}";
pub const fmt_libs = "| libraries (/usr/lib): {d} ({d} MiB)";
pub const fmt_bins = "| binaries (/usr/bin): {d} ({d} MiB)";
pub const fmt_session = "| desktop session: {s}";

const help =
    \\Copyright (c) 2024 Andrij Glyko
    \\This software is licensed under BSD-3-clause license.
    \\
    \\usage: nitrofetch [HIDE...] [SHOW...] [FLAGS...]
    \\
    \\HIDE/SHOW:
    \\  -h|--hide, -s|--show os         - Hide/show os info
    \\  -h|--hide, -s|--show user       - Hide/show user info
    \\  -h|--hide, -s|--show abi        - Hide/show C ABI
    \\  -h|--hide, -s|--show arch       - Hide/show CPU architecture
    \\  -h|--hide, -s|--show logo       - Hide/show ditro logo
    \\  -h|--hide, -s|--show obj_format - Hide/show object format info
    \\  -h|--hide, -s|--show size       - Hide/show directory sizes
    \\  -h|--hide, -s|--show libs       - Hide/show library count
    \\  -h|--hide, -s|--show bins       - Hide/show executables count
    \\  -h|--hide, -s|--show session    - Hide/show desktop session type
    \\
    \\FLAGS:
    \\  -l|--logo <NAME>                - Display logo NAME instead of current distro logo
    \\  -t|--always-tux                 - Always display Tux instead of current distro logo
    \\  --help                          - Display this message and exit
    \\  --mum-ima-hukcer                - Enable hukcer mode (real)
    \\  --reset-to-default              - Reset config in $XDG_CONFIG_HOME/nitrofetch.json to defaults
    \\
    \\For instructions on adding new logos to nitrofetch see README.md on https://github.com/nitrogenez/nitrofetch.
    \\Stand with Ukraine <3
;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(alloc);
    var stdout_bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = stdout_bw.writer();
    const gpa = arena.allocator();
    var config = try Config.loadOrDefault(gpa);

    config.parseArgvOverrides() catch |e| {
        try std.io.getStdErr().writer().print("error: {s}", .{@errorName(e)});
    };
    const user: ?User = if (config.show_user) try User.get(gpa) else null;
    const osinfo: ?OsRelease = if (config.show_os) try OsRelease.parse(gpa) else null;

    var logo = Logo.fromId(blk: {
        if (config.logo) |l| break :blk l;
        if (!config.show_logo) break :blk "";
        if (config.always_tux) break :blk "linux";
        if (osinfo) |i| break :blk i.id;
        break :blk "";
    });
    logo.text_offset = config.text_offset;
    logo.hck = config.mum_ima_hukcer;

    defer arena.deinit();
    defer stdout_bw.flush() catch unreachable;
    defer {
        if (osinfo) |o| o.deinit(gpa);
        if (user) |u| u.deinit(gpa);
    }

    var argv = std.process.args();
    while (argv.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            try stdout.writeAll(help);
            try stdout.writeByte('\n');
            try stdout_bw.flush();
            return;
        }
    }

    if (config.show_os) try logo.printLine(stdout, "{}", .{osinfo.?});
    if (config.show_user) try logo.printLine(stdout, "{}", .{user.?});
    if (config.show_abi) try logo.printLine(stdout, fmt_abi, .{@tagName(builtin.abi)});
    if (config.show_arch) try logo.printLine(stdout, fmt_arch, .{@tagName(builtin.cpu.arch)});
    if (config.show_obj_format) try logo.printLine(stdout, fmt_obj_format, .{@tagName(builtin.object_format)});
    if (config.show_libs) try logo.printLine(stdout, fmt_libs, .{
        try countFiles("/usr/lib", gpa),
        if (config.show_dir_size) try countDirTotalSize("/usr/lib", gpa) else 0,
    });
    if (config.show_bins) try logo.printLine(stdout, fmt_bins, .{
        try countFiles("/usr/bin", gpa),
        if (config.show_dir_size) try countDirTotalSize("/usr/bin", gpa) else 0,
    });
    if (config.show_session) try logo.printLine(stdout, fmt_session, .{std.posix.getenv("XDG_SESSION_TYPE") orelse "null"});
    try logo.printRest(stdout);
}

fn countFiles(comptime dir: []const u8, gpa: std.mem.Allocator) !usize {
    const d = try std.fs.openDirAbsolute(dir, .{ .iterate = true });
    var it = try d.walk(gpa);
    defer it.deinit();
    var c: usize = 0;

    while (try it.next()) |i| {
        if (i.kind != .directory) c += 1;
    }
    return c;
}

fn countDirTotalSize(comptime dir: []const u8, gpa: std.mem.Allocator) !f64 {
    const d = try std.fs.openDirAbsolute(dir, .{ .iterate = true });
    var it = try d.walk(gpa);
    defer it.deinit();
    var total: usize = 0;

    while (try it.next()) |i| {
        if (i.kind != .directory) {
            const stat = i.dir.statFile(i.path) catch continue;
            total += stat.size;
        }
    }
    return bToMb(@as(f64, @floatFromInt(total)));
}

fn bToMib(b: f64) f64 {
    return @divExact(b, 1024 * 1024);
}

fn bToMb(b: f64) f64 {
    return @divExact(b, 1000 * 1000);
}
