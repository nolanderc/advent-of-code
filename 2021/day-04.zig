const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 4,
    },
    .input = Bingo,
    .format = .custom,
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(bingo: config.input) !u32 {
    return play(bingo).winner;
}

fn part2(bingo: config.input) !u32 {
    return play(bingo).loser;
}

const Bingo = struct {
    numbers: []const u8,
    boards: []const BingoBoard,

    const BingoBoard = [5][5]u8;
    const Location = struct { row: u8, col: u8 };

    fn findNumber(board: *const BingoBoard, number: u8) ?Location {
        for (board) |row, row_index| {
            for (row) |cell, col_index| {
                if (cell == number) return Location{ .row = @intCast(u8, row_index), .col = @intCast(u8, col_index) };
            }
        }
        return null;
    }

    pub fn parse(text: []const u8) !Bingo {
        var numbers = std.ArrayList(u8).init(alloc);
        defer numbers.deinit();
        var boards = std.ArrayList(BingoBoard).init(alloc);
        defer boards.deinit();

        var lines = std.mem.split(u8, text, "\n");

        const numbers_line = lines.next() orelse return error.EndOfStream;
        var number_tokens = std.mem.tokenize(u8, numbers_line, ",");
        while (number_tokens.next()) |token| {
            try numbers.append(try std.fmt.parseInt(u8, token, 10));
        }

        while (lines.next()) |_| {
            const board = try boards.addOne();
            for (board) |*row| {
                const line = lines.next() orelse return error.EndOfStream;
                var tokens = std.mem.tokenize(u8, line, " ");

                var i: u32 = 0;
                while (i < row.len) : (i += 1) {
                    const token = tokens.next() orelse return error.EndOfStream;
                    row[i] = try std.fmt.parseInt(u8, token, 10);
                }
            }
        }

        return Bingo{ .numbers = numbers.toOwnedSlice(), .boards = boards.toOwnedSlice() };
    }
};

const GameResult = struct {
    winner: u32,
    loser: u32,
};

fn play(bingo: Bingo) GameResult {
    var best_steps: usize = bingo.numbers.len;
    var winner_score: u32 = 0;

    var worst_steps: usize = 0;
    var loser_score: u32 = 0;

    for (bingo.boards) |*board| {
        var row_sums = [_]u8{0} ** 5;
        var col_sums = [_]u8{0} ** 5;

        var unmarked_sum: u32 = 0;
        for (board) |row| {
            for (row) |cell| unmarked_sum += cell;
        }

        for (bingo.numbers) |number, step| {
            const loc = Bingo.findNumber(board, number) orelse continue;
            row_sums[loc.row] += 1;
            col_sums[loc.col] += 1;
            unmarked_sum -= number;

            if (row_sums[loc.row] == 5 or col_sums[loc.col] == 5) {
                const score = unmarked_sum * number;
                if (step < best_steps) {
                    best_steps = step;
                    winner_score = score;
                }
                if (step >= worst_steps) {
                    worst_steps = step;
                    loser_score = score;
                }
                break;
            }
        }
    }

    return .{
        .winner = winner_score,
        .loser = loser_score,
    };
}

const sample =
    \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
    \\
    \\22 13 17 11  0
    \\ 8  2 23  4 24
    \\21  9 14 16  7
    \\ 6 10  3 18  5
    \\ 1 12 20 15 19
    \\
    \\ 3 15  0  2 22
    \\ 9 18 13 17  5
    \\19  8  7 25 23
    \\20 11 10 24  4
    \\14 21 16 12  6
    \\
    \\14 21 17 24  4
    \\10 16 15  9 19
    \\18  8 23 26 20
    \\22 11 13  6  5
    \\ 2  0 12  3  7
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(u32, 4512), try config.runWithRawInput(part1, sample));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(u32, 1924), try config.runWithRawInput(part2, sample));
}
