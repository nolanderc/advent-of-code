const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub const log_level = .info;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input)});
}

fn part1(input: []const u8) !u64 {
    var moves = std.mem.trim(u8, input, &std.ascii.whitespace);

    var simulator = Simulator{ .moves = moves };
    var i: u32 = 0;
    while (i < 2022) : (i += 1) {
        const shape = Shape.templates[i % Shape.templates.len];
        _ = try simulator.drop(shape);
    }

    return simulator.height();
}

fn part2(input: []const u8) !u64 {
    var moves = std.mem.trim(u8, input, &std.ascii.whitespace);

    const snapshot_size = 64;
    const State = struct {
        move: u16,
        shape: u8,
        rows: [snapshot_size]u7,
    };

    const Snapshot = struct {
        index: u64,
        height: u64,
    };

    var old_states = std.AutoHashMap(State, Snapshot).init(alloc);

    var simulator = Simulator{ .moves = moves };
    var i: u64 = 0;
    var target: u64 = 1e12;
    var bonus_height: u64 = 0;

    while (i < target) : (i += 1) {
        const shape_index = i % Shape.templates.len;

        if (bonus_height == 0 and simulator.stack.rows.len >= snapshot_size) {
            var state = State{
                .move = @intCast(u16, simulator.move_index),
                .shape = @intCast(u8, shape_index),
                .rows = [1]u7{0} ** snapshot_size,
            };
            const snapshot_start = simulator.stack.rows.len - snapshot_size;
            std.mem.copy(u7, &state.rows, simulator.stack.rows.slice()[snapshot_start..]);
            var entry = try old_states.getOrPut(state);
            if (entry.found_existing) {
                const step = i - entry.value_ptr.index;
                const delta = simulator.height() - entry.value_ptr.height;
                const chunks = (target - i) / step;
                bonus_height = delta * chunks;
                i += chunks * step;
            } else {
                entry.value_ptr.* = .{ .index = i, .height = simulator.height() };
            }
        }

        _ = try simulator.drop(Shape.templates[shape_index]);
    }

    return bonus_height + simulator.height();
}

const Simulator = struct {
    stack: Stack = Stack{},
    move_index: usize = 0,
    moves: []const u8,

    fn height(self: *@This()) usize {
        return self.stack.height();
    }

    fn drop(self: *@This(), init_shape: Shape) !usize {
        var shape = init_shape;
        var bottom: u32 = @intCast(u32, self.height()) + 3;

        while (true) {
            const move = self.moves[self.move_index];
            self.move_index += 1;
            if (self.move_index >= self.moves.len) self.move_index -= self.moves.len;

            const next = switch (move) {
                '<' => shape.left() orelse shape,
                '>' => shape.right() orelse shape,
                else => std.debug.panic("invalid move: {c}", .{move}),
            };

            shape = if (self.stack.intersects(bottom, next)) shape else next;

            if (bottom == 0 or self.stack.intersects(bottom - 1, shape)) {
                const extent = self.height() - bottom;
                try self.stack.add(bottom, shape);
                return extent;
            }

            bottom -= 1;
        }
    }
};

const Stack = struct {
    rows: std.BoundedArray(u7, 128) = .{},
    base: u64 = 0,

    fn intersects(self: *@This(), bottom: u64, shape: Shape) bool {
        var y: u3 = 0;

        while (y < shape.height) : (y += 1) {
            const row = bottom + y;
            const bits = shape.get(y);
            if (row >= self.height()) return false;
            if (self.get(row) & bits != 0) return true;
        }

        return false;
    }

    fn add(self: *@This(), bottom: u64, shape: Shape) !void {
        const new_height = bottom + shape.height;
        if (new_height >= self.height()) {
            try self.rows.appendNTimes(0, new_height - self.height());
        }

        var y: u3 = 0;
        while (y < shape.height) : (y += 1) {
            const row = bottom + y;
            const bits = shape.get(y);
            self.rows.slice()[row - self.base] |= bits;
        }

        if (self.rows.len > 120) {
            const offset = self.rows.len - 64;
            std.mem.copy(u7, self.rows.buffer[0..64], self.rows.buffer[offset..self.rows.len]);
            self.base += offset;
            self.rows.len = 64;
        }
    }

    fn get(self: *@This(), row: u64) u7 {
        return self.rows.slice()[row - self.base];
    }

    fn height(self: *@This()) u64 {
        return self.base + self.rows.len;
    }

    fn print(self: *@This()) !void {
        var y = self.rows.len;
        var buffer = std.io.bufferedWriter(std.io.getStdOut().writer());
        var writer = buffer.writer();
        while (y > 0) {
            y -= 1;
            const row = self.rows.slice()[y];
            var mask: u7 = 1 << 6;

            try writer.writeByte('|');
            while (mask != 0) : (mask >>= 1) {
                const char: u8 = if (row & mask == 0) '.' else '#';
                try writer.writeByte(char);
            }
            try writer.writeByte('|');
            try writer.writeByte('\n');
        }
        try writer.writeByteNTimes('-', 9);
        try writer.writeByte('\n');
        try writer.writeByte('\n');
        try buffer.flush();
    }
};

const Shape = struct {
    height: u3,
    rows: [4]u7,

    fn get(self: @This(), row: u3) u7 {
        return self.rows[self.height - 1 - row];
    }

    fn left(self: @This()) ?Shape {
        var new = self;
        for (self.rows[0..self.height]) |bits, row| {
            if ((bits >> 6) & 1 == 1) return null;
            new.rows[row] = bits << 1;
        }
        return new;
    }

    fn right(self: @This()) ?Shape {
        var new = self;
        for (self.rows[0..self.height]) |bits, row| {
            if (bits & 1 == 1) return null;
            new.rows[row] = bits >> 1;
        }
        return new;
    }

    fn fromText(comptime height: u3, text_rows: [height][7]u8) @This() {
        var rows = [4]u7{ 0, 0, 0, 0 };

        var row: u3 = 0;
        while (row < height) : (row += 1) {
            var bits: u7 = 0;
            const text_row: [7]u8 = text_rows[row];
            for (text_row) |char| {
                bits <<= 1;
                if (char == '#') bits |= 1;
            }
            rows[row] = bits;
        }

        return .{ .height = height, .rows = rows };
    }

    const templates: [5]@This() = .{
        @This().fromText(1, .{
            "..####.".*,
        }),
        @This().fromText(3, .{
            "...#...".*,
            "..###..".*,
            "...#...".*,
        }),
        @This().fromText(3, .{
            "....#..".*,
            "....#..".*,
            "..###..".*,
        }),
        @This().fromText(4, .{
            "..#....".*,
            "..#....".*,
            "..#....".*,
            "..#....".*,
        }),
        @This().fromText(2, .{
            "..##...".*,
            "..##...".*,
        }),
    };

    fn print(self: @This()) !void {
        var buffer = std.io.bufferedWriter(std.io.getStdOut().writer());
        var writer = buffer.writer();
        var y: u3 = 0;
        while (y < self.height) : (y += 1) {
            const row = self.rows[y];
            var mask: u7 = 1 << 6;

            while (mask != 0) : (mask >>= 1) {
                const char: u8 = if (row & mask == 0) '.' else '#';
                try writer.writeByte(char);
            }
            try writer.writeByte('\n');
        }
        try writer.writeByte('\n');
        try buffer.flush();
    }
};

const sample =
    \\>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 3068), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 1514285714288), try part2(sample));
}
