const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub const log_level = .info;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    const stopwatch = try util.Stopwatch.init();
    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input)});
    std.debug.print("time: {}\n", .{stopwatch});
}

fn part1(input: []const u8) !i64 {
    var monkeys = try parseInput(input);
    var values = std.AutoHashMap(Name, Value).init(alloc);
    for (monkeys) |monkey| {
        try values.putNoClobber(monkey.name, monkey.value);
    }

    return compute(&values, "root".*);
}

fn compute(values: *std.AutoHashMap(Name, Value), name: Name) i64 {
    const value = values.getPtr(name) orelse unreachable;
    const result: i64 = switch (value.*) {
        .int => |x| x,
        .add => |args| compute(values, args[0]) + compute(values, args[1]),
        .sub => |args| compute(values, args[0]) - compute(values, args[1]),
        .mul => |args| compute(values, args[0]) * compute(values, args[1]),
        .div => |args| @divTrunc(compute(values, args[0]), compute(values, args[1])),
    };
    value.* = .{ .int = result };
    return result;
}

fn part2(input: []const u8) !i64 {
    var monkeys = try parseInput(input);
    var values = std.AutoHashMap(Name, Value).init(alloc);
    for (monkeys) |monkey| {
        try values.putNoClobber(monkey.name, monkey.value);
    }

    const equation = switch (values.get("root".*).?) {
        .int => std.debug.panic("expected root to be an operation", .{}),
        .add, .sub, .mul, .div => |args| args,
    };

    var exprs = try std.ArrayList(Expr).initCapacity(alloc, monkeys.len);
    const lhs = try buildExpr(&exprs, equation[0], &values);
    const rhs = try buildExpr(&exprs, equation[1], &values);

    const lhs_value = simplify(exprs.items, lhs);
    const rhs_value = simplify(exprs.items, rhs);

    var unknown: u16 = undefined;
    var value: i64 = undefined;
    if (lhs_value) |int| {
        unknown = rhs;
        value = int;
    } else if (rhs_value) |int| {
        unknown = lhs;
        value = int;
    } else {
        std.debug.panic("unknown occurs on both sides", .{});
    }

    return solve(exprs.items, unknown, value);
}

fn solve(exprs: []Expr, expr: u16, constant: i64) !i64 {
    var unknown = expr;
    var value = constant;

    while (true) {
        switch (exprs[unknown]) {
            .unknown => return value,
            .int => unreachable,
            .binary => |binary| {
                const lhs = exprs[binary.lhs];
                const rhs = exprs[binary.rhs];

                if (lhs == .int) {
                    switch (binary.op) {
                        .add => value = value - lhs.int,
                        .sub => value = lhs.int - value,
                        .mul => value = @divExact(value, lhs.int),
                        .div => value = @divExact(lhs.int, value),
                    }
                    unknown = binary.rhs;
                    continue;
                }

                if (rhs == .int) {
                    switch (binary.op) {
                        .add => value = value - rhs.int,
                        .sub => value = value + rhs.int,
                        .mul => value = @divExact(value, rhs.int),
                        .div => value = value * rhs.int,
                    }
                    unknown = binary.lhs;
                    continue;
                }

                const writer = std.io.getStdOut().writer();
                try printExpr(exprs, unknown, &writer);
                std.debug.panic("could not solve", .{});
            },
        }
    }
}

fn simplify(exprs: []Expr, id: u16) ?i64 {
    switch (exprs[id]) {
        .unknown => return null,
        .int => |x| return x,
        .binary => |binary| {
            const lhs = simplify(exprs, binary.lhs);
            const rhs = simplify(exprs, binary.rhs);
            if (lhs == null or rhs == null) return null;

            const a = lhs.?;
            const b = rhs.?;
            const result: i64 = switch (binary.op) {
                .add => a + b,
                .sub => a - b,
                .mul => a * b,
                .div => @divTrunc(a, b),
            };
            exprs[id] = .{ .int = result };
            return result;
        },
    }
}

