const std = @import("std");

pub fn ParseResult(comptime T: type) type {
    return struct { value: T, length: usize };
}

pub fn parse(comptime T: type, text: []const u8) !ParserOutput(T) {
    return ParserFunction(T)(text);
}

pub fn parsePattern(comptime pattern: []const u8, comptime Output: type, text: []const u8) !Output {
    return PatternParser(pattern, Output).parse(text);
}

pub fn ParserOutput(comptime T: type) type {
    if (@typeInfo(T) == .Struct and @hasDecl(T, "ParseOutput")) return T.ParseOutput;
    return T;
}

fn ParserFunction(comptime T: type) (fn ([]const u8) anyerror!ParserOutput(T)) {
    if (@typeInfo(T) == .Struct and @hasDecl(T, "parse")) return T.parse;

    return struct {
        fn parse(text: []const u8) !T {
            const result = try parseSingle(T, text);

            const remaining = text[result.length..];
            if (std.mem.trimLeft(u8, remaining, &std.ascii.spaces).len > 0) {
                std.log.err("trailing characters: `{s}`", .{remaining});
                return error.TrailingCharacters;
            }

            return result.value;
        }
    }.parse;
}

pub fn parseSingle(comptime T: type, text: []const u8) !ParseResult(T) {
    const trait = std.meta.trait;

    if (comptime T == []const u8) {
        return ParseResult(T){
            .value = text,
            .length = text.len,
        };
    }

    if (comptime trait.isIntegral(T)) {
        var length: usize = 0;
        if (std.mem.startsWith(u8, text, "-") or std.mem.startsWith(u8, text, "+")) length += 1;
        while (length < text.len and std.ascii.isDigit(text[length])) : (length += 1) {}

        return ParseResult(T){
            .value = try std.fmt.parseInt(T, text[0..length], 10),
            .length = length,
        };
    }

    if (comptime trait.isFloat(T)) {
        var length = 0;
        if (std.mem.startsWith(u8, text, "-") or std.mem.startsWith(u8, text, "+")) length += 1;
        while (length < text.len and std.ascii.isDigit(text[length])) : (length += 1) {}
        if (length + 1 < text.len and text[length] == '.') {
            length += 1;
            while (length < text.len and std.ascii.isDigit(text[length])) : (length += 1) {}
        }

        return ParseResult(T){
            .value = try std.fmt.parseFloat(T, text[0..length]),
            .length = length,
        };
    }

    if (@typeInfo(T) == .Enum) {
        const fields = @typeInfo(T).Enum.fields;

        const EnumField = std.builtin.TypeInfo.EnumField;

        comptime var fields_ordered: [fields.len]EnumField = undefined;
        comptime {
            inline for (fields) |field, index| {
                fields_ordered[index] = field;
            }
            const S = struct {
                pub fn order(context: void, comptime lhs: EnumField, comptime rhs: EnumField) bool {
                    _ = context;
                    return lhs.name.len > rhs.name.len or (lhs.name.len == rhs.name.len and std.mem.lessThan(u8, lhs.name, rhs.name));
                }
            };
            std.sort.sort(EnumField, &fields_ordered, {}, S.order);
        }

        inline for (fields_ordered) |field| {
            if (std.ascii.startsWithIgnoreCase(text, field.name)) {
                return ParseResult(T){
                    .value = @intToEnum(T, field.value),
                    .length = field.name.len,
                };
            }
        }

        return error.InvalidEnum;
    }

    comptime {
        @compileError(std.fmt.comptimePrint("unsupported type for parsing: {}", .{T}));
    }
}

pub fn PatternParser(comptime pattern: []const u8, Output: type) type {
    const info = @typeInfo(Output);
    if (info != .Struct) @compileError("expected a struct");

    _ = pattern;

    const fields = info.Struct.fields;
    const field_count = fields.len;

    comptime var fragments = [1][]const u8{""} ** (field_count + 1);
    comptime {
        var fragment_buffer: [pattern.len]u8 = undefined;

        var frag_count = 0;
        var buffer_index = 0;

        var last_field = 0;
        var i = 0;
        while (i < pattern.len) : (i += 1) {
            if (pattern[i] == '{') {
                if (i + 1 >= pattern.len) @compileError("unexpected end of pattern");

                if (pattern[i + 1] == '{') {
                    i += 1;
                } else {
                    if (pattern[i + 1] != '}') @compileError("expected `}`");

                    if (frag_count >= fragments.len) {
                        @compileError(std.fmt.comptimePrint("found pattern with more placeholders (`{{}}`) than the provided struct had fields ({})", .{field_count}));
                    }

                    fragments[frag_count] = fragment_buffer[last_field..buffer_index];
                    frag_count += 1;
                    last_field = buffer_index;
                    i += 1;

                    continue;
                }
            }

            fragment_buffer[buffer_index] = pattern[i];
            buffer_index += 1;
        }

        // Add a trailing empty string if the pattern ended with a type specifier
        if (last_field == buffer_index) frag_count += 1;

        if (frag_count != fragments.len)
            @compileError("number of type specifiers (`{}`) does not match number of fields");
    }

    return struct {
        pub const ParseOutput = Output;

        pub fn debug(self: *const @This()) void {
            _ = self;
            std.debug.print("fragments:", .{});
            for (fragments) |fragment| {
                std.debug.print(" '{s}'", .{fragment});
            }
            std.debug.print("\n", .{});
        }

        pub fn parse(text: []const u8) anyerror!Output {
            var output: ParseOutput = undefined;

            var remainder = text;

            if (std.mem.startsWith(u8, remainder, fragments[0])) {
                remainder = remainder[fragments[0].len..];
            } else {
                return error.PatternMismatch;
            }

            inline for (fields) |field, index| {
                const fragment = fragments[index + 1];

                const value = if (fragment.len == 0) blk: {
                    const result = try parseSingle(field.field_type, remainder);
                    remainder = remainder[result.length..];
                    break :blk result.value;
                } else blk: {
                    const end = std.mem.indexOf(u8, remainder, fragment) orelse return error.PatternMismatch;

                    const result = try parseSingle(field.field_type, remainder[0..end]);
                    if (result.length != end) return error.PatternMismatch;

                    remainder = remainder[end + fragment.len ..];
                    break :blk result.value;
                };

                @field(output, field.name) = value;
            }

            return output;
        }
    };
}
