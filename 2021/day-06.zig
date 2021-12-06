const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 6,
    },
    .input = u32,
    .format = .{ .tokens = "," },
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(fishes: []config.input) !u64 {
    return simulateFishGrowth(80, fishes);
}

fn part2(fishes: []config.input) !u64 {
    return simulateFishGrowth(256, fishes);
}

fn simulateFishGrowth(days: u32, fishes: []const config.input) u64 {
    var timers = [_]u64{0} ** 9;

    for (fishes) |fish| {
        timers[fish] += 1;
    }

    var day: u32 = 0;
    while (day < days) : (day += 1) {
        const elapsed = timers[0];

        var t: u32 = 1;
        while (t < timers.len) : (t += 1) {
            timers[t - 1] = timers[t];
        }

        timers[6] += elapsed;
        timers[8] = elapsed;
    }

    var count: u64 = 0;
    for (timers) |timer| {
        count += timer;
    }

    return count;
}

const sample =
    \\3,4,3,1,2
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 5934);
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 26984457539);
}
