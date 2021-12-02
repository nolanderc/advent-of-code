const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

pub fn main() !void {
    defer _ = utils.gpa.detectLeaks();
    std.log.info("https://adventofcode.com/2018/day/2", .{});

    var input = try utils.InputReader.initFromStdIn(alloc);
    defer input.deinit(alloc);
    var ids = try input.parseLines("{}", []const u8).collectToSlice(alloc);
    defer alloc.free(ids);

    std.log.info("part 1: {}", .{part1(ids)});
    std.log.info("part 2: {s}", .{part2(ids)});
}

fn part1(ids: [][]const u8) u32 {
    var num_2: u32 = 0;
    var num_3: u32 = 0;

    for (ids) |id| {
        var counts = [_]u8{0} ** ('z' - 'a' + 1);
        for (id) |char| {
            counts[char - 'a'] += 1;
        }

        var has_2 = false;
        var has_3 = false;
        for (counts) |count| {
            if (count == 2) has_2 = true;
            if (count == 3) has_3 = true;
        }

        if (has_2) num_2 += 1;
        if (has_3) num_3 += 1;
    }

    return num_2 * num_3;
}

fn part2(ids: [][]const u8) ?[2][]const u8 {
    for (ids) |a| {
        for (ids) |b| {
            if (a.ptr == b.ptr) continue;

            var diff_count = @minimum(a.len - b.len, b.len - a.len);
            var diff_index: u32 = 0;
            var i: u32 = 0;

            while (i < a.len and i < b.len) : (i += 1) {
                if (a[i] != b[i]) {
                    diff_count += 1;
                    diff_index = i;
                }
            }

            if (diff_count == 1) return [_][]const u8{ a[0..diff_index], a[diff_index + 1 ..] };
        }
    }

    return null;
}
