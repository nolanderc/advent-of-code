const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput("day-01.input");
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

// Find the maximum amount of calories held by a single elf
fn part1(input: []const u8) !i64 {
    var lines = std.mem.split(u8, input, "\n");
    var max_calories: i64 = 0;
    var current_calories: i64 = 0;

    while (lines.next()) |line| {
        const word = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (word.len == 0) {
            max_calories = @max(max_calories, current_calories);
            current_calories = 0;
            continue;
        }

        current_calories += try std.fmt.parseInt(i64, word, 10);
    }

    max_calories = @max(max_calories, current_calories);

    return max_calories;
}

// Find the maximum amount of calories held by any three elves
fn part2(input: []const u8) !i64 {
    var lines = std.mem.split(u8, input, "\n");
    var max_calories: [3]i64 = .{ 0, 0, 0 };
    var current_calories: i64 = 0;

    while (lines.next()) |line| {
        const word = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (word.len == 0) {
            insertMax(&max_calories, current_calories);
            current_calories = 0;
            continue;
        }

        current_calories += try std.fmt.parseInt(i64, word, 10);
    }

    insertMax(&max_calories, current_calories);

    var sum: i64 = 0;
    for (max_calories) |calories| {
        sum += calories;
    }
    return sum;
}

fn insertMax(values: []i64, new: i64) void {
    var value = new;
    var i: usize = 0;
    while (i < values.len) : (i += 1) {
        if (value > values[i]) {
            std.mem.swap(i64, &values[i], &value);
        }
    }
}

const sample =
    \\1000
    \\2000
    \\3000
    \\
    \\4000
    \\
    \\5000
    \\6000
    \\
    \\7000
    \\8000
    \\9000
    \\
    \\10000
;

test "part1" {
    try std.testing.expectEqual(@as(i64, 24000), try part1(sample));
}

test "part2" {
    try std.testing.expectEqual(@as(i64, 45000), try part2(sample));
}
