const std = @import("std");
const Allocator = std.mem.Allocator;
pub const parse = @import("parse.zig");

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const global_allocator: Allocator = gpa.allocator();

pub const Config = struct {
    problem: Problem,
    input: type,
    format: InputFormat,

    pub fn run(comptime config: Config, comptime solution: anytype) SolutionOutput(solution) {
        std.log.info("{s}", .{config.problem.url()});
        const input = try getInput(global_allocator, config.problem);
        defer global_allocator.free(input);
        return runWithRawInput(config, solution, input);
    }

    pub fn runWithRawInput(comptime config: Config, comptime solution: anytype, raw_input: []const u8) SolutionOutput(solution) {
        const input = try config.format.parseInput(config.input, global_allocator, raw_input);
        return solution(input);
    }
};

const Problem = struct {
    year: u32,
    day: u32,

    fn url(comptime self: @This()) []const u8 {
        return std.fmt.comptimePrint("https://adventofcode.com/{}/day/{}", .{ self.year, self.day });
    }

    fn inputUrl(comptime self: @This()) []const u8 {
        return std.fmt.comptimePrint("https://adventofcode.com/{}/day/{}/input", .{ self.year, self.day });
    }

    fn cachedFileName(comptime self: @This()) []const u8 {
        return std.fmt.comptimePrint("aoc-{}-{}.in", .{ self.year, self.day });
    }

    fn cachedPath(comptime self: @This()) []const u8 {
        return "cached-inputs/" ++ self.cachedFileName();
    }
};

pub const InputFormat = union(enum) {
    pattern: []const u8,
    custom: void,
    tokens: []const u8,
    raw: void,

    fn Output(comptime self: @This(), comptime T: type) type {
        switch (self) {
            .pattern => return []T,
            .custom => return T,
            .tokens => return []T,
            .raw => return []const u8,
        }
    }

    fn parseInput(comptime self: @This(), comptime T: type, alloc: Allocator, raw: []const u8) !self.Output(T) {
        const trimmed = std.mem.trimRight(u8, raw, &std.ascii.spaces);
        if (trimmed.len == 0) return error.EmptyInput;

        switch (self) {
            .pattern => {
                const elements = std.mem.count(u8, trimmed, "\n") + 1;
                var items = try alloc.alloc(T, elements);
                var count: usize = 0;

                var lines = std.mem.split(u8, trimmed, "\n");
                while (lines.next()) |line| {
                    items[count] = self.parsePattern(T, line) catch |err| {
                        std.log.err("failed to parse line: `{s}`", .{line});
                        return err;
                    };
                    count += 1;
                }

                return items;
            },

            .custom => if (@hasDecl(T, "parse")) {
                return T.parse(trimmed);
            } else {
                @compileError("expected type with `pub fn parse(text: []const u8) !@This()` decl");
            },

            .tokens => |delimeter| {
                var tokens = std.mem.tokenize(u8, trimmed, delimeter);

                var count: u32 = 0;
                while (tokens.next() != null) : (count += 1) {}
                tokens.reset();

                var items = try alloc.alloc(T, count);
                var i: u32 = 0;
                while (tokens.next()) |token| : (i += 1) {
                    const result = try parse.parseSingle(T, "", token);
                    items[i] = result.value;
                }

                return items;
            },

            .raw => {
                if (T != []const u8) @compileError("input type must be `[]const u8`");
                return trimmed;
            },
        }
    }

    fn parsePattern(comptime self: @This(), comptime T: type, line: []const u8) !T {
        const pattern = self.pattern;
        const PatternStruct = switch (@typeInfo(T)) {
            .Struct => T,
            else => struct { value: T },
        };
        const output = try parse.parsePattern(PatternStruct, pattern, line);
        return if (PatternStruct == T) output else output.value;
    }
};

const SolutionInfo = struct {
    input: type,
    output: type,
};

fn SolutionOutput(comptime solution: anytype) type {
    const solution_type = @TypeOf(solution);
    const solution_info = @typeInfo(solution_type);
    const solution_fn = if (comptime solution_info == .Fn) solution_info.Fn else @compileError(std.fmt.comptimePrint("expected a function, found {}", .{solution_type}));

    switch (@typeInfo(solution_fn.return_type.?)) {
        .ErrorUnion => |err| return anyerror!err.payload,
        else => return anyerror!(solution_fn.return_type.?),
    }
}

fn getInput(alloc: Allocator, comptime problem: Problem) ![]u8 {
    const path = problem.cachedPath();
    _ = alloc;
    if (std.fs.cwd().openFile(path, .{})) |file| {
        return file.readToEndAlloc(alloc, 1 << 20);
    } else |open_error| {
        switch (open_error) {
            error.FileNotFound => {
                const input = try fetchInput(alloc, problem);
                cacheInput(problem, input) catch {};
                return input;
            },
            else => return open_error,
        }
    }
}

fn cacheInput(comptime problem: Problem, bytes: []const u8) !void {
    const path = problem.cachedPath();

    const cwd = std.fs.cwd();

    if (std.fs.path.dirname(path)) |dirname| {
        cwd.makePath(dirname) catch |err| {
            std.log.warn("failed to create directory `{s}`: {s}", .{ dirname, @errorName(err) });
            return err;
        };
    }

    cwd.writeFile(path, bytes) catch |err| {
        std.log.warn("failed to write to file `{s}`: {s}", .{ path, @errorName(err) });
        cwd.deleteFile(path) catch {};
        return err;
    };

    std.log.info("cached `{s}`", .{path});
}

fn fetchInput(alloc: Allocator, comptime problem: Problem) ![]u8 {
    const input_url = problem.inputUrl();
    std.log.info("fetching '{s}'...", .{input_url});

    const session = try getSessionKey(alloc);
    defer alloc.free(session);
    var session_cookie = try std.mem.concat(alloc, u8, &.{ "session=", session });
    defer alloc.free(session_cookie);

    const result = try std.ChildProcess.exec(.{ .allocator = alloc, .argv = &.{ "curl", input_url, "--cookie", session_cookie, "--silent", "--write-out", "%{stderr}%{http_code}%{stdout}" } });

    if (result.term == .Exited and result.term.Exited == 0) {
        if (!std.mem.eql(u8, result.stderr, "200")) {
            std.log.err("failed to fetch '{s}': `{s}`", .{ input_url, result.stdout });
            return error.AccessDenied;
        }

        return result.stdout;
    } else {
        std.log.err("failed to fetch '{s}': {s}", .{ input_url, result.stderr });
        return error.UnknownCurlError;
    }
}

fn getSessionKey(alloc: Allocator) ![]const u8 {
    const name = "AOC_SESSION_KEY";
    return std.process.getEnvVarOwned(alloc, name) catch |err| {
        std.log.err("could not get `{s}`", .{name});
        return err;
    };
}

fn formatAlloc(alloc: Allocator, comptime fmt: []const u8, args: anytype) ![]const u8 {
    const size = std.fmt.count(fmt, args);
    const buffer = try alloc.alloc(u8, size);
    var stream = std.io.fixedBufferStream(buffer);
    try std.fmt.format(stream.writer(), fmt, args);
    return buffer;
}
