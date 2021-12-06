const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 5,
    },
    .input = Line,
    .format = .{ .pattern = "{} -> {}" },
};

const Line = struct {
    start: Point,
    end: Point,
};

const Point = struct {
    x: i32,
    y: i32,

    pub fn parse(comptime _: []const u8, text: []const u8) !Point {
        return utils.parse.parsePattern(Point, "{},{}", text);
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(lines: []config.input) !u32 {
    return countOverlapping(lines, .axis);
}

fn part2(lines: []config.input) !u32 {
    return countOverlapping(lines, .diagonal);
}

fn signum(x: i32) i32 {
    if (x < 0) return -1;
    if (x > 0) return 1;
    return 0;
}

fn countOverlapping(lines: []const Line, kind: enum { axis, diagonal }) !u32 {
    var points = std.AutoHashMap(Point, u32).init(alloc);
    defer points.deinit();
    for (lines) |line| {
        const start = line.start;
        const end = line.end;

        const dx: i32 = signum(end.x - start.x);
        const dy: i32 = signum(end.y - start.y);

        if (kind == .axis and !(dx == 0 or dy == 0)) continue;

        var point = start;
        while (point.x != end.x + dx or point.y != end.y + dy) : ({
            point.x += dx;
            point.y += dy;
        }) {
            (try points.getOrPutValue(point, 0)).value_ptr.* += 1;
        }
    }

    var count: u32 = 0;
    var entries = points.iterator();
    while (entries.next()) |entry| {
        if (entry.value_ptr.* >= 2) {
            count += 1;
        }
    }

    return count;
}

const sample =
    \\0,9 -> 5,9
    \\8,0 -> 0,8
    \\9,4 -> 3,4
    \\2,2 -> 2,1
    \\7,0 -> 7,4
    \\6,4 -> 2,0
    \\0,9 -> 2,9
    \\3,4 -> 1,4
    \\0,0 -> 8,8
    \\5,5 -> 8,2
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 5);
}

test "part 2 sample" {
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 12);
}
