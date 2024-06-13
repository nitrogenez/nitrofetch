const std = @import("std");
const config = @import("config.zig");
const util = @import("util.zig");

id: []const u8,
line: []const u8,

pub const ModuleArgs = struct {
    arena: ?*std.heap.ArenaAllocator = null,
    id: ?[]const u8 = null,
};

const IconConfig = struct {
    diamond_open: []const u8 = "",
    diamond_close: []const u8 = "",
    diamond_foreground: []const u8 = "",
    diamond_background: []const u8 = "",
    foreground: []const u8 = "",
    background: []const u8 = "",
    icon: []const u8 = "",

    pub fn fetch(ctx: *IconConfig, id: []const u8) void {
        const mod = config.getModule(id) orelse return;

        if (mod.icon) |i| ctx.icon = i;
        if (mod.icon_foreground) |i| ctx.foreground = util.getColor(true, i);
        if (mod.icon_background) |i| ctx.background = util.getColor(false, i);
        if (mod.icon_diamond_open) |i| ctx.diamond_open = i;
        if (mod.icon_diamond_close) |i| ctx.diamond_close = i;
        if (mod.icon_diamond_foreground) |i| ctx.diamond_foreground = util.getColor(true, i);
        if (mod.icon_diamond_background) |i| ctx.diamond_background = util.getColor(false, i);
    }

    pub fn write(ctx: *IconConfig, writer: anytype) !void {
        try writer.writeAll(ctx.diamond_background);
        try writer.writeAll(ctx.diamond_foreground);
        try writer.writeAll(ctx.diamond_open);
        try writer.writeAll(util.color_reset);

        try writer.writeAll(ctx.background);
        try writer.writeAll(ctx.foreground);
        try writer.writeAll(ctx.icon);
        try writer.writeAll(util.color_reset);

        try writer.writeAll(ctx.diamond_background);
        try writer.writeAll(ctx.diamond_foreground);
        try writer.writeAll(ctx.diamond_close);
        try writer.writeAll(util.color_reset);
    }
};

const TextConfig = struct {
    text: ?[]const u8 = "",
    diamond_open: []const u8 = "",
    diamond_close: []const u8 = "",
    diamond_foreground: []const u8 = "",
    diamond_background: []const u8 = "",
    foreground: []const u8 = "",
    background: []const u8 = "",

    pub fn fetch(ctx: *TextConfig, id: []const u8) void {
        const mod = config.getModule(id) orelse return;

        ctx.text = mod.text;
        if (mod.text_diamond_open) |i| ctx.diamond_open = i;
        if (mod.text_diamond_close) |i| ctx.diamond_close = i;
        if (mod.text_diamond_foreground) |i| ctx.diamond_foreground = util.getColor(true, i);
        if (mod.text_diamond_background) |i| ctx.diamond_background = util.getColor(false, i);
        if (mod.text_foreground) |i| ctx.foreground = util.getColor(true, i);
        if (mod.text_background) |i| ctx.background = util.getColor(false, i);
    }

    pub fn write(ctx: *TextConfig, text: []const u8, writer: anytype) !void {
        try writer.writeAll(ctx.diamond_background);
        try writer.writeAll(ctx.diamond_foreground);
        try writer.writeAll(ctx.diamond_open);
        try writer.writeAll(util.color_reset);

        try writer.writeAll(ctx.background);
        try writer.writeAll(ctx.foreground);
        try writer.writeAll(if (ctx.text) |t| t else text);
        try writer.writeAll(util.color_reset);

        try writer.writeAll(ctx.diamond_background);
        try writer.writeAll(ctx.diamond_foreground);
        try writer.writeAll(ctx.diamond_close);
    }
};

const CustomTextConfig = struct {
    diamond_open: []const u8 = "",
    diamond_close: []const u8 = "",
    diamond_foreground: []const u8 = "",
    diamond_background: []const u8 = "",
    foreground: []const u8 = "",
    background: []const u8 = "",
    text: []const u8 = "",

    pub fn fetch(ctx: *CustomTextConfig, id: []const u8) void {
        const mod = config.getModule(id) orelse return;

        if (mod.custom_text) |i| ctx.text = i;
        if (mod.custom_text_foreground) |i| ctx.foreground = util.getColor(true, i);
        if (mod.custom_text_background) |i| ctx.background = util.getColor(false, i);
        if (mod.custom_text_diamond_open) |i| ctx.diamond_open = i;
        if (mod.custom_text_diamond_close) |i| ctx.diamond_close = i;
        if (mod.custom_text_diamond_foreground) |i| ctx.diamond_foreground = util.getColor(true, i);
        if (mod.custom_text_diamond_background) |i| ctx.diamond_background = util.getColor(false, i);
    }

    pub fn write(ctx: *CustomTextConfig, writer: anytype) !void {
        try writer.writeAll(ctx.diamond_background);
        try writer.writeAll(ctx.diamond_foreground);
        try writer.writeAll(ctx.diamond_open);
        try writer.writeAll(util.color_reset);

        try writer.writeAll(ctx.background);
        try writer.writeAll(ctx.foreground);
        try writer.writeAll(ctx.text);
        try writer.writeAll(util.color_reset);

        try writer.writeAll(ctx.diamond_background);
        try writer.writeAll(ctx.diamond_foreground);
        try writer.writeAll(ctx.diamond_close);
    }
};

pub fn print(self: *const @This(), writer: anytype) !void {
    const mod = config.getModule(self.id) orelse return;

    var text_cfg = TextConfig{};
    var icon_cfg = IconConfig{};
    var custom_text_cfg = CustomTextConfig{};

    TextConfig.fetch(&text_cfg, self.id);
    IconConfig.fetch(&icon_cfg, self.id);
    CustomTextConfig.fetch(&custom_text_cfg, self.id);

    const order = mod.order orelse config.default_element_order;

    for (order) |elem| {
        if (std.mem.eql(u8, elem, "icon")) {
            try icon_cfg.write(writer);
        } else if (std.mem.eql(u8, elem, "separator")) {
            try writer.writeAll(self.getSep());
        } else if (std.mem.eql(u8, elem, "text")) {
            try text_cfg.write(self.line, writer);
        } else if (std.mem.eql(u8, elem, "custom_text")) {
            try custom_text_cfg.write(writer);
        }
    }
}

fn getSep(self: *const @This()) []const u8 {
    return blk: {
        for (config.getOrDefault().modules) |mod| {
            if (std.mem.eql(u8, mod.id, self.id)) {
                if (mod.separator) |sep| break :blk sep;
                break;
            }
        }
        break :blk if (std.mem.startsWith(u8, self.id, "custom")) "" else config.getOrDefault().separator;
    };
}
