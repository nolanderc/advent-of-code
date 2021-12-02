const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

pub fn main() !void {
    defer _ = utils.gpa.detectLeaks();
    std.log.info("https://adventofcode.com/2018/day/3", .{});

    var input = try utils.InputReader.initFromStdIn(alloc);
    defer input.deinit(alloc);
    var claims = try input.parseLines("#{} @ {},{}: {}x{}", Claim).collectToSlice(alloc);
    defer alloc.free(claims);

    std.log.info("part 1: {}", .{try part1(claims)});
    std.log.info("part 2: {}", .{try part2(claims)});
}

const Claim = struct {
    id: u32,
    x: u32,
    y: u32,
    w: u32,
    h: u32,
};

fn part1(claims: []const Claim) !u32 {
    var grid = try Grid.init(claims);
    defer grid.deinit();

    var count: u32 = 0;
    for (grid.cells) |cell| {
        if (cell >= 2) count += 1;
    }

    return count;
}

fn part2(claims: []const Claim) !?u32 {
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
