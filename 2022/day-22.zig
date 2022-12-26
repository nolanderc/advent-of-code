const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub const log_level = .info;
const visualize = true;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    const stopwatch = try util.Stopwatch.init();
    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input, 50)});
    std.debug.print("time: {}\n", .{stopwatch});
}

fn part1(input_text: []const u8) !u64 {
    const input = try parseInput(input_text);

    var row: u32 = 0;
    var col: u32 = input.grid.rows[row].first;
    var facing = Facing.right;

    for (input.instructions) |instruction| {
        switch (instruction) {
            .left => facing = facing.rotLeft(),
            .right => facing = facing.rotRight(),
            .forward => |n| {
                var steps = n;
                while (steps > 0) : (steps -= 1) {
                    switch (facing) {
                        .right => {
                            const line = input.grid.rows[row];
                            var new_col = if (col == line.last) line.first else col + 1;
                            if (line.cells[new_col - line.first] != .air) break;
                            col = new_col;
                        },
                        .left => {
                            const line = input.grid.rows[row];
                            var new_col = if (col == line.first) line.last else col - 1;
                            if (line.cells[new_col - line.first] != .air) break;
                            col = new_col;
                        },
                        .down => {
                            const line = input.grid.cols[col];
                            var new_row = if (row == line.last) line.first else row + 1;
                            if (line.cells[new_row - line.first] != .air) break;
                            row = new_row;
                        },
                        .up => {
                            const line = input.grid.cols[col];
                            var new_row = if (row == line.first) line.last else row - 1;
                            if (line.cells[new_row - line.first] != .air) break;
                            row = new_row;
                        },
                    }
                }
            },
        }
    }

    return (row + 1) * 1000 + (col + 1) * 4 + @enumToInt(facing);
}

