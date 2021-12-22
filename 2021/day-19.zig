const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 19,
    },
    .input = ScannerList,
    .format = .custom,
};

const ScannerList = struct {
    scanners: []Scanner,

    pub fn parse(text: []const u8) !@This() {
        var scanners = std.ArrayList(Scanner).init(alloc);
        defer scanners.deinit();

        var lines = std.mem.split(u8, text, "\n");
        while (lines.next()) |header_line| {
            const header = try utils.parse.parsePattern(
                struct { id: u32 },
                "--- scanner {} ---",
                header_line,
            );

            var observations = std.ArrayList(Point).init(alloc);
            defer observations.deinit();

            while (lines.next()) |line| {
                const trimmed = std.mem.trim(u8, line, &std.ascii.spaces);
                if (trimmed.len == 0) break;
                const observation = try utils.parse.parsePattern(
                    struct { x: i32, y: i32, z: i32 },
                    "{},{},{}",
                    trimmed,
                );
                try observations.append(Point{ observation.x, observation.y, observation.z });
            }

            try scanners.append(Scanner{
                .id = header.id,
                .observations = observations.toOwnedSlice(),
            });
        }

        return ScannerList{
            .scanners = scanners.toOwnedSlice(),
        };
    }
};

const Scanner = struct {
    id: u32,
    observations: []Point,
};

const Point = [3]i32;

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(list: ScannerList) !u64 {
    const corr = try correlateObservations(list.scanners);
    return corr.beacons.len;
}

fn part2(list: ScannerList) !u64 {
    const corr = try correlateObservations(list.scanners);

    var max_dist: u32 = 0;
    for (corr.scanners) |a| {
        for (corr.scanners) |b| {
            const dist = std.math.absCast(a[0] - b[0]) + std.math.absCast(a[1] - b[1]) + std.math.absCast(a[2] - b[2]);
            max_dist = std.math.max(max_dist, dist);
        }
    }

    return max_dist;
}

const Correlation = struct {
    /// The positions of each scanner (relative to scanner 0)
    scanners: []Point,
    /// The positions of each beacon (relative to scanner 0)
    beacons: []Point,
};

fn correlateObservations(scanners: []Scanner) !Correlation {
    const UsedScanner = struct {
        index: u32,
        orientation: Orientation,
        position: Point,
    };

    var used_scanners = std.ArrayList(UsedScanner).init(alloc);
    defer used_scanners.deinit();
    var remaining_scanners = std.ArrayList(u32).init(alloc);
    defer remaining_scanners.deinit();

    try used_scanners.append(.{
        .index = 0,
        .orientation = .{},
        .position = .{ 0, 0, 0 },
    });
    var i: u32 = 1;
    while (i < scanners.len) : (i += 1) {
        try remaining_scanners.append(@intCast(u32, i));
    }

    var used_i: u32 = 0;
    while (used_i < used_scanners.items.len) : (used_i += 1) {
        const used = used_scanners.items[used_i];

        var remaining_i: u32 = 0;
        while (remaining_i < remaining_scanners.items.len) {
            const remaining = remaining_scanners.items[remaining_i];

            const overlap = (try findOverlap(scanners[used.index], scanners[remaining])) orelse {
                remaining_i += 1;
                continue;
            };

            const delta = used.orientation.orient(overlap.delta);
            const position = Point{
                used.position[0] + delta[0],
                used.position[1] + delta[1],
                used.position[2] + delta[2],
            };
            const orientation = used.orientation.combine(overlap.orientation).inverse();

            try used_scanners.append(.{
                .index = remaining,
                .orientation = orientation,
                .position = position,
            });
            _ = remaining_scanners.swapRemove(remaining_i);

            std.log.debug("{} rel to {} (delta = {any:5}, pos = {any:5}, ori = {})", .{
                remaining,
                used.index,
                delta,
                position,
                overlap.orientation,
            });
        }
    }

    var beacons = std.AutoHashMap(Point, void).init(alloc);
    defer beacons.deinit();
    var scanner_positions = try alloc.alloc(Point, scanners.len);
    errdefer alloc.free(scanner_positions);

    for (used_scanners.items) |used| {
        const pos = used.position;
        scanner_positions[used.index] = used.position;
        for (scanners[used.index].observations) |obs| {
            const delta = used.orientation.orient(obs);
            try beacons.put(Point{
                pos[0] + delta[0],
                pos[1] + delta[1],
                pos[2] + delta[2],
            }, {});
        }
    }

    var beacon_list = try alloc.alloc(Point, beacons.count());
    errdefer alloc.free(beacon_list);

    i = 0;
    var beacon_iter = beacons.keyIterator();
    while (beacon_iter.next()) |beacon| : (i += 1) {
        beacon_list[i] = beacon.*;
    }

    return Correlation{
        .scanners = scanner_positions,
        .beacons = beacon_list,
    };
}

const Overlap = struct {
    delta: Point,
    orientation: Orientation,
};

