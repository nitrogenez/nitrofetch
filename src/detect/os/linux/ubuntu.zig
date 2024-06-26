const std = @import("std");
const util = @import("util.zig");
const Info = @import("../Info.zig");

pub fn getFlavor(ctx: *Info) bool {
    const xdg = std.posix.getenv("XDG_CONFIG_DIRS") orelse return false;

    if (getFlavorXubuntu(ctx, xdg)) return true;
    if (getFlavorLubuntu(ctx, xdg)) return true;
    if (getFlavorKubuntu(ctx, xdg)) return true;
    if (getFlavorBudgie(ctx, xdg)) return true;
    if (getFlavorCinnamon(ctx, xdg)) return true;
    if (getFlavorMate(ctx, xdg)) return true;
    if (getFlavorStudio(ctx, xdg)) return true;
    if (getFlavorTouch(ctx, xdg)) return true;

    return false;
}

fn setFlavor(ctx: *Info, name: []const u8, id: []const u8) bool {
    ctx.name = name;
    ctx.pretty_name = name;
    ctx.id = id;
    ctx.id_like = "ubuntu";
    return true;
}

pub fn getFlavorXubuntu(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{ "xfce", "xubuntu" }))
        return false;
    return setFlavor(ctx, "Xubuntu", "xubuntu");
}

pub fn getFlavorKubuntu(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{ "kde", "plasma", "kubuntu" }))
        return false;
    return setFlavor(ctx, "Kubuntu", "kubuntu");
}

pub fn getFlavorLubuntu(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{ "lxde", "lubuntu" }))
        return false;
    return setFlavor(ctx, "Lubuntu", "lubuntu");
}

pub fn getFlavorBudgie(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{"budgie"}))
        return false;
    return setFlavor(ctx, "Ubuntu Budgie", "ubuntu-budgie");
}

pub fn getFlavorCinnamon(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{"cinnamon"}))
        return false;
    return setFlavor(ctx, "Ubuntu Cinnamon", "ubuntu-cinnamon");
}

pub fn getFlavorMate(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{"mate"}))
        return false;
    return setFlavor(ctx, "Ubuntu Mate", "ubuntu-mate");
}

pub fn getFlavorStudio(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{"studio"}))
        return false;
    return setFlavor(ctx, "Ubuntu Stduio", "ubuntu-studio");
}

pub fn getFlavorSway(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{"sway"}))
        return false;
    return setFlavor(ctx, "Ubuntu Sway Remix", "ubuntu-sway");
}

pub fn getFlavorTouch(ctx: *Info, dirs: []const u8) bool {
    if (!util.containsOneOf(dirs, &.{"touch"}))
        return false;
    return setFlavor(ctx, "Ubuntu Touch", "ubuntu-touch");
}
