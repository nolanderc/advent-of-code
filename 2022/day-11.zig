const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !u64 {
    var monkeys = try parseInput(input);
    var activity = try alloc.alloc(u64, monkeys.len);
    std.mem.set(u64, activity, 0);

    var round: u64 = 0;
    while (round < 20) : (round += 1) {
        for (monkeys) |*monkey, index| {
            for (monkey.items.items) |item| {
                activity[index] += 1;

                var worry: u64 = item;
                const value: u64 = switch (monkey.operation.value) {
                    .old => worry,
                    .int => |value| value,
                };

                switch (monkey.operation.kind) {
                    .add => worry += value,
                    .mul => worry *= value,
                }

                worry /= 3;
                const target = monkey.targets[@boolToInt(worry % monkey.divisible != 0)];
                try monkeys[target].items.append(worry);
            }

            monkey.items.clearRetainingCapacity();
        }
    }

    std.sort.sort(u64, activity, {}, std.sort.desc(u64));

    return activity[0] * activity[1];
}

fn part2(input: []const u8) !u64 {
    var monkeys = try parseInput(input);
    var activity = try alloc.alloc(u64, monkeys.len);
    std.mem.set(u64, activity, 0);

    var mod: u64 = 1;
    for (monkeys) |monkey| {
        mod *= monkey.divisible;
    }

    var round: u64 = 0;
    while (round < 10000) : (round += 1) {
        for (monkeys) |*monkey, index| {
            for (monkey.items.items) |item| {
                activity[index] += 1;

                var worry: u64 = item;
                const value: u64 = switch (monkey.operation.value) {
                    .old => worry,
                    .int => |value| value,
                };

                switch (monkey.operation.kind) {
                    .add => worry += value,
                    .mul => worry *= value,
                }

                worry %= mod;

                const target = monkey.targets[@boolToInt(worry % monkey.divisible != 0)];
                try monkeys[target].items.append(worry);
            }

            monkey.items.clearRetainingCapacity();
        }
    }

    std.sort.sort(u64, activity, {}, std.sort.desc(u64));

    return activity[0] * activity[1];
}

const Monkey = struct {
    items: std.ArrayList(u64),
    operation: Operation,
    divisible: u64,
    targets: [2]u8,
};

const Operation = struct {
    const Kind = enum { mul, add };
    const Value = union(enum) { old: void, int: u32 };

    kind: Kind,
    value: Value,
};

fn parseInput(text: []const u8) ![]Monkey {
    const pattern =
        \\Monkey %:
        \\  Starting items: %
        \\  Operation: new = old %
        \\  Test: divisible by %
        \\    If true: throw to monkey %
        \\    If false: throw to monkey %
    ;

    var monkeys = std.ArrayList(Monkey).init(alloc);
    var groups = std.mem.split(
        u8,
        std.mem.trim(u8, text, &std.ascii.whitespace),
        "\n\n",
    );

    while (groups.next()) |group| {
        var matches = util.extractMatches(pattern, group) orelse {
            std.debug.panic("invalid monkey:\n{s}", .{group});
        };

        var items = std.ArrayList(u64).init(alloc);
        var starting_items = std.mem.split(u8, matches[1], ", ");
        while (starting_items.next()) |item| {
            try items.append(util.parseInt(u64, item, 10));
        }

        const kind: Operation.Kind = switch (matches[2][0]) {
            '*' => .mul,
            '+' => .add,
            else => std.debug.panic("invalid operation: {s}", .{matches[2]}),
        };

        const value_text = matches[2][2..];
        const value: Operation.Value = if (std.mem.eql(u8, value_text, "old"))
            .old
        else .{ .int = util.parseInt(u32, value_text, 10) };

        const divisible = util.parseInt(u64, matches[3], 10);

        const targets = [2]u8{
            util.parseInt(u8, matches[4], 10),
            util.parseInt(u8, matches[5], 10),
        };

        try monkeys.append(.{
            .items = items,
            .operation = .{
                .kind = kind,
                .value = value,
            },
            .divisible = divisible,
            .targets = targets,
        });
    }

    return monkeys.toOwnedSlice();
}

const sample =
    \\Monkey 0:
    \\  Starting items: 79, 98
    \\  Operation: new = old * 19
    \\  Test: divisible by 23
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 3
    \\
    \\Monkey 1:
    \\  Starting items: 54, 65, 75, 74
    \\  Operation: new = old + 6
    \\  Test: divisible by 19
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 0
    \\
    \\Monkey 2:
    \\  Starting items: 79, 60, 97
    \\  Operation: new = old * old
    \\  Test: divisible by 13
    \\    If true: throw to monkey 1
    \\    If false: throw to monkey 3
    \\
    \\Monkey 3:
    \\  Starting items: 74
    \\  Operation: new = old + 3
    \\  Test: divisible by 17
    \\    If true: throw to monkey 0
    \\    If false: throw to monkey 1
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 10605), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 2713310158), try part2(sample));
}
