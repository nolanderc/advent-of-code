const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 12,
    },
    .input = Graph,
    .format = .custom,
};

const Graph = struct {
    ids: std.StringHashMap(u8),
    names: [][]const u8,

    /// For each node, a list of outgoing edges
    edges: [][]u8,
    large: []bool,

    start: u8,
    end: u8,

    pub fn parse(text: []const u8) !@This() {
        const Edge = struct { source: u8, target: u8 };
        var ids = std.StringHashMap(u8).init(alloc);
        errdefer ids.deinit();

        var all_edges = std.ArrayList(Edge).init(alloc);
        defer all_edges.deinit();

        var lines = std.mem.split(u8, text, "\n");
        while (lines.next()) |line| {
            var tokens = std.mem.tokenize(u8, line, "-");
            const a = tokens.next() orelse return error.InvalidFormat;
            const b = tokens.next() orelse return error.InvalidFormat;

            const a_entry = try ids.getOrPut(a);
            if (!a_entry.found_existing) a_entry.value_ptr.* = @intCast(u8, ids.count() - 1);
            const a_id = a_entry.value_ptr.*;

            const b_entry = try ids.getOrPut(b);
            if (!b_entry.found_existing) b_entry.value_ptr.* = @intCast(u8, ids.count() - 1);
            const b_id = b_entry.value_ptr.*;

            try all_edges.append(.{ .source = a_id, .target = b_id });
            try all_edges.append(.{ .source = b_id, .target = a_id });
        }

        var names = try alloc.alloc([]const u8, ids.count());
        var large = try alloc.alloc(bool, ids.count());
        var name_iter = ids.iterator();
        while (name_iter.next()) |entry| {
            large[entry.value_ptr.*] = std.ascii.isUpper(entry.key_ptr.*[0]);
            names[entry.value_ptr.*] = entry.key_ptr.*;
        }

        std.sort.sort(Edge, all_edges.items, {}, struct {
            fn order(_: void, a: Edge, b: Edge) bool {
                if (a.source < b.source) return true;
                if (a.source == b.source) return a.target < b.target;
                return false;
            }
        }.order);

        var edges = try alloc.alloc([]u8, ids.count());
        var edge_targets = try alloc.alloc(u8, all_edges.items.len);
        var id: u8 = 0;
        var edge_index: u32 = 0;
        while (id < ids.count()) : (id += 1) {
            const start = edge_index;
            while (edge_index < all_edges.items.len and all_edges.items[edge_index].source == id) : (edge_index += 1) {
                edge_targets[edge_index] = all_edges.items[edge_index].target;
            }
            edges[id] = edge_targets[start..edge_index];
        }

        return Graph{
            .ids = ids,
            .names = names,
            .edges = edges,
            .large = large,
            .start = ids.get("start") orelse return error.MissingStart,
            .end = ids.get("end") orelse return error.MissingEnd,
        };
    }

    pub fn format(self: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        for (self.edges) |targets, id| {
            try writer.print("\n    {s} ->", .{self.names[id]});
            for (targets) |target| {
                try writer.print(" {s}", .{self.names[target]});
            }
        }
    }

    fn isLarge(self: *const @This(), node: u8) bool {
        return self.large[node];
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(graph: config.input) !u32 {
    var visited = try alloc.alloc(bool, graph.ids.count());
    std.mem.set(bool, visited, false);
    return countPathsSingle(&graph, graph.start, visited);
}

fn countPathsSingle(graph: *const Graph, current: u8, visited: []bool) u32 {
    if (current == graph.end) return 1;
    if (visited[current]) return 0;
    visited[current] = !graph.isLarge(current);

    var sum: u32 = 0;
    for (graph.edges[current]) |target| {
        sum += countPathsSingle(graph, target, visited);
    }

    visited[current] = false;
    return sum;
}

fn part2(graph: config.input) !u32 {
    var visited = try alloc.alloc(bool, graph.ids.count());
    std.mem.set(bool, visited, false);
    var paths = Paths.init(alloc);
    var path = std.ArrayListUnmanaged(u8){};
    try path.append(alloc, graph.start);
    try findPathsTwice(&graph, &paths, &path, visited, true);
    return @intCast(u32, paths.count());
}

const Paths = std.StringHashMap(void);

fn findPathsTwice(
    graph: *const Graph,
    paths: *Paths,
    path: *std.ArrayListUnmanaged(u8),
    visited: []bool,
    twice: bool,
) anyerror!void {
    const current = path.items[path.items.len - 1];

    if (current == graph.end) {
        const current_path = try alloc.dupe(u8, path.items);
        _ = try paths.getOrPutValue(current_path, {});
        return;
    }

    if (graph.isLarge(current)) {
        for (graph.edges[current]) |target| {
            try path.append(alloc, target);
            try findPathsTwice(graph, paths, path, visited, twice);
            _ = path.pop();
        }
    } else {
        if (visited[current]) return;

        if (twice and current != graph.start) {
            for (graph.edges[current]) |target| {
                try path.append(alloc, target);
                try findPathsTwice(graph, paths, path, visited, false);
                _ = path.pop();
            }
        }

        visited[current] = true;
        for (graph.edges[current]) |target| {
            try path.append(alloc, target);
            try findPathsTwice(graph, paths, path, visited, twice);
            _ = path.pop();
        }
        visited[current] = false;
    }
}

const small_sample =
    \\start-A
    \\start-b
    \\A-c
    \\A-b
    \\b-d
    \\A-end
    \\b-end
;

const large_sample =
    \\dc-end
    \\HN-start
    \\start-kj
    \\dc-start
    \\dc-HN
    \\LN-dc
    \\HN-end
    \\kj-sa
    \\kj-HN
    \\kj-dc
;

const huge_sample =
    \\fs-end
    \\he-DX
    \\fs-he
    \\start-DX
    \\pj-DX
    \\end-zg
    \\zg-sl
    \\zg-pj
    \\pj-he
    \\RW-he
    \\fs-DX
    \\pj-RW
    \\zg-RW
    \\start-pj
    \\he-WI
    \\zg-he
    \\pj-fs
    \\start-RW
;

test "part 1 small sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, small_sample), 10);
}

test "part 1 large sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, large_sample), 19);
}

test "part 1 huge sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, huge_sample), 226);
}

test "part 2 small sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, small_sample), 36);
}

test "part 2 large sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, large_sample), 103);
}

test "part 2 huge sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, huge_sample), 3509);
}
