const std = @import("std");

pub fn ParseResult(comptime T: type) type {
    return struct { value: T, length: usize };
}

pub fn parsePattern(comptime Output: type, comptime pattern: []const u8, text: []const u8) !Output {
    return PatternParser(Output, pattern).parse(text);
}

pub fn ParserOutput(comptime T: type) type {
    if (@typeInfo(T) == .Struct and @hasDecl(T, "ParseOutput")) return T.ParseOutput;
    return T;
}

pub fn parseSingle(comptime T: type, comptime specifier: []const u8, text: []const u8) !ParseResult(T) {
    if (text.len == 0) return error.EndOfInput;

    const trait = std.meta.trait;

    if (comptime T == []const u8) {
        return ParseResult(T){
            .value = text,
            .length = text.len,
        };
    }
    if (comptime trait.isIntegral(T)) {
        return parseInt(T, specifier, text);
    }
    if (comptime trait.isFloat(T)) {
        return parseFloat(T, specifier, text);
    }
    if (@hasDecl(T, "parse")) {
        return parseCustom(T, specifier, text);
    }
    if (@typeInfo(T) == .Enum) {
        return parseEnum(T, specifier, text);
    }
    comptime {
        @compileError(std.fmt.comptimePrint("unsupported type for parsing: {}", .{T}));
    }
}

fn parseInt(comptime T: type, comptime specifier: []const u8, text: []const u8) !ParseResult(T) {
    comptime var radix: u32 = 10;
    comptime {
        const specifiers = .{
            .{ .specifier = "", .radix = 10 },
            .{ .specifier = "b", .radix = 2 },
            .{ .specifier = "x", .radix = 16 },
        };

        inline for (specifiers) |spec| {
            if (std.mem.eql(u8, specifier, spec.specifier)) {
                radix = spec.radix;
                break;
            }
        } else {
            @compileError(std.fmt.comptimePrint("unknown specifier for integers: `{s}`", .{specifier}));
        }
    }

    var length: usize = 0;
    if (std.mem.startsWith(u8, text, "-") or std.mem.startsWith(u8, text, "+")) length += 1;
    while (length < text.len and std.ascii.isDigit(text[length])) : (length += 1) {}

    return ParseResult(T){
        .value = try std.fmt.parseInt(T, text[0..length], radix),
        .length = length,
    };
}

fn parseFloat(comptime T: type, comptime specifier: []const u8, text: []const u8) !ParseResult(T) {
    if (specifier.len != 0) {
        @compileError(std.fmt.comptimePrint("unknown specifier for enums: `{s}`", .{specifier}));
    }

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

fn parseEnum(comptime T: type, comptime specifier: []const u8, text: []const u8) !ParseResult(T) {
    if (specifier.len != 0) {
        @compileError(std.fmt.comptimePrint("unknown specifier for enums: `{s}`", .{specifier}));
    }

    const fields = @typeInfo(T).Enum.fields;

    const EnumField = std.builtin.TypeInfo.EnumField;

    comptime var fields_ordered: [fields.len]EnumField = undefined;
    comptime {
        inline for (fields) |field, index| {
            fields_ordered[index] = field;
        }
        std.sort.sort(EnumField, &fields_ordered, {}, struct {
            pub fn order(_: void, comptime lhs: EnumField, comptime rhs: EnumField) bool {
                return lhs.name.len > rhs.name.len or (lhs.name.len == rhs.name.len and std.mem.lessThan(u8, lhs.name, rhs.name));
            }
        }.order);
    }

    inline for (fields_ordered) |field| {
        if (std.ascii.startsWithIgnoreCase(text, field.name)) {
            return ParseResult(T){
                .value = @intToEnum(T, field.value),
                .length = field.name.len,
            };
        }
    }

    std.log.err("not a valid {s}: '{s}'", .{ @typeName(T), text });

    return error.InvalidEnum;
}

fn parseCustom(comptime T: type, comptime specifier: []const u8, text: []const u8) !ParseResult(T) {
    if (@hasDecl(T, "parse")) {
        if (specifier.len != 0) @compileError("cannot use specifier `" ++ specifier ++ "` together with custom parser");
        const value = try T.parse(text);
        if (@TypeOf(value) == ParseResult(T)) {
            return value;
        } else {
            return ParseResult(T){
                .value = value,
                .length = text.len,
            };
        }
    } else {
        @compileError(std.fmt.comptimePrint("struct `{}` does not have a `parse` function"));
    }
}

pub fn PatternParser(comptime Output: type, comptime pattern: []const u8) type {
    const Fields = if (@typeInfo(Output) == .Struct) Output else struct { inner: Output };
    const fields = @typeInfo(Fields).Struct.fields;

    comptime var fragments = [1][]const u8{""} ** (fields.len + 1);
    comptime var specifiers = [1][]const u8{""} ** fields.len;
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
                    if (frag_count >= fields.len) {
                        @compileError(std.fmt.comptimePrint("found pattern with more placeholders (>= {}) than the provided struct had fields ({})", .{ frag_count, fields.len }));
                    }

                    i += 1;
                    if (std.mem.indexOf(u8, pattern[i..], "}")) |index| {
                        fragments[frag_count] = fragment_buffer[last_field..buffer_index];
                        specifiers[frag_count] = pattern[i .. i + index];

                        frag_count += 1;
                        last_field = buffer_index;
                        i += index;
                        continue;
                    } else {
                        @compileError(std.fmt.comptimePrint("expected closing `}}`, found `{s}`", .{pattern[i..]}));
                    }
                }
            }

            fragment_buffer[buffer_index] = pattern[i];
            buffer_index += 1;
        }

        // Add a trailing fragment
        fragments[frag_count] = fragment_buffer[last_field..buffer_index];
        frag_count += 1;

        if (frag_count != fragments.len)
            @compileError(std.fmt.comptimePrint("number of type specifiers ({}) does not match number of fields ({})", .{ frag_count - 1, fields.len }));
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

        pub fn parse(text: []const u8) anyerror!ParseOutput {
            var output: Fields = undefined;

            var remainder = text;

            if (std.mem.startsWith(u8, remainder, fragments[0])) {
                remainder = remainder[fragments[0].len..];
            } else {
                return error.PatternMismatch;
            }

            inline for (fields) |field, index| {
                const fragment = fragments[index + 1];
                const specifier = specifiers[index];

                const value = if (fragment.len == 0) blk: {
                    const result = try parseSingle(field.field_type, specifier, remainder);
                    remainder = remainder[result.length..];
                    break :blk result.value;
                } else blk: {
                    const end = std.mem.indexOf(u8, remainder, fragment) orelse return error.PatternMismatch;

                    const result = try parseSingle(field.field_type, specifier, remainder[0..end]);
                    if (result.length != end) return error.PatternMismatch;

                    remainder = remainder[end + fragment.len ..];
                    break :blk result.value;
                };

                @field(output, field.name) = value;
            }

            if (Fields == ParseOutput) {
                return output;
            } else {
                return output.inner;
            }
        }
    };
}
