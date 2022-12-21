const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub const log_level = .info;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    const stopwatch = try util.Stopwatch.init();
    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input)});
    std.debug.print("time: {}\n", .{stopwatch});
}

fn part1(input: []const u8) !i64 {
    var numbers = try parseInput(input);
    const links = try makeLinks(numbers);
    mix(numbers, links);
    return getCoords(numbers, links);
}

fn part2(input: []const u8) !i64 {
    const numbers = try parseInput(input);
    for (numbers) |*number| number.* *= 811589153;

    const links = try makeLinks(numbers);
    for (@as([10]void, undefined)) |_| mix(numbers, links);
    return getCoords(numbers, links);
}

fn makeLinks(numbers: []i64) ![]Link {
    const count = @intCast(u16, numbers.len);

    var links = try alloc.alloc(Link, numbers.len);
    for (links) |*link, index| {
        link.next = (@intCast(u16, index) + 1) % count;
        link.prev = (@intCast(u16, index) + count - 1) % count;
    }

    return links;
}

fn getCoords(numbers: []i64, links: []Link) i64 {
    const zero = std.mem.indexOfScalar(i64, numbers, 0) orelse {
        std.debug.panic("no zero in input", .{});
    };

    var sum: i64 = 0;
    var i: u16 = 0;
    var curr = zero;
    while (i <= 3000) : (i += 1) {
        if (i % 1000 == 0) sum += numbers[curr];
        curr = links[curr].next;
    }

    return sum;
}

fn mix(numbers: []i64, links: []Link) void {
    const count = @intCast(u16, numbers.len);

    for (numbers) |number, index_usize| {
        const curr = @intCast(u16, index_usize);
        const link = links[curr];

        var steps = number;
        steps = @mod(steps, count - 1);
        if (steps > count / 2) steps -= count - 1;

        if (steps == 0) continue;

        // unlink:
        links[link.prev].next = link.next;
        links[link.next].prev = link.prev;

        if (steps < 0) {
            var prev = link.prev;
            while (steps < 0) : (steps += 1) prev = links[prev].prev;

            // insert after:
            const next = links[prev].next;
            links[curr] = .{ .prev = prev, .next = next };
            links[prev].next = curr;
            links[next].prev = curr;
        }
        if (steps > 0) {
            var next = link.next;
            while (steps > 0) : (steps -= 1) next = links[next].next;

            // insert before:
            const prev = links[next].prev;
            links[curr] = .{ .prev = prev, .next = next };
            links[prev].next = curr;
            links[next].prev = curr;
        }
    }
}

fn printList(links: []const Link, numbers: []i64) void {
    var i: usize = 0;
    var curr: u16 = 0;
    while (i < links.len) : (i += 1) {
        if (i > 0) std.debug.print(", ", .{});
        std.debug.print("{}", .{numbers[curr]});
        curr = links[curr].next;
    }
    std.debug.print("\n", .{});
}

const Link = struct {
    next: u16,
    prev: u16,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("[{}, {}]", .{ self.prev, self.next });
    }
};

fn parseInput(text: []const u8) ![]i64 {
    var numbers = std.ArrayList(i64).init(alloc);

    var lines = std.mem.tokenize(u8, text, &std.ascii.whitespace);
    while (lines.next()) |line| {
        try numbers.append(util.parseInt(i16, line, 10));
    }

    return numbers.toOwnedSlice();
}

const sample =
    \\1
    \\2
    \\-3
    \\3
    \\-2
    \\0
    \\4
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 3), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 1623178306), try part2(sample));
}
