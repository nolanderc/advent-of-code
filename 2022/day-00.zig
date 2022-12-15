const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input)});
}

fn part1(input: []const u8) !u64 {
    _ = input;
    return 0;
}

fn part2(input: []const u8) !u64 {
    _ = input;
    return 0;
}

const sample =
    \\<sample goes here>
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 0), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 0), try part2(sample));
}
