const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 2,
    },
    .input = struct {
        direction: enum { forward, down, up },
        steps: u32,
    },
    .format = .{ .pattern = "{} {}" },
};

pub fn main() anyerror!void {
    try config.run(solution);
}

fn solution(input: []const config.input) void {
    std.log.info("part 1: {}", .{part1(input)});
    std.log.info("part 2: {}", .{part2(input)});
}

fn part1(commands: []const config.input) u32 {
    var x: u32 = 0;
    var depth: u32 = 0;
    for (commands) |command| {
        switch (command.direction) {
            .forward => x += command.steps,
            .down => depth += command.steps,
            .up => depth -= command.steps,
        }
    }
    return x * depth;
}

fn part2(commands: []const config.input) u32 {
    var x: u32 = 0;
    var depth: u32 = 0;
    var aim: u32 = 0;
    for (commands) |command| {
        switch (command.direction) {
            .forward => {
                x += command.steps;
                depth += aim * command.steps;
            },
            .down => aim += command.steps,
            .up => aim -= command.steps,
        }
    }
    return x * depth;
}
