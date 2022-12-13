const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

const visualize = false;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !u64 {
    const lines = try parseInput(input);
    var grid = try Grid.init(lines);

    var count: u64 = 0;
    outer: while (true) : (count += 1) {
        var grain = Point{ 500, 0 };

        while (grid.inBounds(grain)) {
            grain[1] += 1;
            if ((grid.get(grain) orelse .air) == .air) continue;
            grain[0] -= 1;
            if ((grid.get(grain) orelse .air) == .air) continue;
            grain[0] += 2;
            if ((grid.get(grain) orelse .air) == .air) continue;

            grain[0] -= 1;
            grain[1] -= 1;
            grid.set(grain, .sand);
            continue :outer;
        }

        return count;
    }
}

fn part2(input: []const u8) !u64 {
    const lines = try parseInput(input);
    var grid = try Grid.init(lines);

    var buffer = std.io.bufferedWriter(std.io.getStdOut().writer());

    var stack = try std.ArrayList(Point).initCapacity(alloc, @intCast(usize, grid.max[1]) + 1);
    try stack.append(.{ 500, 0 });

    var drop: u64 = 0;
    var count: u64 = 0;
    while (stack.items.len > 0) {
        var grain = stack.items[stack.items.len - 1];

        grain[1] += 1;
        if ((grid.get(grain) orelse .rock) == .air) {
            try stack.append(grain);
            continue;
        }

        grain[0] -= 1;
        if ((grid.get(grain) orelse .rock) == .air) {
            try stack.append(grain);
            continue;
        }

        grain[0] += 2;
        if ((grid.get(grain) orelse .rock) == .air) {
            try stack.append(grain);
            continue;
        }

        grain = stack.pop();

        const sleep = std.math.lossyCast(u64, 1e7 / @intToFloat(f64, count + 1));

        if (visualize) {
            for (stack.items) |pos| {
                drop += 1;
                if (drop % @max(1, count / 128) != 0) continue;

                grid.set(pos, .sand);
                const writer = buffer.writer();
                try writer.writeAll("\x1b[H");
                try grid.print(writer);
                try writer.context.flush();
                std.time.sleep(sleep);
                grid.set(pos, .air);
            }
        }

        grid.set(grain, .sand);
        count += 1;

        if (visualize) {
            const writer = buffer.writer();
            try writer.writeAll("\x1b[H");
            try grid.print(writer);
            try writer.context.flush();
            std.time.sleep(sleep);
        }
    }

    return count;
}

const Grid = struct {
    min: Point,
    max: Point,
    size: @Vector(2, usize),
    cells: []Cell,
    changed: ?std.ArrayList(Point),

    fn init(lines: []Line) !@This() {
        var depth: i32 = 0;

        for (lines) |line| {
            for (line) |point| {
                depth = @max(depth, point[1]);
            }
        }

        // make space for the floor
        depth += 1;

        // make space for the spawning position of the sand
        var min = Point{ 500 - depth - 1, 0 };
        var max = Point{ 500 + depth + 1, depth };

        const size = @intCast(@Vector(2, usize), max - min + Point{ 1, 1 });
        var cells = try alloc.alloc(Cell, size[0] * size[1]);
        std.mem.set(Cell, cells, .air);

        var grid = Grid{
            .min = min,
            .max = max,
            .size = size,
            .cells = cells,
            .changed = null,
        };

        // add all the lines to the grid
        for (lines) |line| {
            var prev = line[0];

            for (line[1..]) |curr| {
                const delta = curr - prev;

                const valid_line = delta[0] == 0 or delta[1] == 0;
                if (!valid_line) std.debug.panic("angled lines not supported: {} -> {}", .{ prev, curr });

                const step = std.math.sign(delta);
                while (@reduce(.Or, prev != curr)) : (prev += step) grid.set(prev, .rock);
                grid.set(curr, .rock);
            }
        }

        return grid;
    }

    fn index(self: @This(), point: Point) usize {
        const p = @intCast(@Vector(2, usize), point - self.min);
        return p[0] + p[1] * self.size[0];
    }

    fn set(self: *@This(), point: Point, cell: Cell) void {
        self.cells[self.index(point)] = cell;
        if (self.changed) |*changed| {
            changed.append(point) catch {};
        }
    }

    fn get(self: *@This(), point: Point) ?Cell {
        if (!self.inBounds(point)) return null;
        return self.cells[self.index(point)];
    }

    fn inBounds(self: @This(), point: Point) bool {
        return @reduce(.And, self.min <= point) and @reduce(.And, point <= self.max);
    }

    fn print(self: *@This(), writer: anytype) !void {
        if (self.changed) |*changed| {
            for (changed.items) |delta| {
                const cell = self.get(delta) orelse continue;
                const p = delta - self.min;
                try writer.print("\x1b[{};{}H{s}", .{ 1 + p[1], 1 + p[0], cell.display() });
            }
            changed.clearRetainingCapacity();
            try writer.print("\x1b[{};{}H", .{ 1 + self.size[1], 1 + self.size[0] });
        } else {
            var row: usize = 0;
            while (row < self.size[1]) : (row += 1) {
                var col: usize = 0;
                while (col < self.size[0]) : (col += 1) {
                    try writer.writeAll(self.cells[col + row * self.size[0]].display());
                }
                try writer.writeAll("\n");
            }
            self.changed = std.ArrayList(Point).init(alloc);
        }
    }
};

const Cell = enum {
    air,
    rock,
    sand,

    fn display(self: @This()) []const u8 {
        return switch (self) {
            .air => "\x1b[2m.\x1b[m",
            .rock => "\x1b[32m#\x1b[m",
            .sand => "\x1b[1m\x1b[38;5;255mO\x1b[m",
        };
    }
};
const Point = @Vector(2, i32);
const Line = []Point;

fn parseInput(text: []const u8) ![]Line {
    var rows = std.mem.split(u8, std.mem.trim(u8, text, &std.ascii.whitespace), "\n");
    var lines = std.ArrayList(Line).init(alloc);

    while (rows.next()) |row| {
        var components = std.mem.split(u8, std.mem.trim(u8, row, &std.ascii.whitespace), " -> ");

        var points = std.ArrayList(Point).init(alloc);
        try points.ensureTotalCapacity(16);

        while (components.next()) |point| {
            const mid = std.mem.indexOfScalar(u8, point, ',') orelse std.debug.panic("invalid point: {s}", .{point});
            const x = util.parseInt(i32, point[0..mid], 10);
            const y = util.parseInt(i32, point[mid + 1 ..], 10);
            try points.append(.{ x, y });
        }

        try lines.append(points.toOwnedSlice());
    }

    return lines.toOwnedSlice();
}

const sample =
    \\498,4 -> 498,6 -> 496,6
    \\503,4 -> 502,4 -> 502,9 -> 494,9
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 24), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 93), try part2(sample));
}
