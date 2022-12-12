const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !i64 {
    const Entry = struct {
        pos: @Vector(2, i32),
        distance: u16,

        fn shortest(context: void, a: @This(), b: @This()) std.math.Order {
            _ = context;
            return std.math.order(a.distance, b.distance);
        }
    };

    const grid = try Grid.parse(input);

    var entries = std.PriorityQueue(Entry, void, Entry.shortest).init(alloc, {});
    try entries.ensureTotalCapacity(grid.width * grid.height);

    var visited = try alloc.alloc(?u16, grid.width * grid.height);
    std.mem.set(?u16, visited, null);

    try entries.add(.{ .pos = grid.source, .distance = 0 });
    while (entries.removeOrNull()) |current| {
        if (@reduce(.And, current.pos == grid.target)) {
            return current.distance;
        }

        const index = grid.index(current.pos) orelse std.debug.panic("position not on grid: {}", .{current.pos});
        if (visited[index]) |*previous| {
            if (current.distance >= previous.*) continue;
            previous.* = current.distance;
        } else {
            visited[index] = current.distance;
        }

        const deltas: [4]@Vector(2, i32) = .{
            .{ -1, 0 },
            .{ 1, 0 },
            .{ 0, -1 },
            .{ 0, 1 },
        };

        const height = grid.heights[index];

        inline for (deltas) |delta| {
            const new = current.pos + delta;
            if (grid.index(new)) |new_index| {
                const new_height = grid.heights[new_index];
                if (new_height <= height + 1) {
                    try entries.add(.{ .pos = new, .distance = current.distance + 1 });
                }
            }
        }
    }

    std.debug.panic("could not find path to end", .{});
}

fn part2(input: []const u8) !i64 {
    const Entry = struct {
        pos: @Vector(2, i32),
        distance: u16,

        fn shortest(context: void, a: @This(), b: @This()) std.math.Order {
            _ = context;
            return std.math.order(a.distance, b.distance);
        }
    };

    const grid = try Grid.parse(input);

    var entries = std.PriorityQueue(Entry, void, Entry.shortest).init(alloc, {});
    try entries.ensureTotalCapacity(grid.width * grid.height);

    var visited = try alloc.alloc(?u16, grid.width * grid.height);
    std.mem.set(?u16, visited, null);

    try entries.add(.{ .pos = grid.target, .distance = 0 });
    while (entries.removeOrNull()) |current| {
        const index = grid.index(current.pos) orelse std.debug.panic("position not on grid: {}", .{current.pos});
        const height = grid.heights[index];

        if (height == 0) {
            return current.distance;
        }

        if (visited[index]) |*previous| {
            if (current.distance >= previous.*) continue;
            previous.* = current.distance;
        } else {
            visited[index] = current.distance;
        }

        const deltas: [4]@Vector(2, i32) = .{
            .{ -1, 0 },
            .{ 1, 0 },
            .{ 0, -1 },
            .{ 0, 1 },
        };

        inline for (deltas) |delta| {
            const new = current.pos + delta;
            if (grid.index(new)) |new_index| {
                const new_height = grid.heights[new_index];
                if (height <= new_height + 1) {
                    try entries.add(.{ .pos = new, .distance = current.distance + 1 });
                }
            }
        }
    }

    std.debug.panic("could not find path to end", .{});
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
