const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub const log_level = .info;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input)});
}

fn part1(text: []const u8) !u64 {
    const input = try Input.parse(text);

    const flows = input.valves.items(.flow);
    const tunnels = input.valves.items(.tunnels);
    const masks = input.valves.items(.mask);
    const open_state_count = @as(usize, 1) << @intCast(u5, input.openable);

    const valve_count = input.valves.len;
    const memo_size = valve_count * open_state_count;
    var old_memo = try alloc.alloc(u16, memo_size);
    var new_memo = try alloc.alloc(u16, memo_size);
    std.mem.set(u16, old_memo, 0);

    var time: u8 = 2;
    while (time <= 30) : (time += 1) {
        // compute the new flow
        for (new_memo) |*new_flow, index| {
            // extract the parameters from the index
            const valve = index % valve_count;
            const opened = index / valve_count;

            const flow = flows[valve];
            const mask = masks[valve];
            const adjacency = &tunnels[valve];

            var if_closed: u16 = 0;
            var if_opened: u16 = 0;

            for (adjacency.slice()) |adjacent| {
                if_closed = @max(if_closed, old_memo[adjacent + valve_count * opened]);
            }

            if (flow > 0 and mask & opened == 0) {
                if_opened += @as(u16, time - 1) * flow;
                if_opened += old_memo[valve + valve_count * (opened | mask)];
            }

            new_flow.* = @max(if_closed, if_opened);
        }

        std.mem.swap([]u16, &old_memo, &new_memo);
    }

    return old_memo[input.starting_room];
}

fn part2(text: []const u8) !u64 {
    const input = try Input.parse(text);

    const flows = input.valves.items(.flow);
    const tunnels = input.valves.items(.tunnels);
    const masks = input.valves.items(.mask);
    const open_state_count = @as(usize, 1) << @intCast(u5, input.openable);

    const valve_count = input.valves.len;
    const memo_size = valve_count * valve_count * open_state_count;
    var old_memo = try alloc.alloc(u16, memo_size * 2);
    var new_memo = try alloc.alloc(u16, memo_size * 2);
    std.mem.set(u16, old_memo, 0);

    std.log.info("memo_size: {}\n", .{memo_size});

    var time: u8 = 2;
    while (time <= 26) : (time += 1) {
        std.debug.print("time: {}\n", .{time});

        // compute the new flow
        for (new_memo) |*new_flow, memo_index| {
            // extract the parameters from the index
            var index = memo_index;

            const valve0 = index % valve_count;
            index /= valve_count;

            const valve1 = index % valve_count;
            index /= valve_count;

            const opened = index % open_state_count;
            index /= open_state_count;

            const turn = index % 2;

            const valve = if (turn == 0) valve0 else valve1;
            const flow = flows[valve];
            const mask = masks[valve];
            const adjacency = &tunnels[valve];

            const prev_memo = if (turn == 0) old_memo[memo_size..] else new_memo[0..memo_size];

            var if_closed: u16 = 0;
            var if_opened: u16 = 0;

            for (adjacency.slice()) |adjacent| {
                var valves = [2]@TypeOf(valve0){ valve0, valve1 };
                valves[turn] = adjacent;
                const prev_flow = prev_memo[valves[0] + valve_count * (valves[1] + valve_count * opened)];
                if_closed = @max(if_closed, prev_flow);
            }

            if (flow > 0 and mask & opened == 0) {
                if_opened += @as(u16, time - 1) * flow;
                const old_flow = prev_memo[valve0 + valve_count * (valve1 + valve_count * (opened | mask))];
                if_opened += old_flow;
            }

            new_flow.* = @max(if_closed, if_opened);
        }

        std.mem.swap([]u16, &old_memo, &new_memo);
    }

    return old_memo[input.starting_room + valve_count * input.starting_room + memo_size];
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
    if (current.time <= 1) return 0;
    if (data.memo.get(current)) |flow| return flow;

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

const Valve = struct {
    label: [2]u8,
    flow: u8,
    tunnel_labels: std.BoundedArray([2]u8, 8),
    tunnels: std.BoundedArray(u8, 8),
    mask: u16,
};

const Room = struct {
    /// The amount of flow contributed by this room (never 0)
    flow: u8,
    /// For each other room, the distance to it
    distances: std.BoundedArray(u8, 16),
};

const Input = struct {
    valves: std.MultiArrayList(Valve),
    starting_room: u8,
    openable: u8,

    fn parse(text: []const u8) !Input {
        var lines = std.mem.tokenize(u8, text, "\n");

        var valves = std.MultiArrayList(Valve){};
        var indices = std.AutoHashMap([2]u8, u8).init(alloc);
        var openable: u8 = 0;

        while (lines.next()) |line| {
            const matches = util.extractMatches("Valve % has flow rate=%; tunnel% lead% to valve% %", line) orelse {
                std.debug.panic("invalid valve: {s}", .{line});
            };

            var valve = Valve{
                .label = matches[0][0..2].*,
                .flow = util.parseInt(u8, matches[1], 10),
                .tunnel_labels = .{},
                .tunnels = .{},
                .mask = 0,
            };

            if (valve.flow > 0) {
                if (openable == 16) {
                    std.debug.panic("too many valves ({}) with flow > 0, maximum supported is 16", .{openable});
                }
                valve.mask = @as(u16, 1) << @intCast(u4, openable);
                openable += 1;
            }

            var tunnels = std.mem.tokenize(u8, matches[5], ", ");
            while (tunnels.next()) |tunnel| {
                try valve.tunnel_labels.append(tunnel[0..2].*);
            }

            try indices.put(valve.label, @intCast(u8, valves.len));
            try valves.append(alloc, valve);
        }

        const tunnels = valves.items(.tunnels);
        for (valves.items(.tunnel_labels)) |labels, valve_index| {
            for (labels.slice()) |label| {
                const tunnel_index = indices.get(label) orelse std.debug.panic("no room with label {s}", .{label});
                try tunnels[valve_index].append(tunnel_index);
            }
        }

        return .{
            .valves = valves,
            .starting_room = indices.get("AA".*) orelse std.debug.panic("no room named AA", .{}),
            .openable = openable,
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
