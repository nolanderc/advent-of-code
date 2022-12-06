const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !usize {
    return findStart(input, 4);
}

fn part2(input: []const u8) !usize {
    return findStart(input, 14);
}

fn findStart(input: []const u8, length: usize) usize {
    var start: usize = length;

    outer: while (start <= input.len) : (start += 1) {
        const window = input[start - length .. start];

        for (window) |byte, index| {
            for (window[index + 1 ..]) |other| {
                if (byte == other) continue :outer;
            }
        }

        break;
    }

    return start;
}

test "part1" {
    std.testing.log_level = .info;
    std.debug.print("\n", .{});
    try std.testing.expectEqual(@as(usize, 7), try part1("mjqjpqmgbljsphdztnvjfqwrcgsmlb"));
    try std.testing.expectEqual(@as(usize, 5), try part1("bvwbjplbgvbhsrlpgdmjqwftvncz"));
    try std.testing.expectEqual(@as(usize, 6), try part1("nppdvjthqldpwncqszvftbrmjlhg"));
    try std.testing.expectEqual(@as(usize, 10), try part1("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg"));
    try std.testing.expectEqual(@as(usize, 11), try part1("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw"));
}

test "part2" {
    std.testing.log_level = .info;
    std.debug.print("\n", .{});
    try std.testing.expectEqual(@as(usize, 19), try part2("mjqjpqmgbljsphdztnvjfqwrcgsmlb"));
    try std.testing.expectEqual(@as(usize, 23), try part2("bvwbjplbgvbhsrlpgdmjqwftvncz"));
    try std.testing.expectEqual(@as(usize, 23), try part2("nppdvjthqldpwncqszvftbrmjlhg"));
    try std.testing.expectEqual(@as(usize, 29), try part2("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg"));
    try std.testing.expectEqual(@as(usize, 26), try part2("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw"));
}
