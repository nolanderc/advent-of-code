const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 11,
    },
    .input = Matrix(u8),
    .format = .custom,
};

fn Matrix(comptime T: type) type {
    return struct {
        items: [10][10]T,

        pub const width = 10;
        pub const height = 10;

        pub fn parse(text: []const u8) !@This() {
            var self: @This() = undefined;

            var lines = std.mem.split(u8, text, "\n");
            for (self.items) |*row| {
                const line = lines.next() orelse return error.EndOfStream;
                for (line) |digit, col| {
                    row[col] = digit - '0';
                }
            }

            return self;
        }

        pub fn init(comptime value: T) @This() {
            return .{
                .items = [1][10]T{[1]T{value} ** 10} ** 10,
            };
        }

        pub fn get(self: *@This(), x: i32, y: i32) ?*T {
            if (y < 0 or y >= height or x < 0 or x >= width) return null;
            return &self.items[@intCast(u32, y)][@intCast(u32, x)];
        }

        pub fn format(self: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            for (self.items) |row| {
                try writer.writeAll("\n    ");
                for (row) |cell| {
                    try writer.print("{any} ", .{cell});
                }
            }
        }
    };
}

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(input: config.input) !u32 {
    var grid = input;

    var num_flashes: u32 = 0;
    var step: u32 = 0;
    while (step < 100) : (step += 1) {
        num_flashes += simulateStep(&grid);
    }

    return num_flashes;
}

fn part2(input: config.input) !u32 {
    var grid = input;
    var step: u32 = 0;
    while (simulateStep(&grid) != 100) : (step += 1) {}
    return step + 1;
}

fn simulateStep(grid: *Matrix(u8)) u32 {
    var flashed = Matrix(bool).init(false);
    var num_flashes: u32 = 0;

    // Increase all energy levels
    for (grid.items) |*row| {
        for (row) |*cell| {
            cell.* += 1;
        }
    }

    while (true) {
        const old_flashes = num_flashes;
        for (grid.items) |*row, uy| {
            for (row) |*cell, ux| {
                const x = @intCast(i32, ux);
                const y = @intCast(i32, uy);

                if (cell.* > 9 and !flashed.get(x, y).?.*) {
                    num_flashes += 1;
                    flashed.get(x, y).?.* = true;

                    comptime var directions = .{
                        .{ .dx = -1, .dy = -1 },
                        .{ .dx = 0, .dy = -1 },
                        .{ .dx = 1, .dy = -1 },
                        .{ .dx = -1, .dy = 0 },
                        .{ .dx = 1, .dy = 0 },
                        .{ .dx = -1, .dy = 1 },
                        .{ .dx = 0, .dy = 1 },
                        .{ .dx = 1, .dy = 1 },
                    };

                    inline for (directions) |dir| {
                        if (grid.get(x + dir.dx, y + dir.dy)) |neighbor| {
                            neighbor.* += 1;
                        }
                    }
                }
            }
        }
        if (old_flashes == num_flashes) break;
    }

    for (grid.items) |*row| {
        for (row) |*cell| {
            if (cell.* > 9) {
                cell.* = 0;
            }
        }
    }

    return num_flashes;
}

const sample =
    \\5483143223
    \\2745854711
    \\5264556173
    \\6141336146
    \\6357385478
    \\4167524645
    \\2176841721
    \\6882881134
    \\4846848554
    \\5283751526
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 1656);
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 195);
}
