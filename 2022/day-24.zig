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

fn part1(text: []const u8) !u64 {
    const input = try Input.parse(text);
    var simulator = try Simulator.init(input);
    return try simulator.routeToEnd();
}

fn part2(text: []const u8) !u64 {
    const input = try Input.parse(text);
    var simulator = try Simulator.init(input);

    const to_end = try simulator.routeToEnd();
    const to_start = try simulator.routeToStart();
    const back_to_end = try simulator.routeToEnd();

    return to_end + to_start + back_to_end;
}

const Simulator = struct {
    grid: Grid,
    state: State,
    point_set: std.DynamicBitSetUnmanaged,

    curr_points: std.ArrayListUnmanaged(Point) = .{},
    next_points: std.ArrayListUnmanaged(Point) = .{},

    fn init(input: Input) !@This() {
        const spaces = std.math.mulWide(u16, input.grid.width, input.grid.height);
        return .{
            .grid = input.grid,
            .state = try State.init(input.blizzards),
            .point_set = try std.DynamicBitSetUnmanaged.initEmpty(alloc, spaces),
        };
    }

    fn routeToEnd(self: *@This()) !u32 {
        const start = Point{ self.grid.start, 0 };
        const end = Point{ self.grid.end, self.grid.height - 1 };
        return self.route(start, end);
    }

    fn routeToStart(self: *@This()) !u32 {
        const start = Point{ self.grid.start, 0 };
        const end = Point{ self.grid.end, self.grid.height - 1 };
        return self.route(end, start);
    }

    fn route(self: *@This(), source: Point, target: Point) !u32 {
        self.curr_points.clearRetainingCapacity();
        self.next_points.clearRetainingCapacity();

        try self.curr_points.append(alloc, source);

        const grid = self.grid;

        const left = 1;
        const top = 1;
        const right = grid.width - 2;
        const bottom = grid.height - 2;

        // var simulator = try Simulator.fromInput(input);
        var time: u32 = 0;
        while (true) {
            time += 1;

            try self.state.advance(grid);
            self.point_set.setRangeValue(
                .{ .start = 0, .end = self.point_set.bit_length },
                false,
            );

            for (self.curr_points.items) |curr| {
                var candidates = std.BoundedArray(Point, 5){};

                try candidates.append(curr);

                if (curr[1] == 0) {
                    try candidates.append(.{ curr[0], 1 });
                } else if (curr[1] == bottom + 1) {
                    try candidates.append(.{ curr[0], bottom });
                } else {
                    try candidates.append(curr - Point{ 1, 0 });
                    try candidates.append(curr + Point{ 1, 0 });
                    try candidates.append(curr - Point{ 0, 1 });
                    try candidates.append(curr + Point{ 0, 1 });
                }

                for (candidates.slice()) |next| {
                    const is_source = @reduce(.And, next == source);
                    const is_target = @reduce(.And, next == target);

                    if (is_target) return time;

                    if (!is_source) {
                        if (next[0] < left or next[0] > right) continue;
                        if (next[1] < top or next[1] > bottom) continue;
                    }

                    if (self.state.occupied.contains(next)) continue;

                    const index = next[0] + @as(u32, next[1]) * grid.width;
                    if (self.point_set.isSet(index)) continue;
                    self.point_set.set(index);

                    try self.next_points.append(alloc, next);
                }
            }

            self.curr_points.clearRetainingCapacity();
            std.mem.swap(@TypeOf(self.curr_points), &self.curr_points, &self.next_points);
        }
    }
};

const State = struct {
    blizzards: []Blizzard,
    occupied: std.AutoHashMap(Point, void),

    fn init(blizzards: []Blizzard) !@This() {
        var occupied = std.AutoHashMap(Point, void).init(alloc);
        try occupied.ensureTotalCapacity(@intCast(u32, blizzards.len));

        for (blizzards) |blizzard| {
            try occupied.put(blizzard.point, {});
        }

        return .{ .blizzards = blizzards, .occupied = occupied };
    }

    fn advance(self: *@This(), grid: Grid) !void {
        self.occupied.clearRetainingCapacity();

        const left: u16 = 1;
        const right: u16 = grid.width - 2;
        const top: u16 = 1;
        const bottom: u16 = grid.height - 2;

        for (self.blizzards) |*blizzard| {
            var new_point: Point = switch (blizzard.direction) {
                .up => blizzard.point - Point{ 0, 1 },
                .down => blizzard.point + Point{ 0, 1 },
                .left => blizzard.point - Point{ 1, 0 },
                .right => blizzard.point + Point{ 1, 0 },
            };

            if (new_point[0] < left) new_point[0] = right;
            if (new_point[0] > right) new_point[0] = left;

            if (new_point[1] < top) new_point[1] = bottom;
            if (new_point[1] > bottom) new_point[1] = top;

            blizzard.point = new_point;
            try self.occupied.put(new_point, {});
        }
    }
};

const Point = @Vector(2, u16);

const Direction = enum { up, down, left, right };

const Grid = struct {
    start: u16,
    end: u16,
    width: u16,
    height: u16,
};

const Blizzard = struct {
    point: Point,
    direction: Direction,
};

const Input = struct {
    grid: Grid,
    blizzards: []Blizzard,

    fn parse(text: []const u8) !Input {
        var lines = std.mem.tokenize(u8, text, &std.ascii.whitespace);

        const start = lines.next();
        var blizzards = std.ArrayList(Blizzard).init(alloc);
        var end: ?[]const u8 = null;

        var row: u16 = 1;
        while (lines.next()) |line| : (row += 1) {
            if (line.len < 2) return error.InvalidGrid;
            if (line[2] == '#') {
                end = line;
                break;
            }

            for (line[1 .. line.len - 1]) |char, col| {
                const point = Point{ @intCast(u16, col + 1), row };
                const dir: Direction = switch (char) {
                    '.' => continue,
                    '^' => .up,
                    'v' => .down,
                    '<' => .left,
                    '>' => .right,
                    else => return error.InvalidBlizzard,
                };

                try blizzards.append(.{ .point = point, .direction = dir });
            }
        }

        const start_line = start orelse return error.EndOfFile;
        const end_line = end orelse return error.EndOfFile;

        return .{
            .grid = .{
                .start = try findOpening(start_line),
                .end = try findOpening(end_line),
                .width = @intCast(u16, start_line.len),
                .height = row + 1,
            },
            .blizzards = blizzards.toOwnedSlice(),
        };
    }

    fn findOpening(row: []const u8) !u16 {
        if (std.math.cast(u16, std.mem.indexOfScalar(u8, row, '.') orelse return error.NoEnd)) |opening| {
            return opening;
        } else {
            return error.InvalidEdge;
        }
    }
};

const sample =
    \\#.######
    \\#>>.<^<#
    \\#.<..<<#
    \\#>v.><>#
    \\#<^v^^>#
    \\######.#
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 18), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 54), try part2(sample));
}
