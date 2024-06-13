const std = @import("std");

pub const detect = struct {
    pub const os = struct {
        pub const Info = @import("detect/os/Info.zig");
        pub const linux = struct {
            pub usingnamespace @import("detect/os/linux/linux.zig");
            pub const ubuntu = @import("detect/os/linux/ubuntu.zig");
        };
    };
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var osinfo = detect.os.Info{
        .name = undefined,
        .pretty_name = undefined,
        .id = undefined,
    };

    if (detect.os.linux.detectDistro(&osinfo, arena.allocator())) {
        try std.io.getStdOut().writer().print("{s} ({s})\n", .{ osinfo.pretty_name, osinfo.id });
        return;
    }
}
