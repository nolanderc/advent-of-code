const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub const log_level = .info;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    const stopwatch = try util.Stopwatch.init();
    std.debug.print("part1: {s}\n", .{(try part1(input)).slice()});
    std.debug.print("part2: {}\n", .{try part2(input)});
    std.debug.print("time: {}\n", .{stopwatch});
}

fn part1(input: []const u8) !std.BoundedArray(u8, 32) {
    var lines = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var sum: i64 = 0;
    while (lines.next()) |line| {
        sum += try parseNumber(line);
    }
    return encodeNumber(sum);
}

fn parseNumber(text: []const u8) !i64 {
    var sum: i64 = 0;
    for (text) |digit| {
        sum *= 5;
        sum += switch (digit) {
            '2' => 2,
            '1' => 1,
            '0' => 0,
            '-' => -1,
            '=' => -2,
            else => return error.InvalidDigit,
        };
    }
    return sum;
}

// 25 = 100
fn encodeNumber(value: i64) !std.BoundedArray(u8, 32) {
    var buffer = std.BoundedArray(u8, 32){};
    const negative = value < 0;

    var powers = [1]i8{0} ** 32;
    var power: u8 = 0;

    var abs: u64 = std.math.absCast(value);
    while (abs != 0) : (power += 1) {
        powers[power] = @intCast(i8, abs % 5);
        abs /= 5;
    }

    var i: u32 = 0;
    while (i < power or powers[i] != 0) : (i += 1) {
        if (powers[i] > 2) {
            powers[i] -= 5;
            powers[i + 1] += 1;
        }
    }

    while (i > 0) {
        i -= 1;
        try buffer.append(switch (powers[i]) {
            -2 => '=',
            -1 => '-',
            0 => '0',
            1 => '1',
            2 => '2',
            else => unreachable,
        });
    }

    if (negative) {
        for (buffer.slice()) |*x| {
            x.* = switch (x.*) {
                '=' => '2',
                '-' => '1',
                '0' => '0',
                '1' => '-',
                '2' => '=',
                else => unreachable,
            };
        }
    }

    return buffer;
}

fn encodePositive(num: u64, power: u64) ?u8 {
    if (num / power == 0) return null;
}

fn part2(input: []const u8) !u64 {
    _ = input;
    return 0;
}

const sample =
    \\1=-0-2
    \\12111
    \\2=0=
    \\21
    \\2=01
    \\111
    \\20012
    \\112
    \\1=-1=
    \\1-12
    \\12
    \\1=
    \\122
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqualStrings("2=-1=0", (try part1(sample)).slice());
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 0), try part2(sample));
}
