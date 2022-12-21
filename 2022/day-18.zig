const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub const log_level = .info;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input)});
}

fn part1(input: []const u8) !u64 {
    var coords = try parseInput(input);
    return pointSurfaceArea(coords);
}

fn pointSurfaceArea(coords: []Point) u64 {
    var sum: u64 = 0;

    for (coords) |*coord| std.mem.rotate(u8, coord, 1);
    std.sort.sort(Point, coords, {}, orderPoint);
    sum += countAdjacent(coords);

    for (coords) |*coord| std.mem.rotate(u8, coord, 1);
    std.sort.sort(Point, coords, {}, orderPoint);
    sum += countAdjacent(coords);

    for (coords) |*coord| std.mem.rotate(u8, coord, 1);
    std.sort.sort(Point, coords, {}, orderPoint);
    sum += countAdjacent(coords);

    return coords.len * 6 - 2 * sum;
}

fn countAdjacent(coords: []Point) u64 {
    var sum: u64 = 0;
    for (coords[1..]) |curr, index| {
        const prev = coords[index];
        const is_adjacent = prev[0] == curr[0] and prev[1] == curr[1] and prev[2] + 1 == curr[2];
        sum += @boolToInt(is_adjacent);
    }
    return sum;
}

fn orderPoint(_: void, a: Point, b: Point) bool {
    return std.mem.order(
        u8,
        &.{ a[0], a[1], a[2] },
        &.{ b[0], b[1], b[2] },
    ) == .lt;
}

fn part2(input: []const u8) !u64 {
    var coords = try parseInput(input);

    var bounds = @splat(3, @as(u8, 0));
    for (coords) |coord| {
        bounds[0] = @max(bounds[0], coord[0] + 1);
        bounds[1] = @max(bounds[1], coord[1] + 1);
        bounds[2] = @max(bounds[2], coord[2] + 1);
    }

    var cells = try alloc.alloc(Cell, @as(usize, bounds[0]) * bounds[1] * bounds[2]);
    std.mem.set(Cell, cells, .{ .inside = false, .visited = false });
    for (coords) |coord| cells[gridIndex(coord, bounds)] = .{ .inside = true, .visited = true };

    var stack = try std.ArrayList(u15).initCapacity(alloc, std.math.maxInt(u15));
    var visited = try std.ArrayList(u15).initCapacity(alloc, std.math.maxInt(u15));
    var inside_count: usize = coords.len;

    for (cells) |_, index| {
        try stack.append(@intCast(u15, index));
        visited.clearRetainingCapacity();

        var outside = false;
        while (stack.popOrNull()) |curr| {
            if (cells[curr].visited) continue;
            cells[curr].visited = true;
            try visited.append(curr);

            const adjacent = adjacentIndices(curr, bounds);
            for (adjacent) |next| {
                if (next) |n| {
                    try stack.append(n);
                } else {
                    outside = true;
                }
            }
        }

        if (!outside) {
            inside_count += visited.items.len;
            for (visited.items) |v| {
                cells[v].inside = true;
            }
        }
    }

    var surface_area: u64 = 0;
    for (cells) |cell, curr| {
        if (cell.inside) {
            const adjacent = adjacentIndices(@intCast(u15, curr), bounds);
            for (adjacent) |next| {
                const is_open = next == null or !cells[next.?].inside;
                surface_area += @boolToInt(is_open);
            }
        }
    }

    return surface_area;
}

const Cell = packed struct {
    inside: bool,
    visited: bool,
};

fn adjacentIndices(base: u15, bounds: @Vector(3, u8)) [6]?u15 {
    const directions: [6]@Vector(3, i2) = .{
        .{ -1, 0, 0 },
        .{ 1, 0, 0 },
        .{ 0, -1, 0 },
        .{ 0, 1, 0 },
        .{ 0, 0, -1 },
        .{ 0, 0, 1 },
    };

    const point = gridPoint(base, bounds);

    var adjacent: [6]?u15 = undefined;
    inline for (directions) |dir, index| {
        const x = @intCast(i16, point[0]) + dir[0];
        const y = @intCast(i16, point[1]) + dir[1];
        const z = @intCast(i16, point[2]) + dir[2];

        if (0 <= x and x < bounds[0] and 0 <= y and y < bounds[1] and 0 <= z and z < bounds[2]) {
            adjacent[index] = @intCast(u15, gridIndex(.{
                @intCast(u8, x),
                @intCast(u8, y),
                @intCast(u8, z),
            }, bounds));
        } else {
            adjacent[index] = null;
        }
    }

    return adjacent;
}

fn gridIndex(p: Point, bounds: @Vector(3, u8)) usize {
    return p[0] + @as(usize, bounds[0]) * (p[1] + @as(usize, bounds[1]) * p[2]);
}

fn gridPoint(index: u15, bounds: @Vector(3, u8)) Point {
    var point: Point = undefined;
    var i = index;
    point[0] = @intCast(u8, i % bounds[0]);
    i /= bounds[0];
    point[1] = @intCast(u8, i % bounds[1]);
    i /= bounds[1];
    point[2] = @intCast(u8, i);
    return point;
}

const Point = [3]u8;

fn parseInput(text: []const u8) ![]Point {
    var lines = std.mem.tokenize(u8, text, &std.ascii.whitespace);
    var coords = std.ArrayList(Point).init(alloc);
    while (lines.next()) |line| {
        const matches = util.extractMatches("%,%,%", line) orelse std.debug.panic("invalid coord: {s}", .{line});
        try coords.append(.{
            util.parseInt(u8, matches[0], 10),
            util.parseInt(u8, matches[1], 10),
            util.parseInt(u8, matches[2], 10),
        });
    }
    return coords.toOwnedSlice();
}

const sample =
    \\2,2,2
    \\1,2,2
    \\3,2,2
    \\2,1,2
    \\2,3,2
    \\2,2,1
    \\2,2,3
    \\2,2,4
    \\2,2,6
    \\1,2,5
    \\3,2,5
    \\2,1,5
    \\2,3,5
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 64), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 58), try part2(sample));
}
