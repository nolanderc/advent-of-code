const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input)});
}

fn part1(text: []const u8) !u64 {
    const input = try Input.parse(text);

    const flows = input.rooms.items(.flow);
    const tunnels = input.rooms.items(.tunnels);
    const valve_masks = input.rooms.items(.valve_mask);

    var memo = std.AutoHashMap(State, u64).init(alloc);
    return maxFlow(.{
        .memo = &memo,
        .flows = flows,
        .tunnels = tunnels,
        .valve_masks = valve_masks,
    }, .{
        .room = input.starting_room,
        .time = 30,
        .valves = 0,
    });
}

const State = struct {
    room: u8,
    time: u8,
    valves: u16,
};

const RoomData = struct {
    memo: *std.AutoHashMap(State, u64),
    /// The flow in each room
    flows: []u8,
    /// The adjacent rooms
    tunnels: []std.BoundedArray(u8, 8),
    /// The index of the valve in the room
    valve_masks: []u16,
};

// Given the current room, the remaining time, and the set of opened
// valves, what is the maximum flow we could achieve?
fn maxFlow(data: RoomData, current: State) !u64 {
    if (current.time <= 1) return 0;
    if (data.memo.get(current)) |flow| return flow;

    const flow = data.flows[current.room];
    const tunnels = data.tunnels[current.room].slice();

    var if_closed: u64 = 0;
    for (tunnels) |adjacent| {
        if_closed = @max(if_closed, try maxFlow(data, .{
            .room = adjacent,
            .time = current.time - 1,
            .valves = current.valves,
        }));
    }

    var if_opened: u64 = 0;
    if (flow > 0) {
        const valve_mask = data.valve_masks[current.room];

        if ((valve_mask & current.valves) == 0) {
            if_opened = @as(u64, current.time - 1) * flow;
            if_opened += try maxFlow(data, .{
                .room = current.room,
                .time = current.time - 1,
                .valves = current.valves | valve_mask,
            });
        }
    }

    const max_flow = @max(if_closed, if_opened);
    try data.memo.putNoClobber(current, max_flow);
    return max_flow;
}

fn part2(text: []const u8) !u64 {
    const input = try Input.parse(text);

    const flows = input.rooms.items(.flow);
    const tunnels = input.rooms.items(.tunnels);
    const valve_masks = input.rooms.items(.valve_mask);

    var memo = std.AutoHashMap(State2, u64).init(alloc);
    return maxFlow2(.{
        .memo = &memo,
        .flows = flows,
        .tunnels = tunnels,
        .valve_masks = valve_masks,
    }, .{
        .turn = 0,
        .rooms = .{ input.starting_room, input.starting_room },
        .time = 26,
        .valves = 0,
    });
}

const State2 = struct {
    turn: u1,
    rooms: [2]u8,
    time: u8,
    valves: u16,
};

const RoomData2 = struct {
    memo: *std.AutoHashMap(State2, u64),
    /// The flow in each room
    flows: []u8,
    /// The adjacent rooms
    tunnels: []std.BoundedArray(u8, 8),
    /// The index of the valve in the room
    valve_masks: []u16,
};

// Given the current room, the remaining time, and the set of opened
// valves, what is the maximum flow we could achieve?
fn maxFlow2(data: RoomData2, current: State2) !u64 {
    if (data.memo.get(current)) |flow| return flow;
    if (current.time <= 1) return 0;

    const room = current.rooms[current.turn];

    const flow = data.flows[room];
    const tunnels = data.tunnels[room].slice();

    var if_closed: u64 = 0;
    for (tunnels) |adjacent| {
        var next = current;
        next.rooms[current.turn] = adjacent;
        next.turn = 1 - current.turn;
        if (next.turn == 0) next.time -= 1;
        if_closed = @max(if_closed, try maxFlow2(data, next));
    }

    var if_opened: u64 = 0;
    if (flow > 0) {
        const valve_mask = data.valve_masks[room];

        if ((valve_mask & current.valves) == 0) {
            if_opened = @as(u64, current.time - 1) * flow;

            var next = current;
            next.valves |= valve_mask;
            next.turn = 1 - current.turn;
            if (next.turn == 0) next.time -= 1;
            if_opened += try maxFlow2(data, next);
        }
    }

    const max_flow = @max(if_closed, if_opened);
    try data.memo.putNoClobber(current, max_flow);
    return max_flow;
}

const Room = struct {
    label: [2]u8,
    flow: u8,
    tunnel_labels: std.BoundedArray([2]u8, 8),
    tunnels: std.BoundedArray(u8, 8),
    valve_mask: u16,
};

const Input = struct {
    rooms: std.MultiArrayList(Room),
    starting_room: u8,

    fn parse(text: []const u8) !Input {
        var lines = std.mem.tokenize(u8, text, "\n");

        var rooms = std.MultiArrayList(Room){};
        var indices = std.AutoHashMap([2]u8, u8).init(alloc);
        var valve_count: u8 = 0;

        while (lines.next()) |line| {
            const matches = util.extractMatches("Valve % has flow rate=%; tunnel% lead% to valve% %", line) orelse {
                std.debug.panic("invalid valve: {s}", .{line});
            };

            var room = Room{
                .label = matches[0][0..2].*,
                .flow = util.parseInt(u8, matches[1], 10),
                .tunnel_labels = .{},
                .tunnels = .{},
                .valve_mask = 0,
            };

            if (room.flow > 0) {
                if (valve_count == 16) {
                    std.debug.panic("too many valves ({}) with flow > 0, maximum supported is 16", .{valve_count});
                }
                room.valve_mask = @as(u16, 1) << @intCast(u4, valve_count);
                valve_count += 1;
            }

            var tunnels = std.mem.tokenize(u8, matches[5], ", ");
            while (tunnels.next()) |tunnel| {
                try room.tunnel_labels.append(tunnel[0..2].*);
            }

            try indices.put(room.label, @intCast(u8, rooms.len));
            try rooms.append(alloc, room);
        }

        const tunnels = rooms.items(.tunnels);
        for (rooms.items(.tunnel_labels)) |labels, room_index| {
            for (labels.slice()) |label| {
                const tunnel_index = indices.get(label) orelse std.debug.panic("no room with label {s}", .{label});
                try tunnels[room_index].append(tunnel_index);
            }
        }

        std.debug.assert(indices.count() == rooms.len);

        return .{
            .rooms = rooms,
            .starting_room = indices.get("AA".*) orelse std.debug.panic("no room named AA", .{}),
        };
    }
};

const sample =
    \\Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
    \\Valve BB has flow rate=13; tunnels lead to valves CC, AA
    \\Valve CC has flow rate=2; tunnels lead to valves DD, BB
    \\Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
    \\Valve EE has flow rate=3; tunnels lead to valves FF, DD
    \\Valve FF has flow rate=0; tunnels lead to valves EE, GG
    \\Valve GG has flow rate=0; tunnels lead to valves FF, HH
    \\Valve HH has flow rate=22; tunnel leads to valve GG
    \\Valve II has flow rate=0; tunnels lead to valves AA, JJ
    \\Valve JJ has flow rate=21; tunnel leads to valve II
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 1651), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 1707), try part2(sample));
}