//    y   z
//    | /
//    |/
//    +---- x
const Orientation = struct {
    right: Direction = .{ .dx = 1, .dy = 0, .dz = 0 },
    up: Direction = .{ .dx = 0, .dy = 1, .dz = 0 },
    forward: Direction = .{ .dx = 0, .dy = 0, .dz = 1 },

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        return writer.print("{{ {}, {}, {} }}", .{ self.right, self.forward, self.up });
    }

    pub fn combine(self: @This(), other: @This()) @This() {
        return .{
            .right = Direction.fromPoint(self.orient(.{ other.right.dx, other.up.dx, other.forward.dx })),
            .up = Direction.fromPoint(self.orient(.{ other.right.dy, other.up.dy, other.forward.dy })),
            .forward = Direction.fromPoint(self.orient(.{ other.right.dz, other.up.dz, other.forward.dz })),
        };
    }

    pub fn orient(self: @This(), point: Point) Point {
        const right = self.right.alignPoint(point);
        const up = self.up.alignPoint(point);
        const forward = self.forward.alignPoint(point);
        return .{
            right[0] + right[1] + right[2],
            up[0] + up[1] + up[2],
            forward[0] + forward[1] + forward[2],
        };
    }

    pub fn inverse(self: @This()) @This() {
        return .{
            .right = .{ .dx = self.right.dx, .dy = self.up.dx, .dz = self.forward.dx },
            .up = .{ .dx = self.right.dy, .dy = self.up.dy, .dz = self.forward.dy },
            .forward = .{ .dx = self.right.dz, .dy = self.up.dz, .dz = self.forward.dz },
        };
    }
};

const Direction = packed struct {
    dx: i2,
    dy: i2,
    dz: i2,

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (self.dx < 0) return writer.writeAll("-x");
        if (self.dx > 0) return writer.writeAll("+x");
        if (self.dy < 0) return writer.writeAll("-y");
        if (self.dy > 0) return writer.writeAll("+y");
        if (self.dz < 0) return writer.writeAll("-z");
        if (self.dz > 0) return writer.writeAll("+z");
        unreachable;
    }

    pub fn fromPoint(p: Point) Direction {
        return .{
            .dx = @intCast(i2, p[0]),
            .dy = @intCast(i2, p[1]),
            .dz = @intCast(i2, p[2]),
        };
    }

    pub fn cross(self: @This(), other: @This()) @This() {
        return .{
            .dx = self.dy * other.dz - other.dy * self.dz,
            .dy = self.dz * other.dx - other.dz * self.dx,
            .dz = self.dx * other.dy - other.dx * self.dy,
        };
    }

    pub fn alignPoint(self: @This(), point: Point) Point {
        return .{
            self.dx * point[0],
            self.dy * point[1],
            self.dz * point[2],
        };
    }
};

fn findOverlap(a: Scanner, b: Scanner) !?Overlap {
    const directions = [_]Direction{
        .{ .dx = 1, .dy = 0, .dz = 0 },
        .{ .dx = -1, .dy = 0, .dz = 0 },
        .{ .dx = 0, .dy = 1, .dz = 0 },
        .{ .dx = 0, .dy = -1, .dz = 0 },
        .{ .dx = 0, .dy = 0, .dz = 1 },
        .{ .dx = 0, .dy = 0, .dz = -1 },
    };

    for (directions) |right| {
        for (directions) |up| {
            const forward = right.cross(up);
            if (forward.dx == 0 and forward.dy == 0 and forward.dz == 0) continue;
            const orientation = Orientation{ .right = right, .up = up, .forward = forward };
            _ = orientation;

            if (try findOverlapOriented(a, b, orientation)) |delta| {
                return Overlap{ .delta = delta, .orientation = orientation };
            }
        }
    }

    return null;
}

fn findOverlapOriented(a: Scanner, b: Scanner, ori: Orientation) !?Point {
    var deltas = std.AutoHashMap(Point, u32).init(alloc);
    deltas.clearRetainingCapacity();

    const delta_count = a.observations.len * b.observations.len;
    try deltas.ensureUnusedCapacity(@intCast(u32, delta_count));

    for (a.observations) |a_obs| {
        for (b.observations) |b_original| {
            const b_obs = ori.orient(b_original);

            // assume that `a_obs` and `b_obs` refer to the same beacon
            const delta = Point{
                a_obs[0] - b_obs[0],
                a_obs[1] - b_obs[1],
                a_obs[2] - b_obs[2],
            };

            (try deltas.getOrPutValue(delta, 0)).value_ptr.* += 1;
        }
    }

    var delta: Point = undefined;
    var max_count: u32 = 0;

    var iter = deltas.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.* >= max_count) {
            max_count = entry.value_ptr.*;
            delta = entry.key_ptr.*;
        }
    }

    return if (max_count >= 12) delta else null;
}

const sample = @embedFile("day-19-sample.txt");

test "part 1 sample" {
    std.testing.log_level = .debug;
    std.log.debug("", .{});
    try std.testing.expectEqual(
        @as(u64, 79),
        try config.runWithRawInput(part1, sample),
    );
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    std.log.debug("", .{});
    try std.testing.expectEqual(
        @as(u64, 3621),
        try config.runWithRawInput(part2, sample),
    );
}