fn printExpr(exprs: []const Expr, id: u16, writer: anytype) !void {
    switch (exprs[id]) {
        .unknown => try writer.print("x", .{}),
        .int => |x| try writer.print("{}", .{x}),
        .binary => |binary| {
            try writer.print("(", .{});
            try printExpr(exprs, binary.lhs, writer);
            const char: u8 = switch (binary.op) {
                .add => '+',
                .sub => '-',
                .mul => '*',
                .div => '/',
            };
            try writer.print(" {c} ", .{char});
            try printExpr(exprs, binary.rhs, writer);
            try writer.print(")", .{});
        },
    }
}

fn buildExpr(
    exprs: *std.ArrayList(Expr),
    name: Name,
    values: *const std.AutoHashMap(Name, Value),
) !u16 {
    const value = values.get(name) orelse std.debug.panic("invalid monkey: {s}", .{name});

    const expr: Expr = if (std.mem.eql(u8, &name, "humn"))
        .unknown
    else switch (value) {
        .int => |x| .{ .int = x },
        .add, .sub, .mul, .div => |args| .{ .binary = .{
            .lhs = try buildExpr(exprs, args[0], values),
            .op = switch (value) {
                .add => .add,
                .sub => .sub,
                .mul => .mul,
                .div => .div,
                else => unreachable,
            },
            .rhs = try buildExpr(exprs, args[1], values),
        } },
    };

    const index = exprs.items.len;
    try exprs.append(expr);
    return @intCast(u16, index);
}

const Expr = union(enum) {
    unknown: void,
    int: i64,
    binary: BinOp,
};

const BinOp = struct { lhs: u16, op: Op, rhs: u16 };
const Op = enum { add, sub, mul, div };

const Monkey = struct {
    name: Name,
    value: Value,
};

const Name = [4]u8;

const Value = union(enum) {
    int: i64,
    add: [2]Name,
    sub: [2]Name,
    mul: [2]Name,
    div: [2]Name,
};

fn parseInput(input: []const u8) ![]Monkey {
    var monkeys = std.ArrayList(Monkey).init(alloc);
    var lines = std.mem.split(u8, std.mem.trim(u8, input, &std.ascii.whitespace), "\n");
    while (lines.next()) |line| {
        const matches = util.extractMatches("%: %", line) orelse {
            std.debug.panic("invalid monkey: {s}", .{line});
        };
        const name = matches[0][0..4].*;
        const value = if (std.ascii.isDigit(matches[1][0])) Value{
            .int = util.parseInt(i64, matches[1], 10),
        } else blk: {
            const parts = util.extractMatches("% % %", matches[1]) orelse {
                std.debug.panic("invalid operation: {s}", .{matches[1]});
            };
            const lhs = parts[0][0..4].*;
            const rhs = parts[2][0..4].*;
            const args = [2]Name{ lhs, rhs };
            break :blk switch (parts[1][0]) {
                '+' => Value{ .add = args },
                '-' => Value{ .sub = args },
                '*' => Value{ .mul = args },
                '/' => Value{ .div = args },
                else => std.debug.panic("invalid operation: {s}", .{parts[1]}),
            };
        };
        try monkeys.append(.{ .name = name, .value = value });
    }
    return monkeys.toOwnedSlice();
}

const sample =
    \\root: pppw + sjmn
    \\dbpl: 5
    \\cczh: sllz + lgvd
    \\zczc: 2
    \\ptdq: humn - dvpt
    \\dvpt: 3
    \\lfqf: 4
    \\humn: 5
    \\ljgn: 2
    \\sjmn: drzm * dbpl
    \\sllz: 4
    \\pppw: cczh / lfqf
    \\lgvd: ljgn * ptdq
    \\drzm: hmdt - zczc
    \\hmdt: 32
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 152), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(i64, 301), try part2(sample));
}
