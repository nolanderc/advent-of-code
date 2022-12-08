const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !usize {
    return simulateRope(input, 2);
}

fn part2(input: []const u8) !usize {
    return simulateRope(input, 10);
}

fn simulateRope(input: []const u8, comptime length: usize) !usize {
    var words = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var rope = [1]@Vector(2, i32){.{ 0, 0 }} ** length;

    var visited = std.AutoHashMap(@Vector(2, i32), void).init(alloc);
    try visited.put(rope[length - 1], {});

    while (words.next()) |direction| {
        var steps = util.parseInt(usize, words.next() orelse "0", 10);

        while (steps > 0) : (steps -= 1) {
            switch (direction[0]) {
                'R' => rope[0][0] += 1,
                'L' => rope[0][0] -= 1,
                'U' => rope[0][1] += 1,
                'D' => rope[0][1] -= 1,
                else => std.debug.panic("unknown direction: {s}", .{direction}),
            }

            var knot: usize = 1;
            while (knot < rope.len) : (knot += 1) {
                const delta = rope[knot - 1] - rope[knot];
                const dir = std.math.sign(delta);
                if (@reduce(.Or, delta != dir)) {
                    rope[knot] += dir;
                }
            }

            try visited.put(rope[length - 1], {});
        }
    }

    return visited.count();
}

const sample =
    \\R 4
    \\U 4
    \\L 3
    \\D 1
    \\R 4
    \\D 1
    \\L 5
    \\R 2
;

const large_sample =
    \\R 5
    \\U 8
    \\L 8
    \\D 3
    \\R 17
    \\D 10
    \\L 25
    \\U 20
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(usize, 13), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(usize, 1), try part2(sample));
    try std.testing.expectEqual(@as(usize, 36), try part2(large_sample));
}
