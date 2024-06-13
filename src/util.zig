const std = @import("std");

pub const color_reset = "\x1b[0m";

const ansi_color_map = std.StaticStringMap([]const u8).initComptime(.{
    .{ "black", "\x1b[0;30m" },
    .{ "red", "\x1b[0;31m" },
    .{ "green", "\x1b[0;32m" },
    .{ "brown", "\x1b[0;33m" },
    .{ "blue", "\x1b[0;34m" },
    .{ "purple", "\x1b[0;35m" },
    .{ "cyan", "\x1b[0;36m" },
    .{ "white", "\x1b[0;37m" },
    .{ "default", "\x1b[0m" },
});

const ansi_color_map_bg = std.StaticStringMap([]const u8).initComptime(.{
    .{ "black", "\x1b[0;40m" },
    .{ "red", "\x1b[0;41m" },
    .{ "green", "\x1b[0;42m" },
    .{ "brown", "\x1b[0;43m" },
    .{ "blue", "\x1b[0;44m" },
    .{ "purple", "\x1b[0;45m" },
    .{ "cyan", "\x1b[0;46m" },
    .{ "white", "\x1b[0;47m" },
    .{ "default", "\x1b[0m" },
});

pub fn getColor(foreground: bool, name: []const u8) []const u8 {
    var buf: [128]u8 = undefined;
    var alloc = std.heap.FixedBufferAllocator.init(&buf);

    const nocolor = std.process.getEnvVarOwned(alloc.allocator(), "NO_COLOR") catch alloc.allocator().dupe(u8, "0") catch unreachable;
    defer alloc.allocator().free(nocolor);

    if (nocolor[0] == '1')
        return ansi_color_map.get("default").?;

    if (foreground)
        return ansi_color_map.get(name) orelse ansi_color_map.get("default").?;
    return ansi_color_map_bg.get(name) orelse ansi_color_map_bg.get("default").?;
}

pub fn pathExists(path: []const u8) bool {
    const f = std.fs.cwd().openFile(path, .{}) catch return false;
    f.close();
    return true;
}
