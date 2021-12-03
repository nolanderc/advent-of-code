const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var alloc = &gpa.allocator;

pub fn build(b: *std.build.Builder) anyerror!void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    var test_steps = std.ArrayList(*std.build.Step).init(alloc);

    const entries = try listEntryPoints();

    for (entries) |entry| {
        const exe = b.addExecutable(entry.name, entry.path);
        exe.setTarget(target);
        exe.setBuildMode(mode);

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(format("run-{s}", .{entry.name}), format("Run the solution for {s}", .{entry.name}));
        run_step.dependOn(&run_cmd.step);

        const exe_tests = b.addTest(entry.path);
        exe_tests.setBuildMode(mode);

        const test_step = b.step(format("test-{s}", .{entry.name}), format("Run unit tests for {s}", .{entry.name}));
        test_step.dependOn(&exe_tests.step);

        try test_steps.append(test_step);
    }

    const test_all_step = b.step("test-all", "Run all unit tests for all days");
    for (test_steps.items) |step| {
        test_all_step.dependOn(&b.addLog("Running {s}: ", .{step.name}).step);
        test_all_step.dependOn(step);
    }
}

const EntryPoint = struct {
    path: []const u8,
    name: []const u8,
};

fn listEntryPoints() ![]EntryPoint {
    var entries = std.ArrayList(EntryPoint).init(alloc);

    var source_dir = try std.fs.cwd().openDir(".", .{});
    defer source_dir.close();
    var source_files = source_dir.iterate();
    while (try source_files.next()) |entry| {
        if (entry.kind != .File) continue;

        const extension = std.fs.path.extension(entry.name);
        if (!std.mem.eql(u8, extension, ".zig")) continue;

        if (std.mem.startsWith(u8, entry.name, "day-")) {
            const path = clone(u8, entry.name);
            const name = clone(u8, entry.name[0 .. entry.name.len - extension.len]);
            try entries.append(.{
                .path = path,
                .name = name,
            });
        }
    }

    std.sort.sort(EntryPoint, entries.items, {}, struct {
        fn order(_: void, a: EntryPoint, b: EntryPoint) bool {
            return std.mem.lessThan(u8, a.name, b.name);
        }
    }.order);

    return entries.toOwnedSlice();
}

fn clone(comptime T: type, old: []const T) []T {
    var new = alloc.alloc(T, old.len) catch unreachable;
    std.mem.copy(T, new, old);
    return new;
}

fn format(comptime fmt: []const u8, args: anytype) []u8 {
    const size = std.fmt.count(fmt, args);
    var buffer = alloc.alloc(u8, size) catch unreachable;
    var stream = std.io.fixedBufferStream(buffer).writer();
    std.fmt.format(stream, fmt, args) catch unreachable;
    return buffer;
}
