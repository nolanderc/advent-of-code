const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

pub fn main() !void {
    defer _ = utils.gpa.detectLeaks();
    std.log.info("https://adventofcode.com/2018/day/1", .{});

    var input = try utils.InputReader.initFromStdIn(alloc);
    defer input.deinit(alloc);
    var deltas = try input.parseLines("{}", i32).collectToSlice(alloc);
    defer alloc.free(deltas);

    var sum: i32 = 0;
    for (deltas) |delta| {
        sum += delta;
    }
    std.log.info("part 1: {}", .{sum});

    var i: usize = 0;
    var frequency: i32 = 0;
    var frequencies = std.AutoHashMap(i32, void).init(alloc);
    defer frequencies.deinit();
    while ((try frequencies.getOrPut(frequency)).found_existing == false) {
        frequency += deltas[i];
        i = (i + 1) % deltas.len;
    }

    std.log.info("part 2: {}", .{frequency});
}
