const std = @import("std");
const Allocator = std.mem.Allocator;

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub var global_alloc = &gpa.allocator;

pub const InputReader = struct {
    bytes: []u8,
    offset: usize = 0,

    pub fn initFromStdIn(alloc: *Allocator) !@This() {
        const input = std.io.getStdIn();
        const size_hint = (try input.stat()).size;
        const bytes = try input.readToEndAllocOptions(alloc, 1 << 20, size_hint, @alignOf(u8), null);
        return @This(){ .bytes = bytes };
    }

    pub fn deinit(self: *@This(), alloc: *Allocator) void {
        alloc.free(self.bytes);
    }

    /// Caller borrows returned memory.
    pub fn nextLine(self: *@This()) ?[]u8 {
        if (self.offset >= self.bytes.len) {
            return null;
        }

        if (std.mem.indexOfAnyPos(u8, self.bytes, self.offset, "\n")) |index| {
            const line = self.bytes[self.offset..index];
            self.offset = index + 1;
            return line;
        } else {
            const line = self.bytes[self.offset..];
            self.offset = self.bytes.len;
            return line;
        }
    }

    /// Caller borrows returned memory.
    pub fn parseLines(self: *@This(), comptime Values: type) ParseLineIterator(Values) {
        return .{ .input = self };
    }

    fn ParseLineIterator(comptime T: type) type {
        return struct {
            input: *InputReader,

            pub fn next(self: *@This()) !?T {
                const line = self.input.nextLine() orelse return null;
                return try parseStruct(T, line);
            }

            pub fn collectToSlice(self: *@This(), alloc: *Allocator) ![]T {
                var list = std.ArrayListUnmanaged(T){};
                defer list.deinit(alloc);
                while (try self.next()) |value| try list.append(alloc, value);
                return list.toOwnedSlice(alloc);
            }
        };
    }
};

pub fn parseStruct(comptime Values: type, text: []const u8) !Values {
    const info = @typeInfo(Values);
    const fields = info.Struct.fields;
    _ = fields;

    var values: Values = undefined;
    var remaining = text;

    inline for (fields) |field| {
        const result = try parseSingle(field.field_type, remaining);
        @field(values, field.name) = result.value;
        remaining = remaining[result.length..];
    }

    for (remaining) |char| {
        if (!std.ascii.isSpace(char)) {
            return error.TrailingCharacters;
        }
    }

    return values;
}

fn ParseResult(comptime T: type) type {
    return struct { value: T, length: usize };
}

const WHITESPACE = [_]u8{ ' ', '\n', '\t', '\r' };

pub fn parseSingle(comptime T: type, text: []const u8) !ParseResult(T) {
    const trait = std.meta.trait;

    const trimmed = std.mem.trimLeft(u8, text, &WHITESPACE);
    const word = if (std.mem.indexOfAny(u8, trimmed, &WHITESPACE)) |index| trimmed[0..index] else trimmed;
    const length = text.len - trimmed.len + word.len;

    var result = ParseResult(T){ .value = undefined, .length = length };

    if (comptime T == []const u8) {
        result.value = word;
    } else if (comptime trait.isIntegral(T)) {
        result.value = try std.fmt.parseInt(T, word, 10);
    } else if (comptime trait.isFloat(T)) {
        result.value = try std.fmt.parseFloat(T, word);
    } else comptime {
        @compileError(std.fmt.comptimePrint("unsupported type for parsing: {}", .{T}));
    }

    return result;
}
