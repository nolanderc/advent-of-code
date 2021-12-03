const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 1,
    },
    .input = u32,
    .format = .{ .pattern = "{}" },
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(input: []const config.input) !u32 {
    return countIncreasingWindows(input, 1);
}

fn part2(input: []const config.input) !u32 {
    return countIncreasingWindows(input, 3);
}

fn countIncreasingWindows(input: []const config.input, window_size: u32) u32 {
    var increases: u32 = 0;
    var i: u32 = window_size;

    while (i < input.len) : (i += 1) {
        var sum: u32 = 0;
        var head: u32 = i - window_size;

        while (head <= i) : (head += 1) {
            sum += input[head];
        }

        const prev_sum = sum - input[i];
        const curr_sum = sum - input[i - window_size];
        if (curr_sum > prev_sum) increases += 1;
    }

    return increases;
}
