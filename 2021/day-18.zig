const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 18,
    },
    .input = PairList,
    .format = .custom,
};

const PairList = struct {
    pairs: []Pair,

    pub fn parse(text: []const u8) !@This() {
        var pairs = std.ArrayList(Pair).init(alloc);
        defer pairs.deinit();
        var stack = std.ArrayList(Pair.Node).init(alloc);
        defer stack.deinit();

        var lines = std.mem.split(u8, text, "\n");

        while (lines.next()) |line| {
            for (line) |char| {
                if (std.ascii.isDigit(char)) {
                    try stack.append(Pair.Node{ .value = char - '0' });
                } else if (char == ']') {
                    const pair = try alloc.create(Pair);
                    pair.right = stack.pop();
                    pair.left = stack.pop();
                    try stack.append(Pair.Node{ .pair = pair });
                }
            }

            try pairs.append(stack.pop().pair.*);
        }

        return @This(){
            .pairs = pairs.toOwnedSlice(),
        };
    }
};

const Pair = struct {
    left: Node,
    right: Node,

    const Node = union(enum) {
        value: u8,
        pair: *Pair,

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            if (self == .value) {
                return writer.print("{}", .{self.value});
            } else {
                return writer.print("{}", .{self.pair.*});
            }
        }

        pub fn magnitude(self: @This()) u64 {
            return switch (self) {
                .value => |v| v,
                .pair => |p| p.magnitude(),
            };
        }

        pub fn explode(self: *@This(), depth: u32) ?[2]u8 {
            if (self.* == .value) return null;
            const pair = self.pair;
            if (depth == 4) {
                const left = pair.left.value;
                const right = pair.right.value;
                self.* = Node{ .value = 0 };
                return [2]u8{ left, right };
            } else {
                return pair.explode(depth);
            }
        }

        pub fn addLeftmost(self: *@This(), value: u8) void {
            if (self.* == .value) {
                self.value += value;
            } else {
                self.pair.left.addLeftmost(value);
            }
        }

        pub fn addRightmost(self: *@This(), value: u8) void {
            if (self.* == .value) {
                self.value += value;
            } else {
                self.pair.right.addRightmost(value);
            }
        }

        pub fn split(self: *@This()) bool {
            if (self.* == .value) {
                if (self.value > 9) {
                    const pair = alloc.create(Pair) catch @panic("allocation failed");
                    pair.left = .{ .value = self.value / 2 };
                    pair.right = .{ .value = (self.value + 1) / 2 };
                    self.* = .{ .pair = pair };
                    return true;
                } else {
                    return false;
                }
            } else {
                return self.pair.split();
            }
        }

        pub fn clone(self: *const @This()) anyerror!@This() {
            if (self.* == .value) return self.*;
            const pair = try alloc.create(Pair);
            pair.* = try self.pair.clone();
            return Node{ .pair = pair };
        }
    };

    pub fn clone(self: *const @This()) !@This() {
        return Pair{
            .left = try self.left.clone(),
            .right = try self.right.clone(),
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        return writer.print("[{}, {}]", .{ self.left, self.right });
    }

    pub fn magnitude(self: @This()) u64 {
        return 3 * self.left.magnitude() + 2 * self.right.magnitude();
    }

    pub fn add(self: *@This(), other: *@This()) @This() {
        var sum = Pair{
            .left = .{ .pair = self },
            .right = .{ .pair = other },
        };
        sum.reduce();
        return sum;
    }

    pub fn reduce(self: *@This()) void {
        while (true) {
            if (self.explode(0) != null) continue;
            if (self.split()) continue;
            break;
        }
    }

    pub fn explode(self: *@This(), depth: u32) ?[2]u8 {
        if (self.left.explode(depth + 1)) |vals| {
            self.right.addLeftmost(vals[1]);
            return [2]u8{ vals[0], 0 };
        }
        if (self.right.explode(depth + 1)) |vals| {
            self.left.addRightmost(vals[0]);
            return [2]u8{ 0, vals[1] };
        }
        return null;
    }

    pub fn split(self: *@This()) bool {
        if (self.left.split()) return true;
        if (self.right.split()) return true;
        return false;
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(list: PairList) !u64 {
    const pairs = list.pairs;

    var pair_sum = &pairs[0];
    for (pairs[1..]) |*pair| {
        const sum = try alloc.create(Pair);
        sum.* = pair_sum.add(pair);
        pair_sum = sum;
    }

    return pair_sum.magnitude();
}

fn part2(list: PairList) !u64 {
    const pairs = list.pairs;

    var max_magnitude: u64 = 0;
    for (pairs) |pair_a, a| {
        for (pairs) |pair_b, b| {
            if (a != b) {
                var left = try pair_a.clone();
                var right = try pair_b.clone();
                const sum = left.add(&right);
                max_magnitude = std.math.max(max_magnitude, sum.magnitude());
            }
        }
    }

    return max_magnitude;
}

const magnitude_samples = .{
    .{ .text = "[[1,2],[[3,4],5]]", .answer = 143 },
    .{ .text = "[[[[0,7],4],[[7,8],[6,0]]],[8,1]]", .answer = 1384 },
    .{ .text = "[[[[1,1],[2,2]],[3,3]],[4,4]]", .answer = 143 },
    .{ .text = "[[[[3,0],[5,3]],[4,4]],[5,5]]", .answer = 143 },
    .{ .text = "[[[[5,0],[7,4]],[5,5]],[6,6]]", .answer = 143 },
    .{ .text = "[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]", .answer = 143 },
};

const full_sample =
    \\[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
    \\[[[5,[2,8]],4],[5,[[9,9],0]]]
    \\[6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
    \\[[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
    \\[[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
    \\[[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
    \\[[[[5,4],[7,7]],8],[[8,3],8]]
    \\[[9,3],[[9,9],[6,[4,9]]]]
    \\[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
    \\[[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
;

const part1_samples = .{.{ .text = full_sample, .answer = 4140 }};
const part2_samples = .{.{ .text = full_sample, .answer = 3993 }};

test "part 1 sample" {
    std.testing.log_level = .debug;
    inline for (part1_samples) |sample| {
        try std.testing.expectEqual(
            @as(u64, sample.answer),
            try config.runWithRawInput(part1, sample.text),
        );
    }
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    inline for (part2_samples) |sample| {
        try std.testing.expectEqual(
            @as(u64, sample.answer),
            try config.runWithRawInput(part2, sample.text),
        );
    }
}
