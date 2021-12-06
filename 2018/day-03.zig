const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2018,
        .day = 3,
    },
    .input = Claim,
    .format = .{ .pattern = "#{} @ {},{}: {}x{}" },
};

pub fn main() !void {
    std.log.info("part 1: {}", .{config.run(part1)});
    std.log.info("part 2: {}", .{config.run(part2)});
}

const Claim = struct {
    id: u32,
    x: u32,
    y: u32,
    w: u32,
    h: u32,
};

fn part1(claims: []const config.input) !u32 {
    var grid = try Grid.init(claims);
    defer grid.deinit();

    var count: u32 = 0;
    for (grid.cells) |cell| {
        if (cell >= 2) count += 1;
    }

    return count;
}

fn part2(claims: []const config.input) !?u32 {
    var grid = try Grid.init(claims);
    defer grid.deinit();

    for (claims) |claim| {
        var count: u32 = 0;
        var row = claim.y;
        while (row < claim.y + claim.h) : (row += 1) {
            const row_start = row * grid.width + claim.x;
            const cells = grid.cells[row_start .. row_start + claim.w];
            for (cells) |cell| count += cell;
        }
        if (count == claim.w * claim.h) return claim.id;
    }

    return null;
}

const Grid = struct {
    width: u32,
    height: u32,
    cells: []u32,

    pub fn deinit(self: *@This()) void {
        alloc.free(self.cells);
    }

    pub fn init(claims: []const Claim) !Grid {
        var max_x: u32 = 0;
        var max_y: u32 = 0;

        for (claims) |claim| {
            max_x = @maximum(max_x, claim.x + claim.w);
            max_y = @maximum(max_y, claim.y + claim.h);
        }

        var grid = Grid{
            .width = max_x,
            .height = max_y,
            .cells = try alloc.alloc(u32, max_x * max_y),
        };
        std.mem.set(u32, grid.cells, 0);

        for (claims) |claim| {
            var row = claim.y;
            while (row < claim.y + claim.h) : (row += 1) {
                const row_start = row * grid.width + claim.x;
                const cells = grid.cells[row_start .. row_start + claim.w];
                for (cells) |*cell| {
                    cell.* += 1;
                }
            }
        }

        return grid;
    }
};

const sample =
    \\#1 @ 1,3: 4x4
    \\#2 @ 3,1: 4x4
    \\#3 @ 5,5: 2x2
;

test "part 1 sample" {
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 4);
}

test "part 2 sample" {
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 3);
}
