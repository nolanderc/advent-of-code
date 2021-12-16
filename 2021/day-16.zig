const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 16,
    },
    .input = Packet,
    .format = .custom,
};

const Packet = struct {
    version: u3,
    kind: Kind,
    data: union {
        children: []Packet,
        literal: u64,
    },

    const Kind = enum(u3) {
        sum = 0,
        product = 1,
        minimum = 2,
        maximum = 3,
        literal = 4,
        greater = 5,
        less = 6,
        equal = 7,
    };

    pub fn parse(text: []const u8) !@This() {
        const buffer = try alloc.alloc(u8, (text.len + 1) / 2);
        defer alloc.free(buffer);

        var stream = std.io.fixedBufferStream(buffer);
        var bit_writer = std.io.bitWriter(.Big, stream.writer());

        for (text) |char| {
            const value = switch (char) {
                '0'...'9' => char - '0',
                'A'...'F' => char - 'A' + 10,
                else => return error.InvalidDigit,
            };
            try bit_writer.writeBits(value, 4);
        }
        try bit_writer.flushBits();

        stream.reset();
        // var reader = stream.reader();
        // var bit_reader = std.io.bitReader(.Big, reader);

        var bit_reader = BitReader.init(stream.reader());
        return parseBits(&bit_reader);
    }

    const BitReader = struct {
        inner: std.io.BitReader(.Big, Reader),
        bits_read: usize,

        const Reader = std.io.FixedBufferStream([]u8).Reader;

        pub fn init(reader: Reader) @This() {
            return .{
                .inner = std.io.bitReader(.Big, reader),
                .bits_read = 0,
            };
        }

        pub fn readBits(self: *@This(), comptime T: type) !T {
            const bits = @typeInfo(T).Int.bits;
            const value = try self.inner.readBitsNoEof(T, bits);
            self.bits_read += bits;
            return value;
        }
    };

    fn parseBits(reader: *BitReader) anyerror!@This() {
        var packet: Packet = undefined;

        packet.version = try reader.readBits(u3);
        packet.kind = @intToEnum(Kind, try reader.readBits(u3));
        if (packet.kind == .literal) {
            var literal: u64 = 0;
            while (true) {
                const value = try reader.readBits(u5);
                literal <<= 4;
                literal += @truncate(u4, value);
                if ((value >> 4) & 1 == 0) {
                    break;
                }
            }
            packet.data = .{ .literal = literal };
        } else {
            var children = std.ArrayList(Packet).init(alloc);
            defer children.deinit();

            const length_kind = try reader.readBits(u1);
            if (length_kind == 0) {
                const length = try reader.readBits(u15);
                const start_bits = reader.bits_read;
                while (reader.bits_read - start_bits < length) {
                    const child = try Packet.parseBits(reader);
                    try children.append(child);
                }
            } else {
                const count = try reader.readBits(u11);
                while (children.items.len < count) {
                    const child = try Packet.parseBits(reader);
                    try children.append(child);
                }
            }

            packet.data = .{ .children = children.toOwnedSlice() };
        }

        return packet;
    }

    pub fn format(self: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try self.formatRecursive(writer, 0);
    }

    fn formatRecursive(self: *const @This(), writer: anytype, indent: u32) @TypeOf(writer).Error!void {
        try writer.print("{{\n", .{});

        try writer.writeByteNTimes(' ', indent + 4);
        try writer.print(".version = {b:0>3} ({d}),\n", .{ self.version, self.version });

        try writer.writeByteNTimes(' ', indent + 4);
        try writer.print(".kind    = {b:0>3} ({d}),\n", .{ self.kind, self.kind });

        if (self.kind == .literal) {
            try writer.writeByteNTimes(' ', indent + 4);
            try writer.print(".data    = {b} ({}),\n", .{ self.data.literal, self.data.literal });
        } else {
            try writer.writeByteNTimes(' ', indent + 4);
            try writer.print(".data    = {{", .{});
            for (self.data.children) |*child| {
                try writer.print(" ", .{});
                try child.formatRecursive(writer, indent + 4);
                try writer.print(",", .{});
            }
            try writer.print("\n", .{});
            try writer.writeByteNTimes(' ', indent + 4);
            try writer.print("}},\n", .{});
        }

        try writer.writeByteNTimes(' ', indent);
        try writer.print("}}", .{});
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(packet: config.input) !u64 {
    var sum: u32 = 0;
    sumVersions(packet, &sum);
    return sum;
}

fn sumVersions(packet: Packet, sum: *u32) void {
    sum.* += packet.version;
    if (packet.kind != .literal) {
        for (packet.data.children) |child| {
            sumVersions(child, sum);
        }
    }
}

fn part2(packet: config.input) !u64 {
    return evaluate(packet);
}

fn evaluate(packet: Packet) u64 {
    switch (packet.kind) {
        .literal => return packet.data.literal,
        else => {
            var result = evaluate(packet.data.children[0]);
            for (packet.data.children[1..]) |child| {
                switch (packet.kind) {
                    .literal => unreachable,
                    .sum => result = result + evaluate(child),
                    .product => result = result * evaluate(child),
                    .minimum => result = @minimum(result, evaluate(child)),
                    .maximum => result = @maximum(result, evaluate(child)),
                    .greater => result = @boolToInt(result > evaluate(child)),
                    .less => result = @boolToInt(result < evaluate(child)),
                    .equal => result = @boolToInt(result == evaluate(child)),
                }
            }
            return result;
        },
    }
}

const part1_samples = .{
    .{ .message = "8A004A801A8002F478", .answer = 16 },
    .{ .message = "620080001611562C8802118E34", .answer = 12 },
    .{ .message = "C0015000016115A2E0802F182340", .answer = 23 },
    .{ .message = "A0016C880162017C3686B18A3D4780", .answer = 31 },
};

test "part 1 sample" {
    std.testing.log_level = .debug;
    inline for (part1_samples) |sample| {
        try std.testing.expectEqual(
            @as(u64, sample.answer),
            try config.runWithRawInput(part1, sample.message),
        );
    }
}

const part2_samples = .{
    .{ .message = "C200B40A82", .answer = 3 },
    .{ .message = "04005AC33890", .answer = 54 },
    .{ .message = "880086C3E88112", .answer = 7 },
    .{ .message = "CE00C43D881120", .answer = 9 },
    .{ .message = "D8005AC2A8F0", .answer = 1 },
    .{ .message = "F600BC2D8F", .answer = 0 },
    .{ .message = "9C005AC2F8F0", .answer = 0 },
    .{ .message = "9C0141080250320F1802104A08", .answer = 1 },
};

test "part 2 sample" {
    std.testing.log_level = .debug;
    inline for (part2_samples) |sample| {
        try std.testing.expectEqual(
            @as(u64, sample.answer),
            try config.runWithRawInput(part2, sample.message),
        );
    }
}
