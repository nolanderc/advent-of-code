const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 20,
    },
    .input = ImageAlgorithm,
    .format = .custom,
};

const Pixel = struct {
    x: i32,
    y: i32,
};

const ImageAlgorithm = struct {
    algorithm: *const [512]u8,
    start: []Pixel,

    width: u32,
    height: u32,

    pub fn parse(text: []const u8) !@This() {
        _ = text;

        const algorithm = text[0..512];

        var start = std.ArrayList(Pixel).init(alloc);
        defer start.deinit();

        var lines = std.mem.split(u8, text[514..], "\n");
        var row: i32 = 0;
        var width: u32 = 0;
        var height: u32 = 0;
        while (lines.next()) |line| : (row += 1) {
            height += 1;
            width = @maximum(width, @intCast(u32, line.len));

            for (line) |pixel, col| {
                if (pixel == '#') {
                    try start.append(Pixel{
                        .x = @intCast(i32, col),
                        .y = row,
                    });
                }
            }
        }

        return @This(){
            .algorithm = algorithm,
            .start = start.toOwnedSlice(),
            .width = width,
            .height = height,
        };
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(input: config.input) !u64 {
    const pixels = try apply(input, 2);
    return pixels.count();
}

fn part2(input: config.input) !u64 {
    const pixels = try apply(input, 50);
    return pixels.count();
}

const PixelSet = std.AutoHashMap(Pixel, void);

fn apply(algo: ImageAlgorithm, steps: u32) !PixelSet {
    var pixels = PixelSet.init(alloc);
    defer pixels.deinit();
    var pixels_new = PixelSet.init(alloc);
    defer pixels_new.deinit();

    for (algo.start) |pixel| {
        try pixels.put(pixel, {});
    }

    var x_min: i32 = 0;
    var x_max: i32 = @intCast(i32, algo.width);
    var y_min: i32 = 0;
    var y_max: i32 = @intCast(i32, algo.height);

    var border: u8 = '.';

    var step: u32 = 0;
    while (step < steps) : (step += 1) {
        x_min -= 1;
        x_max += 1;
        y_min -= 1;
        y_max += 1;

        var y: i32 = y_min;
        while (y <= y_max) : (y += 1) {
            var x: i32 = x_min;
            while (x <= x_max) : (x += 1) {
                var bits: u9 = 0;

                var dy: i32 = -1;
                while (dy <= 1) : (dy += 1) {
                    var dx: i32 = -1;
                    while (dx <= 1) : (dx += 1) {
                        bits <<= 1;
                        const pixel = Pixel{
                            .x = x + dx,
                            .y = y + dy,
                        };
                        if (pixels.get(pixel) != null) {
                            bits |= 1;
                        } else if (border == '#') {
                            const outside_x = pixel.x <= x_min or pixel.x >= x_max;
                            const outside_y = pixel.y <= y_min or pixel.y >= y_max;
                            if (outside_x or outside_y) {
                                bits |= 1;
                            }
                        }
                    }
                }

                const new = algo.algorithm[bits];
                if (new == '#') {
                    try pixels_new.put(Pixel{ .x = x, .y = y }, {});
                }
            }
        }

        if (border == '.') {
            border = algo.algorithm[0];
        } else {
            border = algo.algorithm[512 - 1];
        }

        std.mem.swap(PixelSet, &pixels, &pixels_new);
        pixels_new.clearRetainingCapacity();
    }

    return pixels;
}

const sample =
    \\..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#
    \\
    \\#..#.
    \\#....
    \\##..#
    \\..#..
    \\..###
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(
        @as(u64, 35),
        try config.runWithRawInput(part1, sample),
    );
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(
        @as(u64, 3351),
        try config.runWithRawInput(part2, sample),
    );
}
