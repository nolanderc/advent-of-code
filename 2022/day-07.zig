const std = @import("std");
const util = @import("util.zig");
const alloc = util.alloc;

pub fn main() !void {
    const input = try util.loadInput(util.inputPath(@src().file));
    std.log.info("part1: {}", .{try part1(input)});
    std.log.info("part2: {}", .{try part2(input)});
}

fn part1(input_text: []const u8) !u64 {
    const input = try parseInput(input_text);
    var nodes = try createNodeTree(input.commands);

    var sizes = std.StringHashMap(u64).init(alloc);
    _ = try computeSize(&nodes, &sizes, "/");

    var sum: u64 = 0;

    var size_iterator = sizes.iterator();
    while (size_iterator.next()) |size_entry| {
        const size = size_entry.value_ptr.*;
        if (size <= 100000) {
            if (nodes.get(size_entry.key_ptr.*)) |node| {
                if (node == .directory) {
                    sum += size;
                }
            }
        }
    }

    return sum;
}

fn part2(input_text: []const u8) !u64 {
    const input = try parseInput(input_text);
    var nodes = try createNodeTree(input.commands);

    var sizes = std.StringHashMap(u64).init(alloc);
    const root_size = try computeSize(&nodes, &sizes, "/");

    const total_space = 70000000;
    const required_space = 30000000;
    const unused_space = total_space - root_size;
    const additional_space = required_space - unused_space;

    var best = root_size;

    var size_iterator = sizes.iterator();
    while (size_iterator.next()) |size_entry| {
        const size = size_entry.value_ptr.*;
        if (size >= additional_space) {
            if (nodes.get(size_entry.key_ptr.*)) |node| {
                if (node == .directory) {
                    best = @min(best, size);
                }
            }
        }
    }

    return best;
}

const Node = union(enum) {
    directory: std.ArrayListUnmanaged([]const u8),
    file: u64,
};

fn computeSize(nodes: *const std.StringHashMap(Node), sizes: *std.StringHashMap(u64), path: []const u8) !u64 {
    const size = switch (nodes.get(path) orelse return 0) {
        .file => |size| size,
        .directory => |children| blk: {
            var size: u64 = 0;
            for (children.items) |child| {
                size += try computeSize(nodes, sizes, child);
            }
            break :blk size;
        },
    };

    try sizes.put(path, size);
    return size;
}

fn createNodeTree(commands: []Command) !std.StringHashMap(Node) {
    var current_path = std.ArrayList(u8).init(alloc);
    var nodes = std.StringHashMap(Node).init(alloc);

    for (commands) |command| {
        switch (command) {
            .cd => |target| {
                switch (target) {
                    .root => {
                        current_path.clearRetainingCapacity();
                        try current_path.append('/');
                    },
                    .parent => {
                        const last = std.mem.lastIndexOfScalar(u8, current_path.items[0 .. current_path.items.len - 1], '/') orelse 0;
                        try current_path.resize(last + 1);
                    },
                    .child => |child| {
                        try current_path.appendSlice(child);
                        try current_path.append('/');
                    },
                }

                const dir_entry = try nodes.getOrPut(current_path.items);
                if (!dir_entry.found_existing) {
                    dir_entry.key_ptr.* = try alloc.dupe(u8, current_path.items);
                    dir_entry.value_ptr.* = Node{ .directory = .{} };
                }
            },
            .ls => |entries| {
                const old_len = current_path.items.len;
                for (entries) |entry| {
                    try current_path.appendSlice(entry.name);
                    if (entry.size) |size| {
                        const node_entry = try nodes.getOrPut(current_path.items);
                        if (!node_entry.found_existing) {
                            node_entry.key_ptr.* = try alloc.dupe(u8, current_path.items);
                            node_entry.value_ptr.* = Node{ .file = size };
                        }
                    } else {
                        try current_path.append('/');
                    }

                    var parent_node = nodes.getPtr(current_path.items[0..old_len]).?;
                    try parent_node.directory.append(alloc, try alloc.dupe(u8, current_path.items));

                    // restore the old path
                    try current_path.resize(old_len);
                }
            },
        }
    }

    return nodes;
}

const Input = struct {
    commands: []Command,
};

const Command = union(enum) {
    cd: Directory,
    ls: []DirEntry,
};

const DirEntry = struct {
    name: []const u8,
    size: ?u64 = null,
};

const Directory = union(enum) {
    root: void,
    parent: void,
    child: []const u8,

    fn parse(text: []const u8) !@This() {
        if (std.mem.eql(u8, text, "/")) return .root;
        if (std.mem.eql(u8, text, "..")) return .parent;
        return .{ .child = text };
    }
};

fn parseInput(input: []const u8) !Input {
    var words = std.mem.tokenize(u8, input, &std.ascii.whitespace);
    var commands = std.ArrayList(Command).init(alloc);

    while (words.next()) |kind| {
        _ = try expect("$", kind);
        const command = try expectSome(words.next());

        if (std.mem.eql(u8, command, "cd")) {
            const directory = try Directory.parse(try expectSome(words.next()));
            try commands.append(.{ .cd = directory });
            continue;
        }

        if (std.mem.eql(u8, command, "ls")) {
            const entries = try parseDirEntries(&words);
            try commands.append(.{ .ls = entries });
            continue;
        }

        std.log.err("unknown command `{s}`", .{command});
        return error.UnknownCommand;
    }

    return .{
        .commands = commands.toOwnedSlice(),
    };
}

fn parseDirEntries(words: *std.mem.TokenIterator(u8)) ![]DirEntry {
    var entries = std.ArrayList(DirEntry).init(alloc);
    while (words.peek()) |next| {
        if (std.mem.eql(u8, next, "$")) break;
        const kind = words.next() orelse unreachable;

        if (std.mem.eql(u8, kind, "dir")) {
            const name = try expectSome(words.next());
            try entries.append(.{ .name = name });
            continue;
        }

        const size = util.parseInt(u64, kind, 10);
        const name = try expectSome(words.next());
        try entries.append(.{ .name = name, .size = size });
    }
    return entries.toOwnedSlice();
}

fn expectSome(found: ?[]const u8) ![]const u8 {
    if (found) |found_text| return found_text;
    std.log.err("unexpected end of input", .{});
    return error.UnexpectedEndOfInput;
}

fn expect(expected: []const u8, found: ?[]const u8) ![]const u8 {
    const found_text = found orelse "";

    if (!std.mem.eql(u8, found_text, expected)) {
        std.log.err("expected `{s}` but found `{s}`", .{ expected, found_text });
        return error.UnexpectedInput;
    }

    return found_text;
}

const sample =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 95437), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 24933642), try part2(sample));
}