fn part2(input_text: []const u8, comptime size: u32) !u64 {
    const input = try parseInput(input_text);

    // collect the coordinates of every cube face
    var face_coord_buffer = try std.BoundedArray([2]u3, 6).init(0);
    {
        var row: usize = 0;
        while (row < input.grid.rows.len) : (row += size) {
            var col: usize = 0;
            const line = input.grid.rows[row];
            while (col < line.last) : (col += size) {
                if (col >= line.first) {
                    try face_coord_buffer.append(.{
                        @intCast(u3, col / size),
                        @intCast(u3, row / size),
                    });
                }
            }
        }
    }

    const faces = face_coord_buffer.slice()[0..6].*;

    // for each face, the faces adjacent on each of its edges (in the same order as `Facing`)
    var adjacent: [6][4]?u3 = undefined;
    for (faces) |this, face| {
        const adjacency = &adjacent[face];
        std.mem.set(?u3, adjacency, null);
        for (faces) |other, other_index_size| {
            const other_index = @intCast(u3, other_index_size);

            const dx = @as(i8, other[0]) - this[0];
            const dy = @as(i8, other[1]) - this[1];
            if (dy == 0) {
                if (dx == -1) adjacency[@enumToInt(Facing.left)] = other_index;
                if (dx == 1) adjacency[@enumToInt(Facing.right)] = other_index;
            }
            if (dx == 0) {
                if (dy == -1) adjacency[@enumToInt(Facing.up)] = other_index;
                if (dy == 1) adjacency[@enumToInt(Facing.down)] = other_index;
            }
        }
    }

    var oriented = [1]?OrientedFace{null} ** 6;

    // keep track of all faces which have been locked in
    var locked = try std.BoundedArray(u3, 6).init(0);

    // lock the first face as the front face, and determine the rest from this
    oriented[0] = .{ .side = .front, .up = .up };
    try locked.append(0);

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        if (i >= locked.len) std.debug.panic("could not lock in all faces", .{});
        const curr = locked.buffer[i];
        for (adjacent[curr]) |other, edge| {
            if (other == null or oriented[other.?] != null) continue;
            oriented[other.?] = oriented[curr].?.fromAdjacent(@intToEnum(Facing, edge));
            try locked.append(other.?);
        }
    }

    const Wrapping = struct {
        face: u3,
        up: Facing,
    };

    // for each side of the cube, the face and its orientation
    var sides: [6]Wrapping = undefined;
    for (oriented) |orientation, face| {
        sides[@enumToInt(orientation.?.side)] = .{
            .face = @intCast(u3, face),
            .up = orientation.?.up,
        };
    }

    // for each face: the new face and orientation
    var wrapping: [6][4]Wrapping = undefined;
    std.mem.set([4]Wrapping, &wrapping, [1]Wrapping{.{ .face = 0, .up = .up }} ** 4);
    for (sides) |side, index| {
        const adjacent_sides: [4]CubeFace = switch (@intToEnum(CubeFace, index)) {
            .front => .{ .right, .bottom, .left, .top },
            .back => .{ .left, .bottom, .right, .top },
            .left => .{ .front, .bottom, .back, .top },
            .right => .{ .back, .bottom, .front, .top },
            .top => .{ .right, .front, .left, .back },
            .bottom => .{ .right, .back, .left, .front },
        };

        for (adjacent_sides) |adjacent_side, edge_index| {
            wrapping[side.face][edge_index] = sides[@enumToInt(adjacent_side)];
        }
    }

    var row: u32 = 0;
    var col: u32 = input.grid.rows[row].first;
    var facing = Facing.right;

    for (input.instructions) |instruction| {
        switch (instruction) {
            .left => facing = facing.rotLeft(),
            .right => facing = facing.rotRight(),
            .forward => |n| {
                var steps = n;
                while (steps > 0) : (steps -= 1) {
                    const face_coord = [2]u3{
                        @intCast(u3, col / size),
                        @intCast(u3, row / size),
                    };

                    const delta: [2]i2 = switch (facing) {
                        .right => .{ 1, 0 },
                        .left => .{ -1, 0 },
                        .down => .{ 0, 1 },
                        .up => .{ 0, -1 },
                    };

                    const wrap_edge: ?Facing = if (delta[0] != 0) blk: {
                        const first = face_coord[0] * size;
                        const last = first + size - 1;
                        break :blk if (delta[0] < 0 and col == first)
                            .left
                        else if (delta[0] > 0 and col == last)
                            .right
                        else
                            null;
                    } else blk: {
                        const first = face_coord[1] * size;
                        const last = first + size - 1;
                        break :blk if (delta[1] < 0 and row == first)
                            .up
                        else if (delta[1] > 0 and row == last)
                            .down
                        else
                            null;
                    };

                    var new_col: u32 = undefined;
                    var new_row: u32 = undefined;
                    var new_facing: Facing = undefined;
                    if (wrap_edge) |edge| {
                        const face = for (faces) |coord, index| {
                            if (std.mem.eql(u3, &coord, &face_coord)) break index;
                        } else std.debug.panic("no face with coords: {any}", .{face_coord});

                        const old_up = oriented[face].?.up;
                        const wrap = wrapping[face][@enumToInt(edge.rotateUp(old_up))];
                        const new_up = oriented[wrap.face].?.up;

                        const old_side = oriented[face].?.side;
                        const enter_facing = old_side.enterFacing(edge.rotateUp(old_up));
                        new_facing = enter_facing.rotate(Facing.up, new_up);

                        const relative_pos = switch (edge) {
                            .right => row % size,
                            .down => size - 1 - col % size,
                            .left => size - 1 - row % size,
                            .up => col % size,
                        };

                        const relative_delta: [2]u32 = switch (new_facing) {
                            .right => .{ 0, relative_pos },
                            .down => .{ size - 1 - relative_pos, 0 },
                            .left => .{ size - 1, size - 1 - relative_pos },
                            .up => .{ relative_pos, size - 1 },
                        };

                        const new_coord = faces[wrap.face];
                        new_col = new_coord[0] * size + relative_delta[0];
                        new_row = new_coord[1] * size + relative_delta[1];
                    } else {
                        new_col = @intCast(u32, @intCast(i32, col) + delta[0]);
                        new_row = @intCast(u32, @intCast(i32, row) + delta[1]);
                        new_facing = facing;
                    }

                    const line = input.grid.rows[new_row];
                    if (line.cells[new_col - line.first] == .wall) break;

                    if (visualize) {
                        line.cells[new_col - line.first] = switch (new_facing) {
                            .right => .right,
                            .down => .down,
                            .left => .left,
                            .up => .up,
                        };
                        {
                            const old_line = input.grid.rows[row];
                            old_line.cells[col - old_line.first] = switch (facing) {
                                .right => .right,
                                .down => .down,
                                .left => .left,
                                .up => .up,
                            };
                        }
                    }

                    col = new_col;
                    row = new_row;
                    facing = new_facing;
                }
            },
        }
    }

    try input.grid.debug();

    return (row + 1) * 1000 + (col + 1) * 4 + @enumToInt(facing);
}

