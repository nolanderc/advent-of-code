const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput("day-02.input");
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

// Given a strategy on what to play, compute how much what score we get at rock-paper-scissors
fn part1(input: []const u8) !i64 {
    var lines = std.mem.tokenize(u8, input, "\n");
    var score: i64 = 0;

    while (lines.next()) |line| {
        const opponent = line[0] - 'A';
        const me = line[2] - 'X';

        // me = opponent - 1 -> outcome = 0
        // me = opponent     -> outcome = 1
        // me = opponent + 1 -> outcome = 2
        //
        // Thus we have `outcome = me - opponent + 1 (mod 3)`
        //
        // which is eqiuvalent to `me - opponent + 4 (mod 3)`, which we use to avoid underflow
        const outcome = (4 + me - opponent) % 3;

        score += me + 1;
        score += 3 * outcome;
    }

    return score;
}

// Given a strategy on how to achieve an outcome, compute how what score we get at rock-paper-scissors
fn part2(input: []const u8) !i64 {
    var lines = std.mem.tokenize(u8, input, "\n");
    var score: i64 = 0;

    while (lines.next()) |line| {
        const opponent = line[0] - 'A';
        const outcome = line[2] - 'X';

        // `outcome = 0 -> me = opponent - 1`
        // `outcome = 1 -> me = opponent`
        // `outcome = 2 -> me = opponent + 1`
        //
        // Thus we have `me = opponet - 1 + outcome`
        //
        // We have `2 + outcome = -1 + outcome (mod 3)`
        const me = (opponent + (2 + outcome)) % 3;

        score += outcome * 3;
        score += me + 1;
    }

    return score;
}

const sample =
    \\A Y
    \\B X
    \\C Z
;

test "part1" {
    try std.testing.expectEqual(@as(i64, 15), try part1(sample));
}

test "part2" {
    try std.testing.expectEqual(@as(i64, 12), try part2(sample));
}
