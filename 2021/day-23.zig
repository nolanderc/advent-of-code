const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 23,
    },
    .input = Layout,
    .format = .custom,
};

const Layout = struct {
    rooms: [4][2]Token,

    pub fn parse(text: []const u8) !@This() {
        var lines = std.mem.split(u8, text, "\n");
        _ = lines.next();
        _ = lines.next();

        var rooms: [4][2]Token = undefined;

        inline for (.{ 0, 1 }) |level| {
            var tokens = std.mem.tokenize(u8, lines.next() orelse return error.EndOfInput, " #");
            inline for (.{ 0, 1, 2, 3 }) |room| {
                rooms[room][level] = switch ((tokens.next() orelse return error.EndOfInput)[0]) {
                    'A' => Token.A,
                    'B' => Token.B,
                    'C' => Token.C,
                    'D' => Token.D,
                    else => return error.InvalidToken,
                };
            }
        }

        return Layout{ .rooms = rooms };
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

const Token = enum(u3) {
    Empty = 0,
    A = 1,
    B = 2,
    C = 3,
    D = 4,

    const Tag = @typeInfo(@This()).Enum.tag_type;

    pub fn cost(self: @This()) u16 {
        return switch (self) {
            .Empty => 0,
            .A => 1,
            .B => 10,
            .C => 100,
            .D => 1000,
        };
    }

    fn target_room(self: @This()) ?u2 {
        return switch (self) {
            .Empty => null,
            .A => 0,
            .B => 1,
            .C => 2,
            .D => 3,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        return switch (self) {
            .Empty => writer.writeByte('.'),
            .A => writer.writeByte('A'),
            .B => writer.writeByte('B'),
            .C => writer.writeByte('C'),
            .D => writer.writeByte('D'),
        };
    }
};

fn State(comptime DEPTH: usize) type {
    return struct {
        corridor: [7]Token,
        rooms: [4][DEPTH]Token,

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.print("#############\n", .{});
            try writer.print("#{}{}.{}.{}.{}.{}{}#\n", .{
                self.getCorridor(0),
                self.getCorridor(1),
                self.getCorridor(2),
                self.getCorridor(3),
                self.getCorridor(4),
                self.getCorridor(5),
                self.getCorridor(6),
            });

            var depth: u32 = 0;
            while (depth < DEPTH) : (depth += 1) {
                const pad = if (depth == 0) "##" else "  ";
                try writer.print("{s}#{}#{}#{}#{}#{s}\n", .{
                    pad,
                    self.rooms[0][depth],
                    self.rooms[1][depth],
                    self.rooms[2][depth],
                    self.rooms[3][depth],
                    pad,
                });
            }
            try writer.print("  #########  \n", .{});
        }

        const Successor = struct {
            cost: u32,
            state: State(DEPTH),
        };

        fn initEmpty() @This() {
            return .{
                .corridor = .{.Empty} ** 7,
                .rooms = .{.{.Empty} ** DEPTH} ** 4,
            };
        }

        inline fn getCorridor(self: @This(), index: u3) Token {
            return self.corridor[index];
        }

        fn isCorridorClear(self: @This(), start: u3, end: u3) bool {
            var i = start;
            while (i < end) : (i += 1) {
                if (self.getCorridor(i) != .Empty) return false;
            }
            return true;
        }

        fn roomCorridor(room: u2) u3 {
            return @as(u3, room) + 1;
        }

        fn isFinal(self: @This()) bool {
            for (self.rooms) |room, index| {
                var depth: u32 = 0;
                while (depth < DEPTH) : (depth += 1) {
                    if (room[depth] != @intToEnum(Token, index + 1)) {
                        return false;
                    }
                }
            }
            return true;
        }

        fn corridorSteps(a: u3, b: u3) u8 {
            var delta = 2 * std.math.absCast(@as(i8, a) - @as(i8, b));
            if (a == 0 or a == 6) delta -= 1;
            if (b == 0 or b == 6) delta -= 1;
            return delta;
        }

        fn findCost(self: @This(), cache: *std.AutoHashMap(@This(), u32)) anyerror!u32 {
            if (self.isFinal()) return 0;

            if (cache.get(self)) |cost| return cost;

            const real_cost = result: {
                corridor: for (self.corridor) |token, source_index| {
                    const source = @intCast(u3, source_index);
                    const target_room = token.target_room() orelse continue;

                    var empty: u32 = 0;
                    for (self.rooms[target_room]) |occupied, i| {
                        if (occupied == .Empty) {
                            empty = @intCast(u32, i);
                        } else if (occupied != token) {
                            continue :corridor;
                        }
                    }

                    const left_target = roomCorridor(target_room);
                    const target = if (left_target < source) left_target + 1 else left_target;
                    const range: [2]u3 = if (target < source) .{ target, source } else .{ source + 1, target + 1 };

                    if (self.isCorridorClear(range[0], range[1])) {
                        const steps = corridorSteps(source, target) + 2 + empty;
                        const cost = token.cost() * steps;
                        var next = self;
                        next.corridor[source] = .Empty;
                        next.rooms[target_room][empty] = token;
                        break :result cost + try next.findCost(cache);
                    }
                }

                var best_cost: u32 = std.math.maxInt(u32) / 2;

                rooms: for (self.rooms) |room, room_index| {
                    for (room) |token, depth| {
                        if (token == .Empty) continue;

                        const target_room = token.target_room() orelse unreachable;
                        if (target_room == room_index) {
                            var below = depth + 1;
                            var correct = true;
                            while (below < DEPTH) : (below += 1) {
                                if (room[below] != token) correct = false;
                            }
                            if (correct) continue :rooms;
                        }

                        const left_source = roomCorridor(@intCast(u2, room_index));
                        var target: u3 = 0;
                        while (target < 7) : (target += 1) {
                            const source = if (left_source < target) left_source + 1 else left_source;
                            const range: [2]u3 = if (source <= target) .{ source, target + 1 } else .{ target, left_source + 1 };
                            if (self.isCorridorClear(range[0], range[1])) {
                                const steps = corridorSteps(source, target) + 2 + @intCast(u32, depth);
                                const cost = token.cost() * steps;
                                var next = self;
                                next.corridor[target] = token;
                                next.rooms[room_index][depth] = .Empty;
                                best_cost = @minimum(best_cost, cost + try next.findCost(cache));
                            }
                        }

                        continue :rooms;
                    }
                }

                break :result best_cost;
            };

            try cache.put(self, real_cost);
            return real_cost;
        }
    };
}

fn part1(layout: Layout) !u32 {
    var initial = State(2).initEmpty();
    for (layout.rooms) |level, room| {
        for (level) |token, depth| {
            initial.rooms[room][depth] = token;
        }
    }

    var cache = std.AutoHashMap(State(2), u32).init(alloc);
    return initial.findCost(&cache);
}

fn part2(layout: Layout) !u32 {
    var initial = State(4).initEmpty();

    for (layout.rooms) |level, room| {
        for (level) |token, depth| {
            initial.rooms[room][3 * depth] = token;
        }
    }

    initial.rooms[0][1] = .D;
    initial.rooms[1][1] = .C;
    initial.rooms[2][1] = .B;
    initial.rooms[3][1] = .A;

    initial.rooms[0][2] = .D;
    initial.rooms[1][2] = .B;
    initial.rooms[2][2] = .A;
    initial.rooms[3][2] = .C;

    var cache = std.AutoHashMap(State(4), u32).init(alloc);
    return initial.findCost(&cache);
}

const sample =
    \\#############
    \\#...........#
    \\###B#C#B#D###
    \\  #A#D#C#A#
    \\  #########
;

test "part 1 samples" {
    std.testing.log_level = .debug;
    const output = try config.runWithRawInput(part1, sample);
    try std.testing.expectEqual(@as(u32, 12521), output);
}

test "part 2 samples" {
    std.testing.log_level = .debug;
    const output = try config.runWithRawInput(part2, sample);
    try std.testing.expectEqual(@as(u32, 44169), output);
}
