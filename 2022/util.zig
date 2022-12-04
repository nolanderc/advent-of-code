const std = @import("std");
const Allocator = std.mem.Allocator;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const alloc = gpa.allocator();

pub fn loadInput(path: []const u8) ![]const u8 {
    const cwd = std.fs.cwd();
    const file = cwd.openFile(path, .{}) catch |err| blk: {
        if (err == error.FileNotFound) {
            std.log.info("could not open '{s}', enter input below:", .{path});
            break :blk std.io.getStdIn();
        }

        return err;
    };

    const MiB = 1 << 20;
    const text = try file.readToEndAlloc(alloc, 4 * MiB);

    return std.mem.trim(u8, text, &std.ascii.whitespace);
}

/// Given the path to a source file `whatever/foo.zig`, returns the path of the input `whatever/foo.input`.
pub fn inputPath(comptime source_path: []const u8) []const u8 {
    comptime std.debug.assert(std.mem.endsWith(u8, source_path, ".zig"));
    const output_length = source_path.len - ".zig".len + ".input".len;
    comptime var output: [output_length]u8 = undefined;
    comptime std.mem.copy(u8, output[0 .. source_path.len - 4], source_path[0 .. source_path.len - 4]);
    comptime std.mem.copy(u8, output[source_path.len - 4 ..], ".input");
    return &output;
}

pub fn parseInt(comptime T: type, text: []const u8, radix: u8) T {
    return std.fmt.parseInt(u8, text, radix) catch |err| {
        std.debug.panic("could not parse `{s}`: {!}", .{ text, err });
    };
}

pub fn extractMatches(comptime pattern: []const u8, text: []const u8) ?[matchCount(pattern)][]const u8 {
    const fragments = matchFragments(pattern);
    const count = comptime matchCount(pattern);

    var matches: [count][]const u8 = undefined;
    var index: usize = 0;
    var offset: usize = 0;

    if (!std.mem.startsWith(u8, text[offset..], fragments[0])) return null;
    offset += fragments[0].len;

    while (index < count) : (index += 1) {
        const fragment = fragments[index + 1];

        const match_len = if (index + 1 == count and fragment.len == 0)
            text.len - offset
        else
            std.mem.indexOf(u8, text[offset..], fragment) orelse return null;

        matches[index] = text[offset .. offset + match_len];
        offset += match_len + fragment.len;
    }

    return matches;
}

test "extractMatches" {
    const text = "12-3,456-78";
    const pattern = "%-%,%-%";
    const expected = [4][]const u8{ "12", "3", "456", "78" };
    const matches = extractMatches(pattern, text) orelse unreachable;
    try std.testing.expectEqual(expected.len, matches.len);
    for (matches) |match, index| {
        try std.testing.expectEqualStrings(expected[index], match);
    }
}

fn matchCount(comptime pattern: []const u8) usize {
    return std.mem.count(u8, pattern, "%");
}

test "matchCount" {
    try std.testing.expectEqual(2, comptime matchCount("[%,%]"));
    try std.testing.expectEqual(3, comptime matchCount("%%%"));
}

fn matchFragments(comptime pattern: []const u8) [matchCount(pattern) + 1][]const u8 {
    var fragments: [matchCount(pattern) + 1][]const u8 = undefined;
    var index: usize = 0;
    var splits = std.mem.split(u8, pattern, "%");
    while (splits.next()) |fragment| {
        fragments[index] = fragment;
        index += 1;
    }
    std.debug.assert(index == fragments.len);
    return fragments;
}
