const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2018,
        .day = 1,
    },
    .input = i32,
    .format = .{ .pattern = "{}" },
};

pub fn main() !void {
    std.log.info("part 1: {}", .{config.run(part1)});
    std.log.info("part 2: {}", .{config.run(part2)});
}

fn part1(deltas: []const config.input) !i32 {
    var sum: i32 = 0;
    for (deltas) |delta| {
        sum += delta;
    }
    return sum;
}

fn part2(deltas: []const config.input) !i32 {
    var i: usize = 0;
    var frequency: i32 = 0;
    var frequencies = std.AutoHashMap(i32, void).init(alloc);
    defer frequencies.deinit();
    while ((try frequencies.getOrPut(frequency)).found_existing == false) {
        frequency += deltas[i];
        i = (i + 1) % deltas.len;
    }
    return frequency;
}

test "part 2 sample" {
    const sample =
        \\+7
        \\+7
        \\-2
        \\-7
        \\-4
    ;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 14);
}
