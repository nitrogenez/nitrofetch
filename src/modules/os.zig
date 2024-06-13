const std = @import("std");
const config = @import("../config.zig");
const Module = @import("../Module.zig");
const Info = @import("../detect/os/Info.zig");

pub fn module(args: Module.ModuleArgs) !Module {
    var os = Info{
        .name = undefined,
        .pretty_name = undefined,
        .id = undefined,
    };
    config.system_id = os.id;
    os.detect(args.arena.?.allocator());
    return os.module(args.arena.?.allocator());
}
