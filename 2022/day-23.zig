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

fn part1(input: []const u8) !u64 {
    var points = try parseInput(input);
    var simulator = try Simulator.init(points);

    var turns: usize = 10;
    while (turns > 0) : (turns -= 1) _ = simulator.step();

    var min = simulator.points[0];
    var max = simulator.points[0];
    for (points) |p| {
        min = @min(min, p);
        max = @max(max, p);
    }
    const size = @intCast(@Vector(2, u64), max - min) + @Vector(2, u64){ 1, 1 };
    return size[0] * size[1] - simulator.points.len;
}

fn part2(input: []const u8) !u64 {
    var points = try parseInput(input);
    var simulator = try Simulator.init(points);

    var turns: usize = 1;
    while (simulator.step()) turns += 1;

    return turns;
}

const Simulator = struct {
    points: []Point,
    active: std.AutoHashMap(Point, void),
    proposed: []Point,
    proposed_count: std.AutoHashMap(Point, u32),
    deltas: [4]@Vector(2, i32),

    fn init(points: []Point) !@This() {
        var self: @This() = undefined;
        self.points = points;

        // the set of active points
        self.active = std.AutoHashMap(Point, void).init(alloc);
        try self.active.ensureTotalCapacity(@intCast(u32, points.len));

        // for each point, its proposed new point
        self.proposed = try alloc.alloc(Point, points.len);

        // for each proposed point, the number of times it has been proposed
        self.proposed_count = std.AutoHashMap(Point, u32).init(alloc);
        try self.proposed_count.ensureTotalCapacity(@intCast(u32, points.len));

        self.deltas = .{
            .{ 0, -1 }, // north
            .{ 0, 1 }, // south
            .{ -1, 0 }, // west
            .{ 1, 0 }, // east
        };

        return self;
    }

    /// Simulate a step of the elves moving. Returning `true` if any of them moved.
    fn step(self: *@This()) bool {
        self.active.clearRetainingCapacity();
        self.proposed_count.clearRetainingCapacity();

        var any_movement = false;

        for (self.points) |p| self.active.putAssumeCapacity(p, {});

        for (self.points) |p, index| {
            var adjacent: [9]bool = undefined;
            var has_adjacent = false;

            var dy: i32 = -1;
            while (dy <= 1) : (dy += 1) {
                var dx: i32 = -1;
                while (dx <= 1) : (dx += 1) {
                    const occupied = self.active.contains(p + Point{ dx, dy });
                    adjacent[@intCast(u32, (dx + 1) + (dy + 1) * 3)] = occupied;
                    if ((dx != 0 or dy != 0) and occupied) has_adjacent = true;
                }
            }

            const proposal: Point = if (!has_adjacent)
                p
            else propose: for (self.deltas) |delta| {
                const perp = @Vector(2, i32){ -delta[1], delta[0] };
                const dirs = [3]Point{
                    delta - perp,
                    delta,
                    delta + perp,
                };

                for (dirs) |dir| {
                    // cannot go in this diretion, try with another direction
                    if (adjacent[@intCast(u32, (dir[0] + 1) + (dir[1] + 1) * 3)])
                        continue :propose;
                }

                // this direction was free
                break p + delta;
            } else p;

            self.proposed[index] = proposal;

            const entry = self.proposed_count.getOrPutAssumeCapacity(proposal);
            if (!entry.found_existing) entry.value_ptr.* = 0;
            entry.value_ptr.* += 1;
        }

        for (self.proposed) |proposal, index| {
            const count = self.proposed_count.get(proposal) orelse unreachable;

            if (count == 1) {
                const old = self.points[index];
                if (@reduce(.Or, old != proposal)) any_movement = true;

                self.points[index] = proposal;
            }
        }

        std.mem.rotate(@Vector(2, i32), &self.deltas, 1);

        return any_movement;
    }
};

fn debugPoints(points: []const Point) !void {
    var min = points[0];
    var max = points[0];
    for (points) |p| {
        min = @min(min, p);
        max = @max(max, p);
    }
    const size = @intCast(@Vector(2, u64), max - min) + @Vector(2, u64){ 1, 1 };
    const grid = try alloc.alloc(u8, size[0] * size[1]);
    defer alloc.free(grid);
    std.mem.set(u8, grid, '.');
    for (points) |p| {
        const coord = @intCast(@Vector(2, u64), p - min);
        grid[coord[0] + coord[1] * size[0]] = '#';
    }

    std.debug.print("\n", .{});
    var row: usize = 0;
    while (row < size[1]) : (row += 1) {
        std.debug.print("{s}\n", .{grid[row * size[0] .. (row + 1) * size[0]]});
    }
}

const Point = @Vector(2, i32);

fn parseInput(text: []const u8) ![]Point {
    var lines = std.mem.tokenize(u8, text, &std.ascii.whitespace);
    var coords = std.ArrayList(Point).init(alloc);

    var row: i32 = 0;
    while (lines.next()) |line| : (row += 1) {
        var col: i32 = 0;
        for (line) |ch| {
            if (ch == '#') try coords.append(.{ col, row });
            col += 1;
        }
    }

    return coords.toOwnedSlice();
}

const sample =
    \\....#..
    \\..###.#
    \\#...#.#
    \\.#...##
    \\#.###..
    \\##.#.##
    \\.#..#..
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 110), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 20), try part2(sample));
}
