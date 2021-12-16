const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 14,
    },
    .input = Polymer,
    .format = .custom,
};

const Polymer = struct {
    template: []const u8,
    rules: []Rule,

    const Rule = struct {
        pair: [2]u8,
        output: u8,
    };

    pub fn parse(text: []const u8) !@This() {
        var lines = std.mem.split(u8, text, "\n");

        const template = lines.next() orelse return error.EndOfInput;
        _ = lines.next();

        var rules = std.ArrayList(Rule).init(alloc);
        defer rules.deinit();

        while (lines.next()) |line| {
            var parts = std.mem.split(u8, line, " -> ");
            const pair = parts.next() orelse return error.InvalidInput;
            const output = parts.next() orelse return error.InvalidInput;
            try rules.append(Rule{
                .pair = .{ pair[0], pair[1] },
                .output = output[0],
            });
        }

        return @This(){
            .template = template,
            .rules = rules.toOwnedSlice(),
        };
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(polymer: config.input) !u64 {
    return insertionProcedure(polymer, 10);
}

fn part2(polymer: config.input) !u64 {
    return insertionProcedure(polymer, 40);
}

fn insertionProcedure(polymer: Polymer, steps: u32) !u64 {
    var rules = std.AutoHashMap([2]u8, u8).init(alloc);
    defer rules.deinit();

    for (polymer.rules) |rule| {
        try rules.put(rule.pair, rule.output);
    }

    var pairs = std.AutoHashMap([2]u8, u64).init(alloc);
    defer pairs.deinit();
    var new_pairs = std.AutoHashMap([2]u8, u64).init(alloc);
    defer new_pairs.deinit();

    var i: u32 = 1;
    while (i < polymer.template.len) : (i += 1) {
        const a = polymer.template[i - 1];
        const b = polymer.template[i];
        (try pairs.getOrPutValue(.{ a, b }, 0)).value_ptr.* += 1;
    }

    var step: u32 = 0;
    while (step < steps) : (step += 1) {
        new_pairs.clearRetainingCapacity();

        var pair_iter = pairs.iterator();
        while (pair_iter.next()) |pair_entry| {
            const pair = pair_entry.key_ptr.*;
            const count = pair_entry.value_ptr.*;

            if (rules.get(pair)) |output| {
                (try new_pairs.getOrPutValue(.{ pair[0], output }, 0)).value_ptr.* += count;
                (try new_pairs.getOrPutValue(.{ output, pair[1] }, 0)).value_ptr.* += count;
            } else {
                (try new_pairs.getOrPutValue(pair, 0)).value_ptr.* += count;
            }
        }

        std.mem.swap(@TypeOf(pairs), &pairs, &new_pairs);
    }

    var letters = std.AutoHashMap(u8, u64).init(alloc);
    defer letters.deinit();
    var pair_iter = pairs.iterator();
    while (pair_iter.next()) |entry| {
        // only add the second letter of each pair (so that we don't count them twice)
        const letter = entry.key_ptr[1];
        (try letters.getOrPutValue(letter, 0)).value_ptr.* += entry.value_ptr.*;
    }
    // Add the first letter (that is not counted as any pair above)
    (try letters.getOrPutValue(polymer.template[0], 0)).value_ptr.* += 1;

    var min: u64 = std.math.maxInt(u64);
    var max: u64 = 0;

    var occurances = letters.valueIterator();
    while (occurances.next()) |num| {
        min = std.math.min(min, num.*);
        max = std.math.max(max, num.*);
    }

    return max - min;
}

const sample =
    \\NNCB
    \\
    \\CH -> B
    \\HH -> N
    \\CB -> H
    \\NH -> C
    \\HB -> C
    \\HC -> B
    \\HN -> C
    \\NN -> C
    \\BH -> H
    \\NC -> B
    \\NB -> B
    \\BN -> B
    \\BB -> N
    \\BC -> B
    \\CC -> N
    \\CN -> C
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 1588);
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 2188189693529);
}
