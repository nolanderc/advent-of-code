const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2018,
        .day = 4,
    },
    .input = Log,
    .format = .{ .pattern = "[{}] {}" },
};

const Log = struct {
    timestamp: TimeStamp,
    event: Event,

    const TimeStamp = packed struct {
        year: u12,
        month: u4,
        day: u5,
        hour: u5,
        minute: u6,

        pub fn parse(comptime specifier: []const u8, text: []const u8) !TimeStamp {
            _ = specifier;
            return utils.parse.parsePattern(TimeStamp, "{}-{}-{} {}:{}", text);
        }

        pub fn order(a: TimeStamp, b: TimeStamp) std.math.Order {
            const fields = .{ "year", "month", "day", "hour", "minute" };
            inline for (fields) |field| {
                const ord = std.math.order(@field(a, field), @field(b, field));
                if (ord != .eq) return ord;
            }
            return .eq;
        }

        pub fn format(self: TimeStamp, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            try writer.print("{:4}-{:0>2}-{:0>2} {:0>2}:{:0>2}", .{ self.year, self.month, self.day, self.hour, self.minute });
        }

        pub fn minutesSince(later: TimeStamp, earlier: TimeStamp) u32 {
            // cheat because we are doing AOC:
            return (60 + @as(u32, later.minute) - @as(u32, earlier.minute)) % 60;
        }
    };

    const Event = union(enum) {
        begin: u16,
        sleep: void,
        wake: void,

        pub fn parse(comptime specifier: []const u8, text: []const u8) !Event {
            _ = specifier;
            if (std.mem.startsWith(u8, text, "Guard")) {
                const id = try utils.parse.parsePattern(u16, "Guard #{} begins shift", text);
                return Event{ .begin = id };
            }
            if (std.mem.startsWith(u8, text, "falls asleep")) {
                return .sleep;
            }
            if (std.mem.startsWith(u8, text, "wakes up")) {
                return .wake;
            }
            return error.InvalidEvent;
        }
    };
};

pub fn main() !void {
    std.log.info("part 1: {}", .{config.run(part1)});
    std.log.info("part 2: {}", .{config.run(part2)});
}

fn part1(logs: []Log) !u32 {
    const guards = try collectGuardInfo(logs);

    var best_guard: u16 = 0;
    var max_sleeping: u32 = 0;
    var guard_iter = guards.iterator();
    while (guard_iter.next()) |guard| {
        if (guard.value_ptr.minutes_sleeping >= max_sleeping) {
            max_sleeping = guard.value_ptr.minutes_sleeping;
            best_guard = guard.key_ptr.*;
        }
    }

    const info = guards.get(best_guard) orelse return error.NoBestGuard;

    var best_minute: u32 = 0;
    for (info.minutes) |count, minute| {
        if (count > info.minutes[best_minute]) {
            best_minute = @truncate(u32, minute);
        }
    }

    return best_guard * best_minute;
}

fn part2(logs: []config.input) !u32 {
    const guards = try collectGuardInfo(logs);

    var best_guard: u16 = 0;
    var max_sleeping: u32 = 0;
    var best_minute: u32 = 0;

    var guard_iter = guards.iterator();
    while (guard_iter.next()) |guard| {
        const info = guard.value_ptr;

        var guard_best_minute: u32 = 0;
        for (info.minutes) |count, minute| {
            if (count > info.minutes[guard_best_minute]) {
                guard_best_minute = @truncate(u32, minute);
            }
        }

        if (info.minutes[guard_best_minute] >= max_sleeping) {
            best_guard = guard.key_ptr.*;
            best_minute = guard_best_minute;
            max_sleeping = info.minutes[guard_best_minute];
        }
    }

    return best_guard * best_minute;
}

const GuardInfo = struct {
    minutes_sleeping: u32 = 0,
    minutes: [60]u32 = [_]u32{0} ** 60,
};

fn collectGuardInfo(logs: []Log) !std.AutoHashMap(u16, GuardInfo) {
    std.sort.sort(Log, logs, {}, struct {
        fn order(_: void, a: Log, b: Log) bool {
            return a.timestamp.order(b.timestamp) == .lt;
        }
    }.order);

    var guards = std.AutoHashMap(u16, GuardInfo).init(alloc);
    var last_time: Log.TimeStamp = undefined;
    var current_guard: u16 = 0;
    var state: enum { sleeping, awake } = .awake;

    for (logs) |log| {
        switch (log.event) {
            .begin => |guard| current_guard = guard,
            .sleep => state = .sleeping,
            .wake => {
                const entry = try guards.getOrPut(current_guard);
                if (!entry.found_existing) entry.value_ptr.* = .{};

                const minutes = log.timestamp.minutesSince(last_time);
                entry.value_ptr.minutes_sleeping += minutes;

                var i: u32 = 0;
                while (i < minutes) : (i += 1) {
                    const minute = (@as(u32, last_time.minute) + i) % 60;
                    entry.value_ptr.minutes[minute] += 1;
                }

                state = .awake;
            },
        }

        last_time = log.timestamp;
    }

    return guards;
}

const sample =
    \\[1518-11-01 00:00] Guard #10 begins shift
    \\[1518-11-01 00:05] falls asleep
    \\[1518-11-01 00:25] wakes up
    \\[1518-11-01 00:30] falls asleep
    \\[1518-11-01 00:55] wakes up
    \\[1518-11-01 23:58] Guard #99 begins shift
    \\[1518-11-02 00:40] falls asleep
    \\[1518-11-02 00:50] wakes up
    \\[1518-11-03 00:05] Guard #10 begins shift
    \\[1518-11-03 00:24] falls asleep
    \\[1518-11-03 00:29] wakes up
    \\[1518-11-04 00:02] Guard #99 begins shift
    \\[1518-11-04 00:36] falls asleep
    \\[1518-11-04 00:46] wakes up
    \\[1518-11-05 00:03] Guard #99 begins shift
    \\[1518-11-05 00:45] falls asleep
    \\[1518-11-05 00:55] wakes up
;

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part1, sample), 240);
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(try config.runWithRawInput(part2, sample), 4455);
}
