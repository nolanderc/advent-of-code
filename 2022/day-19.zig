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
    const blueprints = try parseInput(input);
    var sum: u64 = 0;
    for (blueprints) |blueprint| {
        sum += blueprint.index * try maxGeodes(24, blueprint);
    }
    return sum;
}

fn part2(input: []const u8) !u64 {
    const blueprints = try parseInput(input);
    const not_eaten = @min(blueprints.len, 3);
    var product: u64 = 1;
    for (blueprints[0..not_eaten]) |blueprint| {
        product *= try maxGeodes(32, blueprint);
    }
    return product;
}

fn maxGeodes(comptime max_time: u32, blueprint: Blueprint) !u32 {
    const State = struct {
        materials: Materials,
        robots: Robots,
        time: u32,
    };

    const MemoTable = std.AutoHashMap(State, u32);

    const Cache = struct {
        memo: MemoTable = MemoTable.init(alloc),
        blueprint: Blueprint,
        max_materials: Materials,

        fn geodes(self: *@This(), state: State, prune: u32) !u32 {
            if (state.time == 0) return 0;
            if (self.memo.get(state)) |count| return count;

            // prune branches if we have stashed excess materials (which means
            // we probably built too many robots of some type).
            inline for (comptime std.meta.fieldNames(Materials)) |field| {
                if (@field(state.materials, field) > 5 * @field(self.max_materials, field)) {
                    return 0;
                }
            }

            var max: u32 = 0;
            var could_afford_all: bool = true;

            inline for (std.meta.fields(Blueprint)) |field| {
                if (field.field_type == Materials) {
                    const name = field.name;

                    // if we have more robots than we will ever need in a
                    // single timestep of the correspopnding resource, we don't
                    // need to produce any more of them.
                    const has_enough = @hasField(Materials, name) and
                        @field(state.robots, name) >= @field(self.max_materials, name);

                    if (!has_enough) {
                        if (state.materials.sub(@field(self.blueprint, name))) |materials| {
                            var next = state;
                            next.materials = materials.add(next.robots);
                            @field(next.robots, name) += 1;
                            next.time -= 1;
                            max = @max(max, try self.geodes(next, max));
                        } else {
                            could_afford_all = false;
                        }
                    }
                }
            }

            // it is always better to build a robot, so if we could in all
            // cases, don't bother saving resources for the future.
            if (!could_afford_all) {
                var next = state;
                next.time -= 1;
                next.materials = next.materials.add(next.robots);
                max = @max(max, try self.geodes(next, max));
            }

            max += state.robots.geode;

            try self.memo.put(state, max);
            return max;
        }
    };

    var max_materials = Materials{
        .ore = 0,
        .clay = 0,
        .obsidian = 0,
    };

    inline for (std.meta.fields(Blueprint)) |field| {
        if (field.field_type == Materials) {
            const name = field.name;
            max_materials = max_materials.max(@field(blueprint, name));
        }
    }

    var cache = Cache{
        .blueprint = blueprint,
        .max_materials = max_materials,
    };

    return cache.geodes(.{
        .materials = .{},
        .robots = .{},
        .time = max_time,
    }, 0);
}

const Robots = struct {
    ore: u8 = 1,
    clay: u8 = 0,
    obsidian: u8 = 0,
    geode: u8 = 0,
};

const Materials = struct {
    ore: u8 = 0,
    clay: u8 = 0,
    obsidian: u8 = 0,

    fn contains(self: @This(), other: @This()) bool {
        return other.ore <= self.ore and other.clay <= self.clay and other.obsidian <= self.obsidian;
    }

    fn sub(self: @This(), other: @This()) ?@This() {
        if (!self.contains(other)) return null;
        return .{
            .ore = self.ore - other.ore,
            .clay = self.clay - other.clay,
            .obsidian = self.obsidian - other.obsidian,
        };
    }

    fn add(self: @This(), robots: Robots) @This() {
        return .{
            .ore = self.ore + robots.ore,
            .clay = self.clay + robots.clay,
            .obsidian = self.obsidian + robots.obsidian,
        };
    }

    fn max(self: @This(), other: @This()) @This() {
        return .{
            .ore = @max(self.ore, other.ore),
            .clay = @max(self.clay, other.clay),
            .obsidian = @max(self.obsidian, other.obsidian),
        };
    }
};

const Blueprint = struct {
    index: u32,
    ore: Materials,
    clay: Materials,
    obsidian: Materials,
    geode: Materials,
};

fn parseInput(text: []const u8) ![]Blueprint {
    const pattern = "Blueprint %: Each ore robot costs % ore. Each clay robot costs % ore. Each obsidian robot costs % ore and % clay. Each geode robot costs % ore and % obsidian.";
    var lines = std.mem.split(u8, std.mem.trim(u8, text, &std.ascii.whitespace), "\n");
    var blueprints = std.ArrayList(Blueprint).init(alloc);

    while (lines.next()) |line| {
        const matches = util.extractMatches(pattern, line) orelse {
            std.debug.panic("invalid blueprint: {s}", .{line});
        };
        try blueprints.append(.{
            .index = util.parseInt(u8, matches[0], 10),
            .ore = .{ .ore = util.parseInt(u8, matches[1], 10) },
            .clay = .{ .ore = util.parseInt(u8, matches[2], 10) },
            .obsidian = .{
                .ore = util.parseInt(u8, matches[3], 10),
                .clay = util.parseInt(u8, matches[4], 10),
            },
            .geode = .{
                .ore = util.parseInt(u8, matches[5], 10),
                .obsidian = util.parseInt(u8, matches[6], 10),
            },
        });
    }

    return blueprints.toOwnedSlice();
}

const sample =
    \\Blueprint 1: Each ore robot costs 4 ore. Each clay robot costs 2 ore. Each obsidian robot costs 3 ore and 14 clay. Each geode robot costs 2 ore and 7 obsidian.
    \\Blueprint 2: Each ore robot costs 2 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 8 clay. Each geode robot costs 3 ore and 12 obsidian.
;

test "part1" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 33), try part1(sample));
}

test "part2" {
    std.testing.log_level = .info;
    try std.testing.expectEqual(@as(u64, 56 * 62), try part2(sample));
}
