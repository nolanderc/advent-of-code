const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

fn inputPath() []const u8 {
    const source_path = @src().file;
    comptime std.debug.assert(std.mem.endsWith(u8, source_path, ".zig"));
    const output_length = source_path.len - ".zig".len + ".input".len;
    comptime var output: [output_length]u8 = undefined;
    comptime std.mem.copy(u8, output[0 .. source_path.len - 4], source_path[0 .. source_path.len - 4]);
    comptime std.mem.copy(u8, output[source_path.len - 4 ..], ".input");
    return &output;
}

pub fn main() !void {
    const input = try util.loadInput(inputPath());
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

// Given a strategy on what to play, compute how much what score we get at rock-paper-scissors
fn part1(input: []const u8) !i64 {
    var rucksacks = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var sum: i64 = 0;

    while (rucksacks.next()) |sack| {
        const left = sack[0 .. sack.len / 2];
        const right = sack[sack.len / 2 ..];
        const shared = itemSet(left) & itemSet(right);
        sum += @ctz(shared);
    }

    return sum;
}

// Given a strategy on how to achieve an outcome, compute how what score we get at rock-paper-scissors
fn part2(input: []const u8) !i64 {
    var rucksacks = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var sum: i64 = 0;

    while (true) {
        const a = rucksacks.next() orelse break;
        const b = rucksacks.next() orelse break;
        const c = rucksacks.next() orelse break;
        const shared = itemSet(a) & itemSet(b) & itemSet(c);
        sum += @ctz(shared);
    }

    return sum;
}

fn itemSet(items: []const u8) u64 {
    var bits: u64 = 0;

    for (items) |item| {
        bits |= @as(u64, 1) << priority(item);
    }

    return bits;
}

fn priority(item: u8) u6 {
    if ('a' <= item and item <= 'z') return @intCast(u6, item - 'a' + 1);
    if ('A' <= item and item <= 'Z') return @intCast(u6, item - 'A' + 27);
    unreachable;
}

const sample =
    \\vJrwpWtwJgWrhcsFMMfFFhFp
    \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    \\PmmdzqPrVvPwwTWBwg
    \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    \\ttgJtRGJQctTZtZT
    \\CrZsJsPPZsGzwwsLwLmpwMDw
;

test "part1" {
    std.testing.log_level = .info;
    std.debug.print("\n", .{});
    try std.testing.expectEqual(@as(i64, 157), try part1(sample));
}

test "part2" {
    try std.testing.expectEqual(@as(i64, 70), try part2(sample));
}
