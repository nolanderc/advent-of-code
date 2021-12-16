const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 8,
    },
    .input = Notes,
    .format = .custom,
};

const Notes = struct {
    entries: []Entry,

    const Entry = struct {
        signals: [10]Signal,
        digits: [4]Signal,
    };

    const Signal = struct {
        flags: u7 = 0,

        pub fn count(self: Signal) usize {
            return @popCount(u7, self.flags);
        }

        pub fn format(self: Signal, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            var index: u3 = 0;
            while (index < 7) : (index += 1) {
                if (self.flags & (@as(u7, 1) << index) != 0) {
                    const byte = 'a' + @as(u8, index);
                    try writer.writeAll(&.{byte});
                }
            }
        }
    };

    pub fn parse(text: []const u8) !Notes {
        var entries = std.ArrayListUnmanaged(Entry){};

        var lines = std.mem.split(u8, text, "\n");
        while (lines.next()) |line| {
            var tokens = std.mem.tokenize(u8, line, " |");

            var signals = [_]Signal{.{}} ** 14;
            for (signals) |*signal| {
                const token = tokens.next() orelse return error.EndOfLine;
                signal.flags = 0;
                for (token) |char| {
                    signal.flags |= @as(u7, 1) << @intCast(u3, char - 'a');
                }
            }

            try entries.append(alloc, Entry{
                .signals = signals[0..10].*,
                .digits = signals[10..14].*,
            });
        }

        return Notes{
            .entries = entries.toOwnedSlice(alloc),
        };
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(notes: config.input) !u32 {
    var count: u32 = 0;
    for (notes.entries) |*entry| {
        for (entry.digits) |digit| {
            switch (digit.count()) {
                2, 3, 4, 7 => count += 1,
                else => {},
            }
        }
    }
    return count;
}

fn part2(notes: config.input) !u32 {
    std.log.debug("", .{});

    var sum: u32 = 0;
    for (notes.entries) |*entry| {
        std.sort.sort(Notes.Signal, &entry.signals, {}, struct {
            fn order(_: void, a: Notes.Signal, b: Notes.Signal) bool {
                return a.count() < b.count();
            }
        }.order);

        //  0000
        // 4    1
        // 4    1
        //  3333
        // 5    2
        // 5    2
        //  6666
        var wires = [_]u7{std.math.maxInt(u7)} ** 7;

        // 2 signals => digits { 1 }
        // 3 signals => digits { 7 }
        // 4 signals => digits { 4 }
        // 5 signals => digits { 2, 3, 5 }
        // 6 signals => digits { 0, 6, 9 }
        // 7 signals => digits { 8 }
        const digit_one = entry.signals[0].flags;
        const digit_seven = entry.signals[1].flags;
        const digit_four = entry.signals[2].flags;

        wires[0] = digit_seven ^ digit_one;
        wires[1] = digit_one;
        wires[2] = digit_one;
        wires[3] = digit_four;

        for (wires) |*wire, index| {
            if (index > 2 or index == 0) wire.* &= ~digit_one;
            if (index > 2) wire.* &= ~digit_seven;
            if (index > 4 or index == 0) wire.* &= ~digit_four;
        }

        // 5+ signals
        for (entry.signals[3..]) |signal| {
            wires[6] &= signal.flags;
        }

        // 5 signals
        for (entry.signals[3..6]) |signal| {
            wires[3] &= signal.flags;
        }

        var complete = wires[0] | wires[3] | wires[6];

        wires[5] &= ~complete;
        complete |= wires[5];

        wires[4] &= ~complete;
        complete |= wires[4];

        // 5 signals
        for (entry.signals[3..6]) |signal| {
            const wire_5 = signal.flags & wires[5];

            // only digit 2 has wire 5 on.
            if (wire_5 != 0) {
                wires[2] &= ~signal.flags;
                break;
            }
        }

        wires[1] &= ~wires[2];

        const digits: [10]u7 = .{
            // 0
            wires[0] | wires[1] | wires[2] | wires[4] | wires[5] | wires[6],
            // 1
            wires[1] | wires[2],
            // 2
            wires[0] | wires[1] | wires[3] | wires[5] | wires[6],
            // 3
            wires[0] | wires[1] | wires[3] | wires[2] | wires[6],
            // 4
            wires[1] | wires[2] | wires[3] | wires[4],
            // 5
            wires[0] | wires[2] | wires[3] | wires[4] | wires[6],
            // 6
            wires[0] | wires[2] | wires[3] | wires[4] | wires[5] | wires[6],
            // 7
            wires[0] | wires[1] | wires[2],
            // 8
            wires[0] | wires[1] | wires[2] | wires[3] | wires[4] | wires[5] | wires[6],
            // 9
            wires[0] | wires[1] | wires[2] | wires[3] | wires[4] | wires[6],
        };

        var number: u32 = 0;
        for (entry.digits) |signal| {
            const digit = std.mem.indexOf(u7, &digits, &.{signal.flags}) orelse return error.InvalidDigit;
            number = 10 * number + @intCast(u32, digit);
        }

        sum += number;
    }
    return sum;
}

const small_sample =
    \\acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf
;

const large_sample =
    \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
    \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
    \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
    \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
    \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
    \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
    \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
    \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
    \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
    \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, large_sample), 26);
}

test "part 2 small sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, small_sample), 5353);
}

test "part 2 large sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, large_sample), 61229);
}
