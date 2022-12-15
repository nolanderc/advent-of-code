const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    const start = try std.time.Instant.now();
    std.debug.print("part1: {}\n", .{try part1(input, 2_000_000)});
    std.debug.print("part2: {}\n", .{try part2(input, 4_000_000)});
    const end = try std.time.Instant.now();
    var duration = @intToFloat(f64, end.since(start));
    var unit: []const u8 = "ns";

    if (duration > 1000) {
        duration /= 1000.0;
        unit = "us";
    }

    if (duration > 1000) {
        duration /= 1000.0;
        unit = "ms";
    }

    if (duration > 1000) {
        duration /= 1000.0;
        unit = "s";
    }

    std.debug.print("time: {d:.3} {s}", .{ duration, unit });
}

fn part1(input: []const u8, row: i32) !u64 {
    const sensors = try parseInput(input);

    var ranges = try std.ArrayList([2]i32).initCapacity(alloc, 2 * sensors.len);

    for (sensors) |sensor| {
        if (try sensor.coveredRange(row)) |range| {
            if (sensor.beacon[1] == row) {
                for (splitRange(range, sensor.beacon[0])) |subrange| {
                    try ranges.append(subrange orelse continue);
                }
            } else {
                try ranges.append(range);
            }
        }
    }

    return countCovered(ranges.items);
}

fn part2(input: []const u8, max_coord: i32) !u64 {
    const sensors = try parseInput(input);

    var ranges = try std.ArrayList([2]i32).initCapacity(alloc, sensors.len);

    var row: i32 = 0;
    while (row <= max_coord) : (row += 1) {
        ranges.clearRetainingCapacity();

        for (sensors) |sensor| {
            var range = try sensor.coveredRange(row) orelse continue;
            // clamp the range within the covered rectangle
            range[0] = @max(range[0], 0);
            range[1] = @min(range[1], max_coord);
            try ranges.append(range);
        }

        const covered = countCovered(ranges.items);
        if (@intCast(i64, covered) <= max_coord) {
            var last_end: i32 = -1;
            const col = for (ranges.items) |range| {
                if (range[1] <= last_end) continue;
                if (range[0] - 1 <= last_end) {
                    last_end = range[1];
                    continue;
                }

                break last_end + 1;
            } else unreachable;

            const x = @intCast(u64, col);
            const y = @intCast(u64, row);
            return 4_000_000 * x + y;
        }
    }

    return 0;
}

fn countCovered(ranges: [][2]i32) u64 {
    std.sort.insertionSort([2]i32, ranges, {}, struct {
        fn lessThan(_: void, a: [2]i32, b: [2]i32) bool {
            if (a[0] < b[0]) return true;
            if (a[0] > b[0]) return false;
            return a[1] > b[1];
        }
    }.lessThan);

    var covered: u64 = 0;
    var last_end: i32 = std.math.minInt(i32);

    for (ranges) |range| {
        // this range is completely covered by a previous range
        if (range[1] <= last_end) continue;
        const start = if (range[0] <= last_end) last_end + 1 else range[0];
        covered += @intCast(usize, range[1] - start + 1);
        last_end = range[1];
    }

    return covered;
}

const Point = @Vector(2, i32);
const Sensor = struct {
    position: Point,
    beacon: Point,

    fn coveredRange(self: @This(), row: i32) !?[2]i32 {
        const delta = self.beacon - self.position;
        const distance = try std.math.absInt(delta[0]) + try std.math.absInt(delta[1]);

        const height = try std.math.absInt(self.position[1] - row);
        if (height > distance) return null;

        const span = distance - height;
        const left = self.position[0] - span;
        const right = self.position[0] + span;
        return .{ left, right };
    }
};

fn splitRange(range: [2]i32, mid: i32) [2]?[2]i32 {
    std.debug.assert(range[0] <= mid and mid <= range[1]);

    if (range[0] == range[1]) return .{ null, null };
    if (range[0] == mid) return .{ .{ range[0] + 1, range[1] }, null };
    if (range[1] == mid) return .{ .{ range[0], range[1] - 1 }, null };

    return .{
        .{ range[0], mid - 1 },
        .{ mid + 1, range[1] },
    };
}

fn parseInput(input: []const u8) ![]Sensor {
    var lines = std.mem.tokenize(u8, input, "\n");
    var sensors = std.ArrayList(Sensor).init(alloc);

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        const integers = util.extractMatches("Sensor at x=%, y=%: closest beacon is at x=%, y=%", trimmed) orelse {
            std.debug.panic("invalid sensor: {s}", .{trimmed});
        };

        try sensors.append(.{
            .position = .{
                util.parseInt(i32, integers[0], 10),
                util.parseInt(i32, integers[1], 10),
            },
            .beacon = .{
                util.parseInt(i32, integers[2], 10),
                util.parseInt(i32, integers[3], 10),
            },
        });
    }

    return sensors.toOwnedSlice();
}

const sample =
    \\Sensor at x=2, y=18: closest beacon is at x=-2, y=15
    \\Sensor at x=9, y=16: closest beacon is at x=10, y=16
    \\Sensor at x=13, y=2: closest beacon is at x=15, y=3
    \\Sensor at x=12, y=14: closest beacon is at x=10, y=16
    \\Sensor at x=10, y=20: closest beacon is at x=10, y=16
    \\Sensor at x=14, y=17: closest beacon is at x=10, y=16
    \\Sensor at x=8, y=7: closest beacon is at x=2, y=10
    \\Sensor at x=2, y=0: closest beacon is at x=2, y=10
    \\Sensor at x=0, y=11: closest beacon is at x=2, y=10
    \\Sensor at x=20, y=14: closest beacon is at x=25, y=17
    \\Sensor at x=17, y=20: closest beacon is at x=21, y=22
    \\Sensor at x=16, y=7: closest beacon is at x=15, y=3
    \\Sensor at x=14, y=3: closest beacon is at x=15, y=3
    \\Sensor at x=20, y=1: closest beacon is at x=15, y=3
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 26), try part1(sample, 10));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 56000011), try part2(sample, 20));
}
