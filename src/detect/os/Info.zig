const std = @import("std");

name: []const u8,
pretty_name: []const u8,
id: []const u8,
id_like: ?[]const u8 = null,
variant: ?[]const u8 = null,
variant_id: ?[]const u8 = null,
version: ?[]const u8 = null,
version_id: ?[]const u8 = null,
codename: ?[]const u8 = null,
build_id: ?[]const u8 = null,
