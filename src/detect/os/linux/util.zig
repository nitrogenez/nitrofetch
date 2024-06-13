const std = @import("std");

pub fn containsOneOf(haystack: []const u8, needles: []const []const u8) bool {
    return for (needles) |needle| {
        if (std.mem.indexOf(u8, haystack, needle) != null) break true;
    } else false;
}
