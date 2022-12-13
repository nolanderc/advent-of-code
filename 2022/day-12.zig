const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !i64 {
    const grid = try Grid.parse(input);
    return try findPath(
        grid,
        grid.source,
        struct {
            target: @Vector(2, i32),

            fn isTarget(self: @This(), pos: @Vector(2, i32), height: u8) bool {
                _ = height;
                return @reduce(.And, pos == self.target);
            }

            fn isEdge(self: @This(), height: u8, new_height: u8) bool {
                _ = self;
                return new_height <= height + 1;
            }
        }{ .target = grid.target },
    ) orelse std.debug.panic("could not find path", .{});
}

fn part2(input: []const u8) !i64 {
    const grid = try Grid.parse(input);
    return try findPath(
        grid,
        grid.target,
        struct {
            fn isTarget(self: @This(), pos: @Vector(2, i32), height: u8) bool {
                _ = self;
                _ = pos;
                return height == 0;
            }

            fn isEdge(self: @This(), height: u8, new_height: u8) bool {
                _ = self;
                return height <= new_height + 1;
            }
        }{},
    ) orelse std.debug.panic("could not find path", .{});
}

fn findPath(
    grid: Grid,
    source: @Vector(2, i32),
    graph: anytype,
) !?u32 {
    var sources = std.ArrayList(@Vector(2, i32)).init(alloc);
    var targets = std.ArrayList(@Vector(2, i32)).init(alloc);

    try sources.ensureTotalCapacity(4 * grid.width * grid.height);
    try targets.ensureTotalCapacity(4 * grid.width * grid.height);

    var visited = try alloc.alloc(bool, grid.width * grid.height);
    std.mem.set(bool, visited, false);

    var distance: u32 = 0;

    try sources.append(source);
    while (true) : (distance += 1) {
        for (sources.items) |current| {
            const index = grid.index(current) orelse std.debug.panic("position not on grid: {}", .{current});
            const height = grid.heights[index];

            if (graph.isTarget(current, height)) return distance;

            if (visited[index]) continue;
            visited[index] = true;

            const deltas: [4]@Vector(2, i32) = .{
                .{ -1, 0 },
                .{ 1, 0 },
                .{ 0, -1 },
                .{ 0, 1 },
            };

            inline for (deltas) |delta| {
                const next = current + delta;
                if (grid.index(next)) |next_index| {
                    const next_height = grid.heights[next_index];
                    if (graph.isEdge(height, next_height)) {
                        try targets.append(next);
                    }
                }
            }
        }

        sources.clearRetainingCapacity();
        std.mem.swap(@TypeOf(sources), &sources, &targets);
    }

    return null;
}

const Grid = struct {
    source: @Vector(2, i32),
    target: @Vector(2, i32),

    width: usize,
    height: usize,
    heights: []const u8,

    fn inBounds(self: @This(), pos: @Vector(2, i32)) bool {
        return 0 <= pos[0] and pos[0] < self.width and 0 <= pos[1] and pos[1] < self.height;
    }

    fn index(self: @This(), pos: @Vector(2, i32)) ?usize {
        if (!self.inBounds(pos)) return null;
        return @intCast(u32, pos[0]) + @intCast(u32, pos[1]) * self.width;
    }

    fn parse(input: []const u8) !Grid {
        var width: usize = 0;
        var height: usize = 0;
        var source: @Vector(2, i32) = .{ 0, 0 };
        var target: @Vector(2, i32) = .{ 0, 0 };

        var heights = std.ArrayList(u8).init(alloc);
        try heights.ensureTotalCapacity(input.len);

        var lines = std.mem.tokenize(u8, input, &std.ascii.whitespace);
        while (lines.next()) |line| {
            width = @max(width, line.len);

            const row = height;
            height += 1;

            for (line) |char, col| {
                var cell = char;

                if (char == 'S') {
                    source = .{ @intCast(i32, col), @intCast(i32, row) };
                    cell = 'a';
                }
                if (char == 'E') {
                    target = .{ @intCast(i32, col), @intCast(i32, row) };
                    cell = 'z';
                }

                try heights.append(cell - 'a');
            }
        }

        return .{
            .source = source,
            .target = target,
            .width = width,
            .height = height,
            .heights = heights.toOwnedSlice(),
        };
    }
};

const sample =
    \\Sabqponm
    \\abcryxxl
    \\accszExk
    \\acctuvwj
    \\abdefghi
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 31), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 29), try part2(sample));
}
