const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 9,
    },
    .input = Heightmap,
    .format = .custom,
};

const Heightmap = struct {
    heights: Matrix(u8),

    pub fn parse(text: []const u8) !@This() {
        var heights = std.ArrayListUnmanaged(u8){};
        const trimmed = std.mem.trim(u8, text, &std.ascii.spaces);
        var lines = std.mem.split(u8, trimmed, "\n");

        var height: u32 = 0;
        while (lines.next()) |line| {
            for (line) |ch| {
                if (std.ascii.isDigit(ch)) {
                    try heights.append(alloc, ch - '0');
                }
            }
            height += 1;
        }

        const width = @intCast(u32, heights.items.len / height);
        return Heightmap{
            .heights = .{
                .items = heights.toOwnedSlice(alloc),
                .width = width,
                .height = height,
            },
        };
    }
};

fn Matrix(comptime T: type) type {
    return struct {
        items: []T,
        width: u32,
        height: u32,

        pub fn init(width: u32, height: u32) !@This() {
            return @This(){
                .items = try alloc.alloc(T, width * height),
                .width = width,
                .height = height,
            };
        }

        pub fn get(self: @This(), row: i32, col: i32) ?T {
            if (row < 0 or row >= self.height or col < 0 or col >= self.width) return null;
            return self.items[@intCast(u32, col) + @intCast(u32, row) * self.width];
        }

        pub fn set(self: @This(), row: i32, col: i32, value: T) void {
            if (row < 0 or row >= self.height or col < 0 or col >= self.width) @panic("index out of bounds");
            self.items[@intCast(u32, col) + @intCast(u32, row) * self.width] = value;
        }
    };
}

const DIRECTIONS = .{
    .{ .row = -1, .col = 0 },
    .{ .row = 1, .col = 0 },
    .{ .row = 0, .col = -1 },
    .{ .row = 0, .col = 1 },
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(heightmap: config.input) !u32 {
    const heights = heightmap.heights;

    var sum: u32 = 0;
    var row: i32 = 0;
    while (row < heights.height) : (row += 1) {
        var col: i32 = 0;
        while (col < heights.width) : (col += 1) {
            const center = heights.get(row, col) orelse unreachable;
            inline for (DIRECTIONS) |dir| {
                const adjacent = heights.get(row - dir.row, col + dir.col) orelse 10;
                if (center >= adjacent) break;
            } else {
                sum += @as(u32, center) + 1;
            }
        }
    }

    return sum;
}

fn part2(heightmap: config.input) !u32 {
    const heights = heightmap.heights;

    var visited = try Matrix(bool).init(heights.width, heights.height);

    var largest_basins = [3]u32{ 0, 0, 0 };

    var row: i32 = 0;
    while (row < heights.height) : (row += 1) {
        var col: i32 = 0;
        while (col < heights.width) : (col += 1) {
            const center = heights.get(row, col) orelse unreachable;

            inline for (DIRECTIONS) |dir| {
                const adjacent = heights.get(row - dir.row, col + dir.col) orelse 10;
                if (center >= adjacent) break;
            } else {
                const size = basinSize(&heights, &visited, row, col);
                rollingMax(u32, &largest_basins, size);
            }
        }
    }

    return largest_basins[0] * largest_basins[1] * largest_basins[2];
}

fn rollingMax(comptime T: type, maxima: []T, new: T) void {
    var rolling = new;
    for (maxima) |*max| {
        if (rolling > max.*) {
            std.mem.swap(T, &rolling, max);
        }
    }
}

pub fn basinSize(heights: *const Matrix(u8), visited: *Matrix(bool), row: i32, col: i32) u32 {
    const height = heights.get(row, col) orelse 10;
    if (height >= 9 or visited.get(row, col) orelse true) return 0;
    visited.set(row, col, true);

    var size: u32 = 1;

    inline for (DIRECTIONS) |dir| {
        if (height <= heights.get(row + dir.row, col + dir.col) orelse 0) {
            size += basinSize(heights, visited, row + dir.row, col + dir.col);
        }
    }

    return size;
}

const sample =
    \\2199943210
    \\3987894921
    \\9856789892
    \\8767896789
    \\9899965678
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 15);
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 1134);
}
