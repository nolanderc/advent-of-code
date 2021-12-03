const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 3,
    },
    .input = []const u8,
    .format = .{ .pattern = "{}" },
};

pub fn main() anyerror!void {
    try config.run(solution);
}

fn solution(input: []const config.input) !void {
    std.log.info("part 1: {}", .{try part1(input)});
    std.log.info("part 2: {}", .{try part2(input)});
}

fn part1(diagnostics: []const config.input) !u32 {
    const num_bits = if (diagnostics.len > 0) @truncate(u5, diagnostics[0].len) else 0;
    var gamma: u32 = 0;

    var bit: u5 = 0;
    while (bit < num_bits) : (bit += 1) {
        var ones: u32 = 0;
        for (diagnostics) |diagnostic| {
            if (diagnostic[num_bits - bit - 1] == '1') ones += 1;
        }
        const zeros = diagnostics.len - ones;
        if (ones > zeros) {
            gamma |= @as(u32, 1) << bit;
        }
    }

    const epsilon = (~gamma) & ((@as(u32, 1) << num_bits) - 1);

    return epsilon * gamma;
}

fn part2(diagnostics: []const config.input) !u32 {
    const num_bits = if (diagnostics.len > 0) @truncate(u5, diagnostics[0].len) else 0;

    var oxygen = try std.ArrayList(u32).initCapacity(alloc, diagnostics.len);
    var carbon = try std.ArrayList(u32).initCapacity(alloc, diagnostics.len);

    for (diagnostics) |diag| {
        const bits = try std.fmt.parseInt(u32, diag, 2);
        try oxygen.append(bits);
        try carbon.append(bits);
    }

    var bit: u5 = 0;
    while (bit < num_bits) : (bit += 1) {
        const mask = @as(u32, 1) << (num_bits - bit - 1);

        const oxygen_zeros = countZeros(oxygen.items, mask);
        const carbon_zeros = countZeros(carbon.items, mask);

        const oxygen_ones = oxygen.items.len - oxygen_zeros;
        const carbon_ones = carbon.items.len - carbon_zeros;

        const oxygen_keep_mask = if (oxygen_ones >= oxygen_zeros) mask else 0;
        const carbon_keep_mask = if (carbon_ones < carbon_zeros) mask else 0;

        if (oxygen.items.len > 1) filterMask(&oxygen, mask, oxygen_keep_mask);
        if (carbon.items.len > 1) filterMask(&carbon, mask, carbon_keep_mask);
    }

    const oxygen_rating = oxygen.items[0];
    const carbon_rating = carbon.items[0];

    return oxygen_rating * carbon_rating;
}

fn countZeros(numbers: []const u32, mask: u32) u32 {
    var zeros: u32 = 0;
    for (numbers) |bits| {
        if (bits & mask == 0) zeros += 1;
    }
    return zeros;
}

fn filterMask(numbers: *std.ArrayList(u32), mask: u32, keep: u32) void {
    var i: usize = 0;
    while (i < numbers.items.len) {
        if (numbers.items[i] & mask != keep) {
            _ = numbers.swapRemove(i);
        } else {
            i += 1;
        }
    }
}

test "part 1 sample input" {
    const sample =
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
    ;
    try std.testing.expectEqual(@as(u32, 198), try config.runWithRawInput(part1, sample));
}

test "part 2 sample input" {
    const sample =
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
    ;
    try std.testing.expectEqual(@as(u32, 230), try config.runWithRawInput(part2, sample));
}
