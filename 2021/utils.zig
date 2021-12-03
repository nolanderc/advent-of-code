const std = @import("std");
const Allocator = std.mem.Allocator;
const parse = @import("parse.zig");

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const global_allocator = &gpa.allocator;

pub const Config = struct {
    problem: Problem,
    input: type,
    format: InputFormat,

    pub fn run(comptime config: Config, comptime solution: anytype) solutionOutput(solution) {
        std.log.info("{s}", .{config.problem.url()});
        const input = try getInput(global_allocator, config.problem);
        defer global_allocator.free(input);
        return runWithRawInput(config, solution, input);
    }

    pub fn runWithRawInput(comptime config: Config, comptime solution: anytype, raw_input: []const u8) solutionOutput(solution) {
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

    fn Output(comptime self: @This(), comptime T: type) type {
        switch (self) {
            .pattern => return []const T,
        }
    }

    fn parseInput(comptime self: @This(), comptime T: type, alloc: *Allocator, raw: []const u8) !self.Output(T) {
        switch (self) {
            .pattern => {
                const trimmed = std.mem.trimRight(u8, raw, &std.ascii.spaces);
                if (trimmed.len == 0) return error.EmptyInput;

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
        }
    }

    fn parsePattern(comptime self: @This(), comptime T: type, line: []const u8) !T {
        const pattern = self.pattern;
        const PatternStruct = switch (@typeInfo(T)) {
            .Struct => T,
            else => struct { value: T },
        };
        const output = try parse.parsePattern(pattern, PatternStruct, line);
        return if (PatternStruct == T) output else output.value;
    }
};

const SolutionInfo = struct {
    input: type,
    output: type,
};

fn solutionOutput(comptime solution: anytype) type {
    const solution_type = @TypeOf(solution);
    const solution_info = @typeInfo(solution_type);
    const solution_fn = if (comptime solution_info == .Fn) solution_info.Fn else @compileError(std.fmt.comptimePrint("expected a function, found {}", .{solution_type}));

    switch (@typeInfo(solution_fn.return_type.?)) {
        .ErrorUnion => |err| return anyerror!err.payload,
        else => return anyerror!(solution_fn.return_type.?),
    }
}

fn getInput(alloc: *Allocator, comptime problem: Problem) ![]u8 {
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

fn fetchInput(alloc: *Allocator, comptime problem: Problem) ![]u8 {
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

fn getSessionKey(alloc: *Allocator) ![]const u8 {
    const name = "AOC_SESSION_KEY";
    return std.process.getEnvVarOwned(alloc, name) catch |err| {
        std.log.err("could not get `{s}`", .{name});
        return err;
    };
}

pub const InputReader = struct {
    bytes: []const u8,
    trimmed: []const u8,
    offset: usize = 0,

    pub fn init(bytes: []const u8) @This() {
        const trimmed = std.mem.trimRight(u8, bytes, &std.ascii.spaces);
        return @This(){ .bytes = bytes, .trimmed = trimmed };
    }

    pub fn initFromStdIn(alloc: *Allocator) !@This() {
        const input = std.io.getStdIn();
        const size_hint = (try input.stat()).size;
        const bytes = try input.readToEndAllocOptions(alloc, 1 << 20, size_hint, @alignOf(u8), null);
        return @This().init(bytes);
    }

    pub fn deinit(self: *@This(), alloc: *Allocator) void {
        alloc.free(self.bytes);
    }

    /// Caller borrows returned memory.
    pub fn nextLine(self: *@This()) ?[]const u8 {
        if (self.offset >= self.trimmed.len) {
            return null;
        }

        if (std.mem.indexOfAnyPos(u8, self.trimmed, self.offset, "\n")) |index| {
            const line = self.trimmed[self.offset..index];
            self.offset = index + 1;
            return line;
        } else {
            const line = self.trimmed[self.offset..];
            self.offset = self.trimmed.len;
            return line;
        }
    }

    /// Caller borrows returned memory.
    pub fn parseLines(self: *@This(), comptime pattern: []const u8, comptime Output: type) ParseLineIterator(pattern, Output) {
        return .{ .input = self };
    }

    fn ParseLineIterator(comptime pattern: []const u8, comptime Output: type) type {
        return struct {
            input: *InputReader,

            const PatternStruct = switch (@typeInfo(Output)) {
                .Struct => Output,
                else => struct { value: Output },
            };
            const Parser = parse.PatternParser(pattern, PatternStruct);

            pub fn next(self: *@This()) !?Output {
                const line = self.input.nextLine() orelse return null;

                const output = try Parser.parse(line);
                return if (PatternStruct == Output) output else output.value;
            }

            pub fn collectToSlice(self: *@This(), alloc: *Allocator) ![]Output {
                var list = std.ArrayListUnmanaged(Output){};
                defer list.deinit(alloc);
                while (try self.next()) |value| try list.append(alloc, value);
                return list.toOwnedSlice(alloc);
            }
        };
    }
};
