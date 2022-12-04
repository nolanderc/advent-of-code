const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !i64 {
    var pairs = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var count: i64 = 0;

    while (pairs.next()) |pair_text| {
        const pair = parsePair(pair_text);

        const a = pair[0];
        const b = pair[1];

        const a_contains_b = a[0] <= b[0] and b[1] <= a[1];
        const b_contains_a = b[0] <= a[0] and a[1] <= b[1];

        count += @boolToInt(a_contains_b or b_contains_a);
    }

    return count;
}

fn part2(input: []const u8) !i64 {
    var pairs = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var count: i64 = 0;

    while (pairs.next()) |pair_text| {
        const pair = parsePair(pair_text);

        const a = pair[0];
        const b = pair[1];

        const overlap = @max(a[0], b[0]) <= @min(a[1], b[1]);

        count += @boolToInt(overlap);
    }

    return count;
}

fn parsePair(pair: []const u8) [2][2]u8 {
    const endpoints = util.extractMatches("%-%,%-%", pair) orelse {
        std.debug.panic("invalid pair: {s}", .{pair});
    };
    return .{ .{
        util.parseInt(u8, endpoints[0], 10),
        util.parseInt(u8, endpoints[1], 10),
    }, .{
        util.parseInt(u8, endpoints[2], 10),
        util.parseInt(u8, endpoints[3], 10),
    } };
}

const sample =
    \\2-4,6-8
    \\2-3,4-5
    \\5-7,7-9
    \\2-8,3-7
    \\6-6,4-6
    \\2-6,4-8
;

test "part1" {
    std.testing.log_level = .info;
    std.debug.print("\n", .{});
    try std.testing.expectEqual(@as(i64, 2), try part1(sample));
}

test "part2" {
    try std.testing.expectEqual(@as(i64, 4), try part2(sample));
}
