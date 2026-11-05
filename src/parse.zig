const std = @import("std");
const token = @import("token");
const Token = token.Token;

const ParseError = error{ ExpectedExpression, ExpectedRParen, ExpectedNumber, UnexpectedToken, UnexpectedTrailingTokens };

// 1 + ( 1 // (1) )
pub fn parse(tokens: []const Token) ParseError!f32 {
    var cursor: usize = 0;
    const result = try parse_expr(tokens, &cursor);
    if (cursor < tokens.len) return ParseError.UnexpectedTrailingTokens;
    return result;
}

fn parse_expr(tokens: []const Token, cursor: *usize) ParseError!f32 {
    var left = try parse_term(tokens, cursor);
    while (cursor.* < tokens.len and tokens[cursor.*] == .Series) {
        cursor.* += 1;
        left += try parse_term(tokens, cursor);
    }
    return left;
}

fn parse_term(tokens: []const Token, cursor: *usize) ParseError!f32 {
    var left = try parse_factor(tokens, cursor);
    while (cursor.* < tokens.len and tokens[cursor.*] == .Parallel) {
        cursor.* += 1;
        const right = try parse_factor(tokens, cursor);
        left = 1.0 / ((1.0 / left) + (1.0 / right)); // R1 // R2
    }
    return left;
}

fn parse_factor(tokens: []const Token, cursor: *usize) ParseError!f32 {
    if (cursor.* >= tokens.len) return ParseError.ExpectedExpression;
    switch (tokens[cursor.*]) {
        .Number => |n| {
            cursor.* += 1;
            return n;
        },
        .LP => {
            cursor.* += 1;
            const res = try parse_expr(tokens, cursor);
            if (cursor.* >= tokens.len or tokens[cursor.*] != .RP)
                return ParseError.ExpectedRParen;
            cursor.* += 1;
            return res;
        },
        else => return ParseError.UnexpectedToken,
    }
}

const Tester = if (@import("builtin").is_test) struct {
    fn eval(src: []const u8) !f32 {
        const allocator = t.allocator;
        var buff: std.ArrayList(Token) = .empty;
        defer buff.deinit(allocator);
        try token.tokenize(src, &buff, allocator);
        return parse(buff.items);
    }

    fn run(src: []const u8, expected: f32) !void {
        try t.expectEqual(
            try eval(src),
            expected,
        );
    }
} else struct {};

const t = std.testing;
test "series1" {
    try Tester.run("1+1", 2);
}

test "series2" {
    try Tester.run("32+7", 39);
}

test "parallel1" {
    try Tester.run("1//1", 0.5);
}

test "parallel2" {
    try Tester.run("1//1//1", 1.0 / 3.0);
}
