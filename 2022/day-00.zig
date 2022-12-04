const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    std.log.info("test", .{});
    const input = try util.loadInput("day-00.input");

    std.log.info("part1: {}", .{try part1(input)});
}

fn part1(input: []const u8) !i64 {
    var words = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var sum: i64 = 0;

    while (words.next()) |word| {
        const value = try std.fmt.parseInt(i64, word, 10);
        sum += value;
    }

    return sum;
}

test "part1" {
    try std.testing.expectEqual(try part1("1 2 3 4"), 10);
    try std.testing.expectEqual(try part1("100 20 3"), 123);
}
