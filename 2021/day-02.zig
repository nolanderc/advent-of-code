const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

pub fn main() anyerror!void {
    try utils.run(.{
        .problem = .{
            .year = 2021,
            .day = 2,
        },
        .input = Command,
        .format = .{ .pattern = "{} {}" },
    }, &.{ part1, part2 });
}

const Command = struct {
    direction: enum { forward, down, up },
    steps: u32,
};

fn part1(commands: []const Command) !void {
    var x: u32 = 0;
    var depth: u32 = 0;
    for (commands) |command| {
        switch (command.direction) {
            .forward => x += command.steps,
            .down => depth += command.steps,
            .up => depth -= command.steps,
        }
    }
    std.log.info("part 1: {}", .{x * depth});
}

fn part2(commands: []const Command) !void {
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
    std.log.info("part 2: {}", .{x * depth});
}