const OrientedFace = struct {
    // side of the cube the face is on
    side: CubeFace,

    // which of the face's edges logically points "up" (for the bottom-face,
    // "up" is defined as toward the front-face, and for the top-face it is
    // defined as toward the back-face).
    up: Facing,

    fn fromAdjacent(self: @This(), physical_edge: Facing) OrientedFace {
        const logical_edge = physical_edge.rotateUp(self.up);
        return switch (self.side) {
            .front => switch (logical_edge) {
                .right => .{ .side = .right, .up = self.up },
                .left => .{ .side = .left, .up = self.up },
                .up => .{ .side = .top, .up = self.up },
                .down => .{ .side = .bottom, .up = self.up },
            },
            .back => switch (logical_edge) {
                .right => .{ .side = .left, .up = self.up },
                .left => .{ .side = .right, .up = self.up },
                .up => .{ .side = .top, .up = self.up.opposite() },
                .down => .{ .side = .bottom, .up = self.up.opposite() },
            },
            .left => switch (logical_edge) {
                .right => .{ .side = .back, .up = self.up },
                .left => .{ .side = .front, .up = self.up },
                .up => .{ .side = .top, .up = self.up.rotateUp(.right) },
                .down => .{ .side = .bottom, .up = self.up.rotateUp(.left) },
            },
            .right => switch (logical_edge) {
                .right => .{ .side = .front, .up = self.up },
                .left => .{ .side = .back, .up = self.up },
                .up => .{ .side = .top, .up = self.up.rotateUp(.left) },
                .down => .{ .side = .bottom, .up = self.up.rotateUp(.right) },
            },
            .top => switch (logical_edge) {
                .right => .{ .side = .right, .up = physical_edge.opposite() },
                .left => .{ .side = .left, .up = physical_edge.opposite() },
                .up => .{ .side = .back, .up = physical_edge.opposite() },
                .down => .{ .side = .front, .up = physical_edge.opposite() },
            },
            .bottom => switch (logical_edge) {
                .right => .{ .side = .right, .up = physical_edge },
                .left => .{ .side = .left, .up = physical_edge },
                .up => .{ .side = .front, .up = physical_edge },
                .down => .{ .side = .back, .up = physical_edge },
            },
        };
    }
};

const CubeFace = enum(u3) {
    front = 0,
    back = 1,
    left = 2,
    right = 3,
    top = 4,
    bottom = 5,

    fn enterFacing(from: @This(), direction: Facing) Facing {
        return switch (from) {
            .front => direction,
            .back => switch (direction) {
                .up => .down,
                .down => .up,
                else => direction,
            },
            .left => switch (direction) {
                .up => .right,
                .down => .right,
                else => direction,
            },
            .right => switch (direction) {
                .up => .left,
                .down => .left,
                else => direction,
            },
            .top => .down,
            .bottom => .up,
        };
    }
};

const Facing = enum(u2) {
    right = 0,
    down = 1,
    left = 2,
    up = 3,

    fn rotLeft(self: @This()) @This() {
        return @intToEnum(@This(), @enumToInt(self) -% 1);
    }

    fn rotRight(self: @This()) @This() {
        return @intToEnum(@This(), @enumToInt(self) +% 1);
    }

    fn opposite(self: @This()) @This() {
        return @intToEnum(@This(), @enumToInt(self) +% 2);
    }

    fn rotateUp(self: @This(), up: @This()) @This() {
        return @intToEnum(
            Facing,
            @enumToInt(self) -% @enumToInt(up) +% @enumToInt(Facing.up),
        );
    }

    fn rotate(self: @This(), old_up: @This(), new_up: @This()) @This() {
        return @intToEnum(
            Facing,
            @enumToInt(self) -% @enumToInt(old_up) +% @enumToInt(new_up),
        );
    }
};

const Cell = enum(u8) {
    air = '.',
    wall = '#',
    right = '>',
    down = 'v',
    left = '<',
    up = '^',
};

