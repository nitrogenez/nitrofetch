const Module = @import("../Module.zig");

pub fn module(args: Module.ModuleArgs) !Module {
    return Module{
        .id = args.id.?,
        .line = "",
    };
}
