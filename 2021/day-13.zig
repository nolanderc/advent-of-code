const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 13,
    },
    .input = Paper,
    .format = .custom,
};

const Paper = struct {
    points: []Point,
    instructions: []Instruction,

    const Point = struct {
        x: i32,
        y: i32,
    };

    const Instruction = struct {
        axis: enum { x, y },
        position: i32,
    };

    pub fn parse(text: []const u8) !@This() {
        var lines = std.mem.split(u8, text, "\n");

        var points = std.ArrayList(Point).init(alloc);
        defer points.deinit();
        var instructions = std.ArrayList(Instruction).init(alloc);
        defer instructions.deinit();

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, &std.ascii.spaces);
            if (trimmed.len == 0) break;
            const point = try utils.parse.parsePattern(Point, "{},{}", trimmed);
            try points.append(point);
        }

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, &std.ascii.spaces);
            const instruction = try utils.parse.parsePattern(Instruction, "fold along {}={}", trimmed);
            try instructions.append(instruction);
        }

        return @This(){
            .points = points.toOwnedSlice(),
            .instructions = instructions.toOwnedSlice(),
        };
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(paper: config.input) !usize {
    performInstruction(paper.points, paper.instructions[0]);

    std.sort.sort(Paper.Point, paper.points, {}, struct {
        fn lessThan(_: void, a: Paper.Point, b: Paper.Point) bool {
            if (a.x != b.x) return a.x < b.x;
            return a.y < b.y;
        }
    }.lessThan);

    const unique = dedup(Paper.Point, paper.points, struct {
        fn equal(a: Paper.Point, b: Paper.Point) bool {
            return a.x == b.x and a.y == b.y;
        }
    }.equal);

    return unique.len;
}

fn part2(paper: config.input) !void {
    for (paper.instructions) |instruction| {
        performInstruction(paper.points, instruction);
    }

    try printPoints(paper.points);
}

fn printPoints(points: []Paper.Point) !void {
    var min_x: i32 = points[0].x;
    var max_x: i32 = points[0].x;

    var min_y: i32 = points[0].y;
    var max_y: i32 = points[0].y;

    for (points) |point| {
        min_x = std.math.min(min_x, point.x);
        max_x = std.math.max(max_x, point.x);
        min_y = std.math.min(min_y, point.y);
        max_y = std.math.max(max_y, point.y);
    }

    const width = @intCast(u32, max_x - min_x) + 1;
    const height = @intCast(u32, max_y - min_y) + 1;

    var grid = try alloc.alloc(u8, width * height);
    std.mem.set(u8, grid, ' ');

    for (points) |point| {
        const x = @intCast(u32, point.x - min_x);
        const y = @intCast(u32, point.y - min_y);
        grid[x + y * width] = '#';
    }

    var stdout = std.io.getStdOut().writer();
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        try stdout.writeAll(grid[y * width .. (y + 1) * width]);
        try stdout.writeByte('\n');
    }
}

fn dedup(comptime T: type, slice: []T, equal: fn (T, T) bool) []T {
    var write: usize = 0;
    var read: usize = 1;
    while (read < slice.len) : (read += 1) {
        if (!equal(slice[write], slice[read])) {
            write += 1;
            slice[write] = slice[read];
        }
    }
    return slice[0 .. write + 1];
}

fn performInstruction(points: []Paper.Point, instruction: Paper.Instruction) void {
    for (points) |*point| {
        const coord = switch (instruction.axis) {
            .x => &point.x,
            .y => &point.y,
        };

        if (coord.* > instruction.position) {
            coord.* = 2 * instruction.position - coord.*;
        }
    }
}

const sample =
    \\6,10
    \\0,14
    \\9,10
    \\0,3
    \\10,4
    \\4,11
    \\6,0
    \\6,12
    \\4,1
    \\0,13
    \\10,12
    \\3,4
    \\3,0
    \\8,4
    \\1,10
    \\2,14
    \\8,10
    \\9,0
    \\
    \\fold along y=7
    \\fold along x=5
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 17);
}
