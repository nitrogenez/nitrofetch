const std = @import("std");
const toml = @import("toml");

var instance: ?toml.Parsed(Config) = null;
var arena: std.heap.ArenaAllocator = undefined;

pub var system_id: ?[]const u8 = null;

pub const default_path = "/etc/xdg/nitrofetch.toml";
pub const default_element_order: []const []const u8 = &.{ "icon", "separator", "text", "custom_text" };

const ModuleConfig = struct {
    id: []const u8,
    separator: ?[]const u8 = null,
    order: ?[]const []const u8 = default_element_order,

    icon: ?[]const u8 = null,
    icon_foreground: ?[]const u8 = null,
    icon_background: ?[]const u8 = null,
    icon_diamond_open: ?[]const u8 = null,
    icon_diamond_close: ?[]const u8 = null,
    icon_diamond_foreground: ?[]const u8 = null,
    icon_diamond_background: ?[]const u8 = null,

    text: ?[]const u8 = null,
    text_foreground: ?[]const u8 = null,
    text_background: ?[]const u8 = null,
    text_diamond_open: ?[]const u8 = null,
    text_diamond_close: ?[]const u8 = null,
    text_diamond_foreground: ?[]const u8 = null,
    text_diamond_background: ?[]const u8 = null,

    custom_text: ?[]const u8 = null,
    custom_text_foreground: ?[]const u8 = null,
    custom_text_background: ?[]const u8 = null,
    custom_text_diamond_open: ?[]const u8 = null,
    custom_text_diamond_close: ?[]const u8 = null,
    custom_text_diamond_foreground: ?[]const u8 = null,
    custom_text_diamond_background: ?[]const u8 = null,
};

const Config = struct {
    order: []const []const u8 = &.{"os"},
    separator: []const u8 = " - ",
    default_logo: []const u8 = "tux",
    modules: []const ModuleConfig = &.{
        .{ .id = "os", .icon = "󰌽", .icon_foreground = "blue" },
    },
};

pub fn init(gpa: std.mem.Allocator, path: ?[]const u8) !void {
    arena = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();

    var parser = toml.Parser(Config).init(arena.allocator());
    defer parser.deinit();

    instance = try parser.parseFile(path orelse default_path);
}

pub fn deinit() void {
    if (instance) |i| i.deinit();
    arena.deinit();
}

pub fn get() ?*const Config {
    return if (instance) |i| &i.value else null;
}

pub fn getOrDefault() *const Config {
    return get() orelse &.{};
}

pub fn getModuleIndex(id: []const u8) ?usize {
    for (getOrDefault().modules, 0..) |module, i| {
        if (std.mem.eql(u8, module.id, id))
            return i;
    }
    return null;
}

pub fn getModule(id: []const u8) ?ModuleConfig {
    const index = getModuleIndex(id) orelse return null;
    return getOrDefault().modules[index];
}
