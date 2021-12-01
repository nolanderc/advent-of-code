const std = @import("std");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    std.log.info("https://adventofcode.com/2021/day/1", .{});
    defer _ = utils.gpa.detectLeaks();
    var alloc = utils.global_alloc;

    var input_reader = try utils.InputReader.initFromStdIn(alloc);
    defer input_reader.deinit(alloc);

    const input = try input_reader.parseLines(DepthInput).collectToSlice(alloc);
    defer alloc.free(input);

    std.log.info("part 1: {}", .{part1(input)});
    std.log.info("part 2: {}", .{part2(input)});
    std.log.info("done", .{});
}

const DepthInput = struct { depth: u32 };

fn part1(input: []const DepthInput) u32 {
    return countIncreasingWindows(input, 1);
}

fn part2(input: []const DepthInput) u32 {
    return countIncreasingWindows(input, 3);
}

fn countIncreasingWindows(input: []const DepthInput, window_size: u32) u32 {
    var increases: u32 = 0;
    var i: u32 = window_size;

    while (i < input.len) : (i += 1) {
        var sum: u32 = 0;
        var head: u32 = i - window_size;

        while (head <= i) : (head += 1) {
            sum += input[head].depth;
        }

        const prev_sum = sum - input[i].depth;
        const curr_sum = sum - input[i - window_size].depth;
        if (curr_sum > prev_sum) increases += 1;
    }

    return increases;
}
