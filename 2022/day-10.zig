const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2:\n{s}", .{try part2(input)});
}

fn part1(input: []const u8) !i64 {
    var x: i64 = 1;
    var cycle: u32 = 0;
    var words = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var strength: i64 = 0;

    while (words.next()) |instruction| {
        const is_add = std.mem.eql(u8, instruction, "addx");
        var latency: u32 = if (is_add) 2 else 1;

        while (latency > 0) : (latency -= 1) {
            cycle += 1;
            if (isMeasureCycle(cycle)) {
                strength += cycle * x;
            }
        }

        if (is_add) {
            const amount = util.parseInt(i64, words.next() orelse "0", 10);
            x += amount;
        } else if (std.mem.eql(u8, instruction, "noop")) {
            continue;
        } else {
            std.debug.panic("unknown instruction: {s}", .{instruction});
        }
    }

    return strength;
}

fn isMeasureCycle(cycle: usize) bool {
    return switch (cycle) {
        20, 60, 100, 140, 180, 220 => true,
        else => false,
    };
}

fn part2(input: []const u8) ![6 * (40 + 1)]u8 {
    var x: i64 = 1;
    var cycle: u32 = 0;
    var words = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var crt: [6 * (40 + 1)]u8 = undefined;

    while (words.next()) |instruction| {
        const is_add = std.mem.eql(u8, instruction, "addx");
        var latency: u32 = if (is_add) 2 else 1;

        while (latency > 0) : (latency -= 1) {
            const row = cycle / 40;
            const col = cycle % 40;
            crt[41 * row + col] = if (col + 1 < x or x + 1 < col) ' ' else 'O';
            cycle += 1;
        }

        if (is_add) {
            const amount = util.parseInt(i64, words.next() orelse "0", 10);
            x += amount;
        } else if (std.mem.eql(u8, instruction, "noop")) {
            continue;
        } else {
            std.debug.panic("unknown instruction: {s}", .{instruction});
        }
    }

    var row: usize = 0;
    while (row < 6) : (row += 1) {
        crt[41 * row + 40] = '\n';
    }

    return crt;
}

const sample = @embedFile("day-10.sample");

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 13140), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    const expected =
        \\##..##..##..##..##..##..##..##..##..##..
        \\###...###...###...###...###...###...###.
        \\####....####....####....####....####....
        \\#####.....#####.....#####.....#####.....
        \\######......######......######......####
        \\#######.......#######.......#######.....
        \\
    ;
    try std.testing.expectEqualStrings(expected, &try part2(sample));
}
