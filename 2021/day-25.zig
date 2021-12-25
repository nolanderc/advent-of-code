const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 25,
    },
    .input = Map,
    .format = .custom,
};

const Map = struct {
    tiles: [][]u8,

    pub fn parse(text: []const u8) !Map {
        var lines = std.mem.split(u8, text, "\n");
        var tiles = std.ArrayList([]u8).init(alloc);
        while (lines.next()) |line| {
            try tiles.append(try alloc.dupe(u8, line));
        }
        return Map{ .tiles = tiles.toOwnedSlice() };
    }

    pub fn clone(self: @This()) !@This() {
        const rows = try alloc.dupe([]u8, self.tiles);
        for (rows) |*row| {
            row.* = try alloc.dupe(u8, row.*);
        }

        return Map{
            .tiles = rows,
        };
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(map: config.input) !u32 {
    const height = map.tiles.len;
    const width = map.tiles[0].len;

    var curr = try map.clone();
    var next = try map.clone();

    // std.log.debug("", .{});
    // std.log.debug("----- initial -----", .{});
    // for (curr.tiles) |line| {
    //     std.log.debug("{s}", .{line});
    // }

    var steps: u32 = 1;
    while (true) : (steps += 1) {
        var num_changed: u32 = 0;

        {
            // east
            var y: u32 = 0;
            while (y < height) : (y += 1) {
                var x: u32 = 0;
                while (x < width) : (x += 1) {
                    const target = (x + 1) % width;
                    const src = curr.tiles[y][x];
                    const dst = curr.tiles[y][target];
                    if (src == '>' and dst == '.') {
                        next.tiles[y][x] = dst;
                        next.tiles[y][target] = src;
                        num_changed += 1;
                        x += 1;
                    } else {
                        next.tiles[y][x] = src;
                    }
                }
            }
        }

        std.mem.swap(Map, &curr, &next);

        {
            // south
            var x: u32 = 0;
            while (x < width) : (x += 1) {
                var y: u32 = 0;
                while (y < height) : (y += 1) {
                    const target = (y + 1) % height;
                    const src = curr.tiles[y][x];
                    const dst = curr.tiles[target][x];
                    if (src == 'v' and dst == '.') {
                        next.tiles[y][x] = dst;
                        next.tiles[target][x] = src;
                        num_changed += 1;
                        y += 1;
                    } else {
                        next.tiles[y][x] = src;
                    }
                }
            }
        }

        std.mem.swap(Map, &curr, &next);

        // std.log.debug("----- step {} -----", .{steps});
        // for (curr.tiles) |line| {
        //     std.log.debug("{s}", .{line});
        // }

        if (num_changed == 0) return steps;
    }
}

fn part2(_: config.input) !i64 {
    return 0;
}

const sample =
    \\v...>>.vv>
    \\.vv>>.vv..
    \\>>.>v>...v
    \\>>v>>.>.v.
    \\v>v.vv.v..
    \\>.>>..v...
    \\.vv..>.>v.
    \\v.v..>>v.v
    \\....v..v.>
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    const output = try config.runWithRawInput(part1, sample);
    try std.testing.expectEqual(@as(u32, 58), output);
}
