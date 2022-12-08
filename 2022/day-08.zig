const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !i64 {
    var grid_lines = std.ArrayList([]const u8).init(alloc);
    var lines = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var width: usize = 0;
    while (lines.next()) |line| {
        width = @max(width, line.len);
        try grid_lines.append(line);
    }

    const visible = try findVisible(grid_lines.items);
    var visible_count: i64 = 0;
    for (visible) |v| {
        if (v) visible_count += 1;
    }
    return visible_count;
}

fn findVisible(grid: []const []const u8) ![]bool {
    const height = grid.len;
    const width = grid[0].len;
    var visible = try alloc.alloc(bool, width * height);

    var row: usize = 0;
    while (row < height) : (row += 1) {
        const x = @intCast(i32, width - 1);
        const y = @intCast(i32, row);
        scanVisible(visible, grid, .{ 0, y }, .{ 1, 0 });
        scanVisible(visible, grid, .{ x, y }, .{ -1, 0 });
    }

    var col: usize = 0;
    while (col < width) : (col += 1) {
        const x = @intCast(i32, col);
        const y = @intCast(i32, height - 1);
        scanVisible(visible, grid, .{ x, 0 }, .{ 0, 1 });
        scanVisible(visible, grid, .{ x, y }, .{ 0, -1 });
    }

    return visible;
}

fn scanVisible(visible: []bool, grid: []const []const u8, start: @Vector(2, i32), delta: @Vector(2, i32)) void {
    var ray = Ray{
        .height = @intCast(u32, grid.len),
        .width = @intCast(u32, grid[0].len),
        .pos = start,
        .delta = delta,
    };

    var tallest: u8 = 0;
    const width = grid[0].len;

    while (ray.next()) |pos| {
        const tree = grid[pos.row][pos.col];
        if (tree > tallest) {
            tallest = tree;
            visible[width * pos.row + pos.col] = true;
        }
    }
}

fn part2(input: []const u8) !u64 {
    var grid_lines = std.ArrayList([]const u8).init(alloc);
    var lines = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    while (lines.next()) |line| {
        try grid_lines.append(line);
    }

    const scores = try findScore(grid_lines.items);
    var max: u64 = 0;
    for (scores) |score| {
        max = @max(max, score);
    }
    return max;
}

fn findScore(grid: []const []const u8) ![]u64 {
    const height = grid.len;
    const width = grid[0].len;
    var scores = try alloc.alloc(u64, width * height);
    std.mem.set(u64, scores, 1);

    var row: usize = 0;
    while (row < height) : (row += 1) {
        const x = @intCast(i32, width - 1);
        const y = @intCast(i32, row);
        scanScore(scores, grid, .{ 0, y }, .{ 1, 0 });
        scanScore(scores, grid, .{ x, y }, .{ -1, 0 });
    }

    var col: usize = 0;
    while (col < width) : (col += 1) {
        const x = @intCast(i32, col);
        const y = @intCast(i32, height - 1);
        scanScore(scores, grid, .{ x, 0 }, .{ 0, 1 });
        scanScore(scores, grid, .{ x, y }, .{ 0, -1 });
    }

    return scores;
}

fn scanScore(scores: []u64, grid: []const []const u8, start: @Vector(2, i32), delta: @Vector(2, i32)) void {
    var running_scores = [1]u64{0} ** 10;
    var ray = Ray{
        .height = @intCast(u32, grid.len),
        .width = @intCast(u32, grid[0].len),
        .pos = start,
        .delta = delta,
    };

    const width = grid[0].len;

    while (ray.next()) |pos| {
        const height = grid[pos.row][pos.col] - '0';
        scores[width * pos.row + pos.col] *= running_scores[height];

        // shorter (or equally high) trees can only see us
        for (running_scores[0 .. height + 1]) |*score| score.* = 1;

        // taller trees can see all trees we see, as well as this tree
        for (running_scores[height + 1 ..]) |*score| score.* += 1;
    }
}

const Ray = struct {
    width: u32,
    height: u32,
    pos: @Vector(2, i32),
    delta: @Vector(2, i32),

    fn next(self: *@This()) ?struct { row: u32, col: u32 } {
        const pos = self.pos;
        if (0 <= pos[0] and pos[0] < self.width and 0 <= pos[1] and pos[1] < self.height) {
            const col = @intCast(u32, pos[0]);
            const row = @intCast(u32, pos[1]);
            self.pos += self.delta;
            return .{ .row = row, .col = col };
        } else {
            return null;
        }
    }
};

fn scan(grid: []const []const u8, start: @Vector(2, i32), delta: @Vector(2, i32), callback: anytype) void {
    const height = grid.len;
    const width = grid[0].len;

    var pos = start;
    while (0 <= pos[0] and pos[0] < width and 0 <= pos[1] and pos[1] < height) : (pos += delta) {
        const col = @intCast(usize, pos[0]);
        const row = @intCast(usize, pos[1]);

        const tree = grid[row][col];
        callback.onTree(row, col, tree);
    }
}

const sample =
    \\30373
    \\25512
    \\65332
    \\33549
    \\35390
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 21), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 8), try part2(sample));
}
