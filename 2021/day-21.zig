const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 21,
    },
    .input = struct { player: u8, position: u8 },
    .format = .{ .pattern = "Player {} starting position: {}" },
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(input: []config.input) !u64 {
    var scores = [2]u32{ 0, 0 };
    var positions = [2]u32{ input[0].position - 1, input[1].position - 1 };

    var rolls: u32 = 0;
    while (scores[0] < 1000 and scores[1] < 1000) {
        const player: u32 = if (rolls % 6 == 0) 0 else 1;

        var i: u32 = 0;
        while (i < 3) : (i += 1) {
            positions[player] += 1 + rolls % 100;
            rolls += 1;
        }

        scores[player] += 1 + positions[player] % 10;
    }

    return rolls * @minimum(scores[0], scores[1]);
}

const distribution = blk: {
    var dist = [_]u8{0} ** 10;

    var a: u8 = 1;
    while (a <= 3) : (a += 1) {
        var b: u8 = 1;
        while (b <= 3) : (b += 1) {
            var c: u8 = 1;
            while (c <= 3) : (c += 1) {
                dist[a + b + c] += 1;
            }
        }
    }

    break :blk dist;
};

fn part2(input: []config.input) !u64 {
    const initial = QuantumState{
        .scores = .{ 0, 0 },
        .positions = .{ input[0].position - 1, input[1].position - 1 },
        .turn = 0,
    };

    var cache = QuantumCache.init(alloc);
    const wins = playQuantum(initial, &cache);

    return @maximum(wins[0], wins[1]);
}

const QuantumState = struct {
    scores: [2]u8,
    positions: [2]u8,
    turn: u1,

    pub fn move(self: @This(), times: u8) @This() {
        var next: QuantumState = self;
        next.turn = 1 - self.turn;

        const position = &next.positions[self.turn];
        position.* = (position.* + times) % 10;
        next.scores[self.turn] += 1 + position.*;

        return next;
    }
};

const QuantumCache = std.AutoHashMap(QuantumState, [2]u64);

fn playQuantum(state: QuantumState, cache: *QuantumCache) [2]u64 {
    if (state.scores[0] >= 21) return .{ 1, 0 };
    if (state.scores[1] >= 21) return .{ 0, 1 };

    if (cache.get(state)) |wins| return wins;

    var total_wins = [2]u64{ 0, 0 };
    for (distribution[3..]) |count, roll| {
        const wins = playQuantum(state.move(@intCast(u8, 3 + roll)), cache);
        total_wins[0] += count * wins[0];
        total_wins[1] += count * wins[1];
    }

    cache.put(state, total_wins) catch @panic("failed to insert into cache");

    return total_wins;
}

const sample =
    \\Player 1 starting position: 4
    \\Player 2 starting position: 8
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(
        @as(u64, 739785),
        try config.runWithRawInput(part1, sample),
    );
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(
        @as(u64, 444356092776315),
        try config.runWithRawInput(part2, sample),
    );
}