const Grid = struct {
    const Line = struct {
        first: u32,
        last: u32,
        cells: []Cell,
    };

    rows: []Line,
    cols: []Line,

    fn debug(self: @This()) !void {
        var buffered = std.io.bufferedWriter(std.io.getStdErr().writer());
        var writer = buffered.writer();

        try writer.writeAll("+");
        try writer.writeByteNTimes('-', self.cols.len);
        try writer.writeAll("+\n");

        for (self.rows) |row| {
            try writer.writeAll("|");
            try writer.writeByteNTimes(' ', row.first);
            try writer.writeAll(@ptrCast([]const u8, row.cells));
            try writer.writeByteNTimes(' ', self.cols.len - row.last - 1);
            try writer.writeAll("|\n");
        }

        try writer.writeAll("+");
        try writer.writeByteNTimes('-', self.cols.len);
        try writer.writeAll("+\n");

        try buffered.flush();
    }
};

const Instruction = union(enum) {
    left: void,
    right: void,
    forward: u8,
};

const Input = struct {
    grid: Grid,
    instructions: []Instruction,
};

fn parseInput(text: []const u8) !Input {
    var split_lines = std.mem.split(u8, text, "\n");
    var lines_list = std.ArrayList([]const u8).init(alloc);

    var height: usize = 0;
    var width: usize = 0;

    while (split_lines.next()) |line| {
        if (std.mem.trim(u8, line, &std.ascii.whitespace).len == 0) break;
        try lines_list.append(line);
        height += 1;
        width = @max(width, line.len);
    }
    const lines = lines_list.toOwnedSlice();

    var rows = std.ArrayList(Grid.Line).init(alloc);
    var cols = std.ArrayList(Grid.Line).init(alloc);

    var cells = std.ArrayList(Cell).init(alloc);

    {
        var row: u32 = 0;
        while (row < height) : (row += 1) {
            var first: ?u32 = null;
            try cells.ensureTotalCapacity(width);

            var col: u32 = 0;
            while (col < width) : (col += 1) {
                const ch = if (col < lines[row].len) lines[row][col] else ' ';
                if (ch == ' ') continue;
                if (first == null) first = col;
                try cells.append(if (ch == '#') .wall else .air);
            }

            try rows.append(.{
                .first = first.?,
                .last = first.? + @intCast(u32, cells.items.len - 1),
                .cells = cells.toOwnedSlice(),
            });
        }
    }

    {
        var col: u32 = 0;
        while (col < width) : (col += 1) {
            var first: ?u32 = null;
            try cells.ensureTotalCapacity(height);

            var row: u32 = 0;
            while (row < height) : (row += 1) {
                const ch = if (col < lines[row].len) lines[row][col] else ' ';
                if (ch == ' ') continue;
                if (first == null) first = row;
                try cells.append(if (ch == '#') .wall else .air);
            }

            try cols.append(.{
                .first = first.?,
                .last = first.? + @intCast(u32, cells.items.len - 1),
                .cells = cells.toOwnedSlice(),
            });
        }
    }

    var instr = split_lines.next() orelse std.debug.panic("missing instructions", .{});
    var instructions = std.ArrayList(Instruction).init(alloc);
    while (instr.len > 0) {
        if (instr[0] == 'L') {
            try instructions.append(.left);
            instr = instr[1..];
            continue;
        }
        if (instr[0] == 'R') {
            try instructions.append(.right);
            instr = instr[1..];
            continue;
        }

        var i: usize = 0;
        while (i < instr.len and std.ascii.isDigit(instr[i])) : (i += 1) {}

        const amount = util.parseInt(u8, instr[0..i], 10);
        try instructions.append(.{ .forward = amount });
        instr = instr[i..];
    }

    return .{
        .grid = .{
            .rows = rows.toOwnedSlice(),
            .cols = cols.toOwnedSlice(),
        },
        .instructions = instructions.toOwnedSlice(),
    };
}

const sample =
    \\        ...#
    \\        .#..
    \\        #...
    \\        ....
    \\...#.......#
    \\........#...
    \\..#....#....
    \\..........#.
    \\        ...#....
    \\        .....#..
    \\        .#......
    \\        ......#.
    \\
    \\10R5L5R10L4R5L5
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 6032), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 5031), try part2(sample, 4));
}
