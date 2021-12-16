const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 7,
    },
    .input = u32,
    .format = .{ .tokens = "," },
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(positions: []config.input) !u64 {
    return fuelConsumption(positions, struct {
        fn cost(distance: u32) u32 {
            return distance;
        }
    }.cost);
}

fn part2(positions: []config.input) !u64 {
    return fuelConsumption(positions, struct {
        fn cost(distance: u32) u32 {
            return distance * (distance + 1) / 2;
        }
    }.cost);
}

fn fuelConsumption(positions: []const u32, comptime cost: fn (u32) u32) u32 {
    var min: u32 = positions[0];
    var max: u32 = positions[0];
    for (positions) |pos| {
        min = std.math.min(min, pos);
        max = std.math.max(max, pos);
    }

    var best_fuel: u32 = std.math.maxInt(u32);
    var target = min;
    while (target <= max) : (target += 1) {
        var fuel: u32 = 0;
        for (positions) |pos| {
            const delta = std.math.min(target -% pos, pos -% target);
            fuel += cost(delta);
        }
        if (fuel < best_fuel) {
            best_fuel = fuel;
        }
    }

    return best_fuel;
}

const sample =
    \\16,1,2,0,4,2,7,1,2,14
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 37);
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 168);
}
