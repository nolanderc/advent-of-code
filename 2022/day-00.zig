const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !i64 {
    _ = input;
    return 0;
}

fn part2(input: []const u8) !i64 {
    _ = input;
    return 0;
}

const sample =
    \\<sample goes here>
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 2), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 4), try part2(sample));
}
