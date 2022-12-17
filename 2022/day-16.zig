const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub const log_level = .info;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    const start = try std.time.Instant.now();

    std.debug.print("part1: {}\n", .{try part1(input)});
    std.debug.print("part2: {}\n", .{try part2(input)});

    const end = try std.time.Instant.now();
    var duration = @intToFloat(f64, end.since(start));
    var unit: []const u8 = "ns";

    if (duration > 1000) {
        duration /= 1000.0;
        unit = "us";
    }

    if (duration > 1000) {
        duration /= 1000.0;
        unit = "ms";
    }

    if (duration > 1000) {
        duration /= 1000.0;
        unit = "s";
    }

    std.log.info("time: {d:.3} {s}", .{ duration, unit });
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

    const WorkData = struct {
        flows: []u8,
        tunnels: []std.BoundedArray(u8, 8),
        masks: []u16,
        valve_count: usize,

        old_memo: []u16,
        new_memo: []u16,

        threads: usize,

        barrier: *Barrier,

        const Barrier = struct {
            mutex: std.Thread.Mutex = .{},
            condition: std.Thread.Condition = .{},
            num_waiting: usize = 0,
            version: u1 = 0,
        };

        fn execute(data: @This(), offset: usize, count: usize) void {
            var old_memo = data.old_memo;
            var new_memo = data.new_memo;
            const valve_count = data.valve_count;

            var time: u8 = 2;
            while (time <= 26) : (time += 1) {
                if (offset == 0) {
                    std.debug.print("\r{}%", .{100 * @as(u32, time - 2) / 24});
                }

                var turn: u8 = 0;
                while (turn < 2) : (turn += 1) {
                    // compute the new flow
                    var memo_index = offset;
                    while (memo_index < offset + count) : (memo_index += 1) {
                        // extract the parameters from the index
                        var index = memo_index;

                        const valve0 = index % valve_count;
                        index /= valve_count;

                        const valve1 = index % valve_count;
                        index /= valve_count;

                        const opened = index;

                        const valve = if (turn == 0) valve0 else valve1;
                        const flow = data.flows[valve];
                        const mask = data.masks[valve];
                        const adjacency = &data.tunnels[valve];

                        var if_closed: u16 = 0;
                        var if_opened: u16 = 0;

                        for (adjacency.slice()) |adjacent| {
                            var valves = [2]@TypeOf(valve0){ valve0, valve1 };
                            valves[turn] = adjacent;
                            const old_flow = old_memo[valves[0] + valve_count * (valves[1] + valve_count * opened)];
                            if_closed = @max(if_closed, old_flow);
                        }

                        if (flow > 0 and mask & opened == 0) {
                            if_opened += @as(u16, time - 1) * flow;
                            const old_flow = old_memo[valve0 + valve_count * (valve1 + valve_count * (opened | mask))];
                            if_opened += old_flow;
                        }

                        new_memo[memo_index] = @max(if_closed, if_opened);
                    }

                    std.mem.swap([]u16, &old_memo, &new_memo);
                    data.sync();
                }
            }

            if (offset == 0) {
                std.debug.print("\r       \r", .{});
            }
        }

        fn sync(self: @This()) void {
            self.barrier.mutex.lock();
            defer self.barrier.mutex.unlock();

            self.barrier.num_waiting += 1;
            if (self.barrier.num_waiting == self.threads) {
                self.barrier.num_waiting = 0;
                self.barrier.version ^= 1;
                self.barrier.condition.broadcast();
                return;
            }

            const version = self.barrier.version;
            while (self.barrier.version == version) {
                self.barrier.condition.wait(&self.barrier.mutex);
            }
        }
    };

    const valve_count = input.valves.len;
    const open_state_count = @as(usize, 1) << @intCast(u5, input.openable);
    const memo_size = valve_count * valve_count * open_state_count;

    var barrier = WorkData.Barrier{};
    var data = WorkData{
        .flows = input.valves.items(.flow),
        .tunnels = input.valves.items(.tunnels),
        .masks = input.valves.items(.mask),
        .valve_count = valve_count,
        .old_memo = try alloc.alloc(u16, memo_size),
        .new_memo = try alloc.alloc(u16, memo_size),
        .threads = std.Thread.getCpuCount() catch 1,
        .barrier = &barrier,
    };
    std.mem.set(u16, data.old_memo, 0);
    std.mem.set(u16, data.new_memo, 0);

    std.log.info("starting {} threads...", .{data.threads});
    var threads = std.ArrayList(std.Thread).init(alloc);
    var i: usize = 0;
    const thread_size = memo_size / data.threads;
    while (i < data.threads) : (i += 1) {
        const size = if (i < data.threads - 1) thread_size else memo_size - (data.threads - 1) * thread_size;
        const offset = i * thread_size;
        const thread = try std.Thread.spawn(.{}, WorkData.execute, .{ data, offset, size });
        try threads.append(thread);
    }

    for (threads.items) |thread| {
        thread.join();
    }

    return data.old_memo[input.starting_room + valve_count * input.starting_room];
}

const Valve = struct {
    label: [2]u8,
    flow: u8,
    tunnel_labels: std.BoundedArray([2]u8, 8),
    tunnels: std.BoundedArray(u8, 8),
    mask: u16,
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
