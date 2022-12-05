const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {s}", .{try part1(input)});
    std.log.info("part2: {s}", .{try part2(input)});
}

fn part1(input_text: []const u8) ![]const u8 {
    const input = try parseInput(input_text);
    var stacks = input.stacks;

    for (input.instructions) |instr| {
        var i = instr.count;
        while (i > 0) : (i -= 1) {
            const crate = stacks[instr.source].pop();
            try stacks[instr.target].append(alloc, crate);
        }
    }

    var output = try alloc.alloc(u8, stacks.len);
    for (stacks) |stack, index| {
        output[index] = stack.items[stack.items.len - 1];
    }
    return output;
}

fn part2(input_text: []const u8) ![]const u8 {
    const input = try parseInput(input_text);
    var stacks = input.stacks;

    for (input.instructions) |instr| {
        if (instr.source == instr.target) continue;

        const source = &stacks[instr.source];
        const target = &stacks[instr.target];

        try target.appendSlice(alloc, source.items[source.items.len - instr.count ..]);
        try source.resize(alloc, source.items.len - instr.count);
    }

    var output = try alloc.alloc(u8, stacks.len);
    for (stacks) |stack, index| {
        output[index] = stack.items[stack.items.len - 1];
    }
    return output;
}

const Input = struct {
    stacks: []std.ArrayListUnmanaged(u8),
    instructions: []Instruction,
};

const Instruction = struct {
    count: u8,
    source: u8,
    target: u8,
};

fn parseInput(input: []const u8) !Input {
    var lines = std.mem.split(u8, input, "\n");
    var stacks = std.ArrayListUnmanaged(std.ArrayListUnmanaged(u8)){};

    while (lines.next()) |line| {
        if (line.len < 2) std.debug.panic("invalid line: {s}", .{line});
        if (std.ascii.isDigit(line[1])) break;

        const stack_width = 4;

        const stack_count = (line.len + stack_width - 1) / stack_width;
        while (stacks.items.len < stack_count) {
            try stacks.append(alloc, .{});
        }

        var stack_index: usize = 0;
        while (stack_index < stack_count) : (stack_index += 1) {
            const byte = line[stack_width * stack_index + 1];
            if (std.ascii.isWhitespace(byte)) continue;
            try stacks.items[stack_index].append(alloc, byte);
        }
    }

    for (stacks.items) |*stack| {
        std.mem.reverse(u8, stack.items);
    }

    const blank = lines.next() orelse return error.UnexpectedEof;
    std.debug.assert(std.mem.trim(u8, blank, &std.ascii.whitespace).len == 0);

    var instructions = std.ArrayListUnmanaged(Instruction){};
    while (lines.next()) |line| {
        if (std.mem.trim(u8, line, &std.ascii.whitespace).len == 0) break;
        const instruction = try instructions.addOne(alloc);
        const matches = util.extractMatches("move % from % to %", line) orelse {
            std.debug.panic("invalid instruction: {s}", .{line});
        };

        instruction.count = util.parseInt(u8, matches[0], 10);
        instruction.source = util.parseInt(u8, matches[1], 10) - 1;
        instruction.target = util.parseInt(u8, matches[2], 10) - 1;
    }

    return .{
        .stacks = stacks.toOwnedSlice(alloc),
        .instructions = instructions.toOwnedSlice(alloc),
    };
}

const sample =
    \\    [D]    
    \\[N] [C]    
    \\[Z] [M] [P]
    \\ 1   2   3 
    \\
    \\move 1 from 2 to 1
    \\move 3 from 1 to 3
    \\move 2 from 2 to 1
    \\move 1 from 1 to 2
;

test "part1" {
    std.testing.log_level = .info;
    std.debug.print("\n", .{});
    try std.testing.expectEqualStrings("CMZ", try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    std.debug.print("\n", .{});
    try std.testing.expectEqualStrings("MCD", try part2(sample));
}
