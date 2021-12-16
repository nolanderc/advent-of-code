const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 15,
    },
    .input = Map,
    .format = .custom,
};

fn Matrix(comptime T: type) type {
    return struct {
        values: []T,
        width: u32,
        height: u32,

        pub fn init(width: u32, height: u32) !@This() {
            return @This(){
                .values = try alloc.alloc(T, width * height),
                .width = width,
                .height = height,
            };
        }

        pub fn fill(self: *@This(), value: T) void {
            std.mem.set(T, self.values, value);
        }

        pub fn get(self: *const @This(), x: u32, y: u32) T {
            return self.values[x + y * self.width];
        }

        pub fn getPtr(self: *@This(), x: u32, y: u32) *T {
            return &self.values[x + y * self.width];
        }

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            var y: u32 = 0;
            while (y < self.height) : (y += 1) {
                var x: u32 = 0;
                while (x < self.width) : (x += 1) {
                    try writer.print(" {}", .{self.get(x, y)});
                }
                try writer.writeAll("\n");
            }
        }
    };
}

const Map = struct {
    grid: Matrix(u8),

    pub fn parse(text: []const u8) !@This() {
        var grid = std.ArrayList(u8).init(alloc);
        defer grid.deinit();

        var width: u32 = 0;
        var height: u32 = 0;

        var lines = std.mem.split(u8, text, "\n");
        while (lines.next()) |line| {
            height += 1;
            const trimmed = std.mem.trim(u8, line, &std.ascii.spaces);
            width = @maximum(width, @intCast(u32, trimmed.len));
            try grid.appendSlice(trimmed);
            for (grid.items[grid.items.len - trimmed.len ..]) |*cell| {
                cell.* -= '0';
            }
        }

        return @This(){
            .grid = .{
                .values = grid.toOwnedSlice(),
                .width = width,
                .height = height,
            },
        };
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(map: config.input) !u64 {
    return findPath(map.grid);
}

fn part2(map: config.input) !u64 {
    var expanded = try Matrix(u8).init(5 * map.grid.width, 5 * map.grid.height);

    var x: u32 = 0;
    while (x < map.grid.width) : (x += 1) {
        var y: u32 = 0;
        while (y < map.grid.height) : (y += 1) {
            var ix: u8 = 0;
            while (ix < 5) : (ix += 1) {
                var iy: u8 = 0;
                while (iy < 5) : (iy += 1) {
                    const old = map.grid.get(x, y);
                    const extra = ix + iy;
                    var new = old + extra;
                    while (new > 9) new -= 9;

                    const nx = x + ix * map.grid.width;
                    const ny = y + iy * map.grid.height;
                    expanded.getPtr(nx, ny).* = new;
                }
            }
        }
    }

    return findPath(expanded);
}

fn findPath(grid: Matrix(u8)) !u64 {
    const Node = struct {
        x: u16,
        y: u16,

        cost: u32,

        fn order(a: @This(), b: @This()) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    };

    var queue = std.PriorityQueue(Node, Node.order).init(alloc);

    var best_cost = try Matrix(u32).init(grid.width, grid.height);
    best_cost.fill(std.math.maxInt(u32));

    try queue.add(.{ .x = 0, .y = 0, .cost = 0 });

    const end_x = grid.width - 1;
    const end_y = grid.height - 1;

    while (queue.removeOrNull()) |current| {
        if (current.x == end_x and current.y == end_y) return current.cost;

        const adjacent = [_][2]i8{
            .{ -1, 0 },
            .{ 1, 0 },
            .{ 0, -1 },
            .{ 0, 1 },
        };

        for (adjacent) |delta| {
            const nx = @as(i32, current.x) + delta[0];
            const ny = @as(i32, current.y) + delta[1];
            if (nx < 0 or nx >= grid.width) continue;
            if (ny < 0 or ny >= grid.height) continue;
            const x = @intCast(u16, nx);
            const y = @intCast(u16, ny);

            const new_cost = current.cost + grid.get(x, y);

            const prev_best = best_cost.getPtr(x, y);
            if (new_cost >= prev_best.*) continue;
            prev_best.* = new_cost;

            try queue.add(.{ .x = x, .y = y, .cost = new_cost });
        }
    }

    unreachable;
}

const sample =
    \\1163751742
    \\1381373672
    \\2136511328
    \\3694931569
    \\7463417111
    \\1319128137
    \\1359912421
    \\3125421639
    \\1293138521
    \\2311944581
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 40);
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 315);
}
