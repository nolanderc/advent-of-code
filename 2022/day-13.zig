const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input: []const u8) !u64 {
    const text = std.mem.trim(u8, input, &std.ascii.whitespace);
    var pairs = std.mem.split(u8, text, "\n\n");

    var sum: u64 = 0;
    var index: u32 = 0;

    while (pairs.next()) |pair| : (index += 1) {
        const mid = std.mem.indexOfScalar(u8, pair, '\n') orelse std.debug.panic("invalid pair: {s}", .{pair});
        const left = try parsePacket(pair[0..mid]);
        const right = try parsePacket(pair[mid + 1 ..]);

        const order = packetOrder(left, right);
        if (order != .gt) {
            sum += index + 1;
        }
    }

    return sum;
}

fn part2(input: []const u8) !u64 {
    const text = std.mem.trim(u8, input, &std.ascii.whitespace);
    var packet_lines = std.mem.tokenize(u8, text, "\n");
    var packets = std.ArrayList(Packet).init(alloc);

    while (packet_lines.next()) |line| {
        try packets.append(try parsePacket(line));
    }

    try packets.append(try parsePacket("[[2]]"));
    try packets.append(try parsePacket("[[6]]"));

    std.sort.sort(Packet, packets.items, {}, struct {
        fn order(context: void, left: Packet, right: Packet) bool {
            _ = context;
            return packetOrder(left, right) == .lt;
        }
    }.order);

    var a: u64 = 0;
    var b: u64 = 0;

    var buffer = try alloc.alloc(u8, input.len);
    for (packets.items) |packet, index| {
        const result = try std.fmt.bufPrint(buffer, "{}", .{packet});
        if (std.mem.eql(u8, result, "[[2]]")) a = index + 1;
        if (std.mem.eql(u8, result, "[[6]]")) b = index + 1;
    }

    return a * b;
}

fn packetOrder(left: Packet, right: Packet) std.math.Order {
    switch (left) {
        .int => |left_int| {
            switch (right) {
                .int => |right_int| return std.math.order(left_int, right_int),
                .list => |right_list| return orderListList(&[1]Packet{left}, right_list),
            }
        },
        .list => |left_list| {
            switch (right) {
                .int => return orderListList(left_list, &[1]Packet{right}),
                .list => |right_list| return orderListList(left_list, right_list),
            }
        },
    }

    return .eq;
}

fn orderListList(left: []Packet, right: []Packet) std.math.Order {
    var i: usize = 0;
    while (i < left.len and i < right.len) : (i += 1) {
        const order = packetOrder(left[i], right[i]);
        if (order != .eq) return order;
    }

    return std.math.order(left.len, right.len);
}

const Packet = union(enum) {
    list: []Packet,
    int: u32,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        switch (self) {
            .int => |value| try writer.print("{}", .{value}),
            .list => |inner| {
                try writer.writeAll("[");
                for (inner) |value, index| {
                    if (index > 0) try writer.writeAll(",");
                    try writer.print("{}", .{value});
                }
                try writer.writeAll("]");
            },
        }
    }
};

fn parsePacket(text: []const u8) !Packet {
    var accumulator = std.ArrayList(Packet).init(alloc);
    try accumulator.ensureTotalCapacity(text.len);

    var list_starts = std.ArrayList(usize).init(alloc);
    try list_starts.ensureTotalCapacity(16);

    var i: usize = 0;
    while (i < text.len) {
        if (text[i] == '[') {
            try list_starts.append(accumulator.items.len);
            i += 1;
        } else if (text[i] == ']') {
            const start = list_starts.popOrNull() orelse return error.UnbalancedLists;
            const list = try alloc.dupe(Packet, accumulator.items[start..]);
            try accumulator.resize(start);
            try accumulator.append(.{ .list = list });
            i += 1;
        } else if (std.ascii.isDigit(text[i])) {
            var int: u32 = 0;
            while (std.ascii.isDigit(text[i])) : (i += 1) {
                int *= 10;
                int += text[i] - '0';
            }
            try accumulator.append(.{ .int = int });
        }

        if (i < text.len and text[i] == ',') i += 1;
    }

    if (accumulator.items.len != 1) {
        return error.NoRootList;
    }

    return accumulator.pop();
}

const sample =
    \\[1,1,3,1,1]
    \\[1,1,5,1,1]
    \\
    \\[[1],[2,3,4]]
    \\[[1],4]
    \\
    \\[9]
    \\[[8,7,6]]
    \\
    \\[[4,4],4,4]
    \\[[4,4],4,4,4]
    \\
    \\[7,7,7,7]
    \\[7,7,7]
    \\
    \\[]
    \\[3]
    \\
    \\[[[]]]
    \\[[]]
    \\
    \\[1,[2,[3,[4,[5,6,7]]]],8,9]
    \\[1,[2,[3,[4,[5,6,0]]]],8,9]
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 13), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 140), try part2(sample));
}
