const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 10,
    },
    .input = []const u8,
    .format = .{ .pattern = "{}" },
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(lines: []const config.input) !u32 {
    var stack = std.ArrayList(u8).init(alloc);
    defer stack.deinit();

    var sum: u32 = 0;

    for (lines) |line| {
        if (try checkLineCorruption(line, &stack)) |invalid| {
            if (invalid == ')') sum += 3;
            if (invalid == ']') sum += 57;
            if (invalid == '}') sum += 1197;
            if (invalid == '>') sum += 25137;
        }
    }

    return sum;
}

fn part2(lines: []const config.input) !u64 {
    var stack = std.ArrayList(u8).init(alloc);
    defer stack.deinit();

    var scores = std.ArrayList(u64).init(alloc);
    defer scores.deinit();

    for (lines) |line| {
        if ((try checkLineCorruption(line, &stack)) != null) continue;

        var score: u64 = 0;
        while (stack.items.len > 0) {
            score *= 5;
            score += switch (stack.pop()) {
                '(' => @as(u32, 1),
                '[' => @as(u32, 2),
                '{' => @as(u32, 3),
                '<' => @as(u32, 4),
                else => @as(u32, 0),
            };
        }

        try scores.append(score);
    }

    std.sort.sort(u64, scores.items, {}, comptime std.sort.asc(u64));

    return scores.items[scores.items.len / 2];
}

/// Checks if a line is corrupted. If it is, returns the invalid character
fn checkLineCorruption(line: []const u8, stack: *std.ArrayList(u8)) !?u8 {
    stack.clearRetainingCapacity();

    for (line) |char| {
        switch (char) {
            '(', '[', '{', '<' => try stack.append(char),
            else => {
                if (stack.items.len == 0) return char;
                const last = stack.pop();
                const matches = switch (last) {
                    '(' => char == ')',
                    '[' => char == ']',
                    '{' => char == '}',
                    '<' => char == '>',
                    else => return char,
                };
                if (!matches) return char;
            },
        }
    } else {
        return null;
    }
}

const sample =
    \\[({(<(())[]>[[{[]{<()<>>
    \\[(()[<>])]({[<{<<[]>>(
    \\{([(<{}[<>[]}>{[]{[(<()>
    \\(((({<>}<{<{<>}{[]{[]{}
    \\[[<[([]))<([[{}[[()]]]
    \\[{[{({}]{}}([{[{{{}}([]
    \\{<[[]]>}<{[{[{[]{()[[[]
    \\[<(<(<(<{}))><([]([]()
    \\<{([([[(<>()){}]>(<<{{
    \\<{([{{}}[<[[[<>{}]]]>[]]
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 26397);
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 288957);
}
