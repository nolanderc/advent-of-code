const std = @import("std");
const utils = @import("utils.zig");

const alloc = utils.global_allocator;

const config = utils.Config{
    .problem = .{
        .year = 2021,
        .day = 17,
    },
    .input = Area,
    .format = .custom,
};

const Area = struct {
    left: i32,
    right: i32,
    bottom: i32,
    top: i32,

    pub fn parse(text: []const u8) !Area {
        return utils.parse.parsePattern(Area, "target area: x={}..{}, y={}..{}", text);
    }
};

pub fn main() anyerror!void {
    std.log.info("part 1: {}", .{try config.run(part1)});
    std.log.info("part 2: {}", .{try config.run(part2)});
}

fn part1(target: config.input) !u64 {
    std.debug.assert(target.bottom < 0);

    // Let the velocity of the probe be `(x, y)`
    // We don't really care about x, focus on y.
    //
    // `height` is on the form: `y + (y-1) + ... + 2 + 1`
    //
    // When falling back down, and when at coordinate `(_, 0)` the probe will
    // have velocity `(_, -y)`. In the next step it will end up at `(_, -y-1)`.
    //
    // In order to maximize velocity (and thus `height`) we need to make sure
    // that `(_, -y-1)` ends up in the target area. Thus we have:
    //      -y-1 = y_min
    //        -y = y_min + 1
    //         y = -(y_min + 1)

    const y_vel = @intCast(u32, -(target.bottom + 1));
    const height = tri(y_vel);
    return height;
}

fn part2(target: config.input) !u64 {
    std.debug.assert(target.left > 0);
    std.debug.assert(target.top < 0);

    var sum: u64 = 0;

    const min_x = 1;
    const max_x = target.right;
    const min_y = target.bottom;
    const max_y = -(target.bottom + 1);

    var y = min_y;
    while (y <= max_y) : (y += 1) {
        var t_min: i32 = 0;
        var t_max: i32 = 0;

        var y_vel = y;
        var y_pos: i32 = 0;
        while (y_pos > target.top) {
            y_pos += y_vel;
            y_vel -= 1;
            t_min += 1;
        }
        t_max = t_min;
        while (y_pos >= target.bottom) {
            t_max += 1;
            y_pos += y_vel;
            y_vel -= 1;
        }

        var x: i32 = min_x;
        while (x <= max_x) : (x += 1) {
            var t: i32 = t_min;
            while (t < t_max) : (t += 1) {
                const x_pos = tri(x) - if (t < x) tri(x - t) else 0;
                if (target.left <= x_pos and x_pos <= target.right) {
                    sum += 1;
                    break;
                }
            }
        }
    }

    return sum;
}

fn tri(n: anytype) @TypeOf(n) {
    return @divExact(n * (n + 1), 2);
}

const sample = "target area: x=20..30, y=-10..-5";

test "part 1 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u64, 45), try config.runWithRawInput(part1, sample));
}

test "part 2 sample" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u64, 112), try config.runWithRawInput(part2, sample));
}
