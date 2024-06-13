const std = @import("std");
const config = @import("config.zig");
const Module = @import("Module.zig");
const Logo = @import("Logo.zig");

pub const detect = struct {
    pub const os = struct {
        pub const Info = @import("detect/os/Info.zig");
        pub const linux = struct {
            pub usingnamespace @import("detect/os/linux/linux.zig");
            pub const ubuntu = @import("detect/os/linux/ubuntu.zig");
        };
    };
};

pub const modules = struct {
    pub const os = @import("modules/os.zig");
    pub const custom = @import("modules/custom.zig");
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var known_modules = std.ArrayList([]const u8).init(arena.allocator());
    var module_list = std.ArrayList(Module).init(arena.allocator());
    defer module_list.deinit();
    defer known_modules.deinit();

    config.init(arena.allocator(), null) catch {};

    inline for (@typeInfo(modules).Struct.decls) |decl|
        try known_modules.append(decl.name);

    const modorder = config.getOrDefault().order;
    for (modorder) |mod| {
        if (std.mem.startsWith(u8, mod, "custom")) {
            try module_list.append(try modules.custom.module(.{ .id = mod }));
        }

        inline for (@typeInfo(modules).Struct.decls) |decl| {
            if (std.mem.eql(u8, decl.name, mod)) {
                try module_list.append(try @field(modules, decl.name).module(.{ .arena = &arena }));
            }
        }
    }
    var logo = Logo.fromId(config.system_id orelse "linux");
    defer logo.printRest(std.io.getStdOut().writer()) catch unreachable;

    for (module_list.items) |i| {
        var linebuf: [1024]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&linebuf);
        try i.print(fbs.writer());
        try logo.printLine(std.io.getStdOut().writer(), "{s}", .{fbs.getWritten()});
        // try std.io.getStdOut().writeAll("\n");
    }
}
