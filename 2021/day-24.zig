const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 24,
    },
    .input = Monad,
    .format = .custom,
};

const Monad = struct {
    instructions: []Instruction,

    pub fn parse(text: []const u8) !@This() {
        var instructions = std.ArrayList(Instruction).init(alloc);
        defer instructions.deinit();

        var lines = std.mem.split(u8, text, "\n");

        while (lines.next()) |line| {
            var words = std.mem.tokenize(u8, line, " ");
            const op = (try utils.parse.parseSingle(OpCode, "", words.next() orelse "")).value;
            const lhs = (try utils.parse.parseSingle(Variable, "", words.next() orelse "")).value;
            const rhs = if (op == .inp) Value{ .integer = 0 } else blk: {
                break :blk (try utils.parse.parseSingle(Value, "", words.next() orelse "")).value;
            };
            try instructions.append(.{ .op = op, .lhs = lhs, .rhs = rhs });
        }

        return Monad{
            .instructions = instructions.toOwnedSlice(),
        };
    }

    pub fn simulate(self: @This(), registers: *[4]i64, input: []i64) void {
        var input_index: u32 = 0;
        for (self.instructions) |instr| {
            const lhs = registers[@enumToInt(instr.lhs)];
            const rhs = if (instr.rhs == .variable) registers[@enumToInt(instr.rhs.variable)] else instr.rhs.integer;

            var result: i64 = undefined;
            switch (instr.op) {
                .inp => {
                    result = input[input_index];
                    input_index += 1;
                },
                .add => result = lhs + rhs,
                .mul => result = lhs * rhs,
                .div => result = @divTrunc(lhs, rhs),
                .mod => result = @rem(lhs, rhs),
                .eql => result = @boolToInt(lhs == rhs),
            }

            registers[@enumToInt(instr.lhs)] = result;
        }
    }
};

const Instruction = struct {
    op: OpCode,
    lhs: Variable,
    rhs: Value,

    pub fn format(self: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{s} {s}", .{ @tagName(self.op), @tagName(self.lhs) });
        if (self.op != .inp) {
            if (self.rhs == .integer) {
                try writer.print(" {}", .{self.rhs.integer});
            } else {
                try writer.print(" {s}", .{@tagName(self.rhs.variable)});
            }
        }
    }
};

const OpCode = enum {
    inp,
    add,
    mul,
    div,
    mod,
    eql,
};

const Value = union(enum) {
    integer: i64,
    variable: Variable,

    pub fn parse(text: []const u8) !@This() {
        if (text[0] == '-' or std.ascii.isDigit(text[0])) {
            const int = try std.fmt.parseInt(i64, text, 10);
            return Value{ .integer = int };
        } else {
            const variable = try utils.parse.parseSingle(Variable, "", text);
            return Value{ .variable = variable.value };
        }
    }
};

const Variable = enum(u2) { x = 0, y = 1, z = 2, w = 3 };

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(monad: Monad) !i64 {
    var prev_z = std.AutoHashMap(i64, i64).init(alloc);
    defer prev_z.deinit();
    var next_z = std.AutoHashMap(i64, i64).init(alloc);
    defer next_z.deinit();

    try next_z.put(0, 0);

    var i: u32 = 0;
    while (i < 14) : (i += 1) {
        const tmp = Monad{ .instructions = monad.instructions[i * 18 .. (i + 1) * 18] };

        std.mem.swap(@TypeOf(prev_z), &prev_z, &next_z);
        next_z.clearRetainingCapacity();

        var digit: i64 = 9;
        while (digit >= 1) : (digit -= 1) {
            std.log.info("testing digit {} = {}", .{ i, digit });

            var prev_z_iter = prev_z.iterator();
            while (prev_z_iter.next()) |prev_entry| {
                const old_z = prev_entry.key_ptr.*;
                const model = prev_entry.value_ptr.*;

                var registers = [4]i64{ 0, 0, old_z, 0 };
                tmp.simulate(&registers, &.{digit});
                const new_z = registers[2];

                const next_entry = try next_z.getOrPut(new_z);
                if (next_entry.found_existing) continue;
                next_entry.value_ptr.* = model * 10 + digit;
            }
        }
    }

    return next_z.get(0) orelse return error.SolutionNotFound;
}

fn part2(monad: Monad) !i64 {
    var prev_z = std.AutoHashMap(i64, i64).init(alloc);
    defer prev_z.deinit();
    var next_z = std.AutoHashMap(i64, i64).init(alloc);
    defer next_z.deinit();

    try next_z.put(0, 0);

    var i: u32 = 0;
    while (i < 14) : (i += 1) {
        const tmp = Monad{ .instructions = monad.instructions[i * 18 .. (i + 1) * 18] };

        std.mem.swap(@TypeOf(prev_z), &prev_z, &next_z);
        next_z.clearRetainingCapacity();

        var digit: i64 = 1;
        while (digit <= 9) : (digit += 1) {
            std.log.info("testing digit {} = {}", .{ i, digit });

            var prev_z_iter = prev_z.iterator();
            while (prev_z_iter.next()) |prev_entry| {
                const old_z = prev_entry.key_ptr.*;
                const model = prev_entry.value_ptr.*;

                var registers = [4]i64{ 0, 0, old_z, 0 };
                tmp.simulate(&registers, &.{digit});
                const new_z = registers[2];

                const next_entry = try next_z.getOrPut(new_z);
                if (next_entry.found_existing) continue;
                next_entry.value_ptr.* = model * 10 + digit;
            }
        }
    }

    return next_z.get(0) orelse return error.SolutionNotFound;
}
