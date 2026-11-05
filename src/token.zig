const std = @import("std");

pub const Token = union(enum) {
    LP,
    RP,
    Series,
    Parallel,
    Number: f32,
};

fn scan_number(src: []const u8, i: *usize) !f32 {
    const start = i.*;
    var digits: usize = 0;
    var dots: usize = 0;

    if (src[i.*] == '-') i.* += 1;

    while (i.* < src.len) {
        switch (src[i.*]) {
            '0'...'9' => digits += 1,
            '.' => dots += 1,
            else => break,
        }
        i.* += 1;
    }

    if (digits == 0) return error.expectedNumber;
    if (dots > 1) return error.malformedNumber;

    const val = std.fmt.parseFloat(f32, src[start..i.*]);
    i.* -= 1; // idk it just works
    return val;
}

pub fn tokenize(src: []const u8, buff: *std.ArrayList(Token), allocator: std.mem.Allocator) !void {
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        const c = src[i];

        switch (c) {
            ' ', '\n' => {},
            '(' => try buff.append(allocator, .LP),
            ')' => try buff.append(allocator, .RP),
            '+' => try buff.append(allocator, .Series),
            '/' => {
                if (i + 1 >= src.len or src[i + 1] != '/') {
                    return error.expectedAnotherSlash;
                }
                i += 1;
                try buff.append(allocator, .Parallel);
            },
            '0'...'9', '-' => try buff.append(allocator, .{ .Number = try scan_number(src, &i) }),
            else => return error.UnknownToken,
        }
    }
}

const Tester = if (@import("builtin").is_test) struct {
    fn run(src: []const u8, expected: []const Token) !void {
        const allocator = t.allocator;
        var buff: std.ArrayList(Token) = .empty;
        defer buff.deinit(allocator);

        try tokenize(src, &buff, allocator);
        try t.expectEqualSlices(Token, expected, buff.items);
    }

    fn expectError(src: []const u8, expected_err: anyerror) !void {
        const allocator = t.allocator;
        var buff: std.ArrayList(Token) = .empty;
        defer buff.deinit(allocator);

        try t.expectError(expected_err, tokenize(src, &buff, allocator));
    }
} else struct {};

const t = std.testing;

test "series" {
    try Tester.run("1+1", &.{
        Token{ .Number = 1 },
        .Series,
        Token{ .Number = 1 },
    });
}

test "parallel" {
    try Tester.run("10 // 20", &.{
        Token{ .Number = 10 },
        .Parallel,
        Token{ .Number = 20 },
    });
}

test "parentheses" {
    try Tester.run("(1 + 2)", &.{
        .LP,
        Token{ .Number = 1 },
        .Series,
        Token{ .Number = 2 },
        .RP,
    });
}

test "decimals and negatives" {
    try Tester.run("-3.5 // 0.25", &.{
        Token{ .Number = -3.5 },
        .Parallel,
        Token{ .Number = 0.25 },
    });
}

test "whitespace" {
    try Tester.run("  \n 42 \n  +   10  \n", &.{
        Token{ .Number = 42 },
        .Series,
        Token{ .Number = 10 },
    });
}

test "errors" {
    try Tester.expectError("10 / 20", error.expectedAnotherSlash);
    try Tester.expectError("10 * 20", error.UnknownToken);
    try Tester.expectError("1.2.3", error.malformedNumber);
    try Tester.expectError("-", error.expectedNumber);
}
