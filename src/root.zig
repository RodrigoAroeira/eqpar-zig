const std = @import("std");
const token = @import("token");
const parse = @import("parse");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const OHM = "\u{03A9}";

pub fn run(stdout: *Io.Writer, line: []const u8, allocator: Allocator) !void {
    var tokens: std.ArrayList(token.Token) = .empty;
    defer tokens.deinit(allocator);
    token.tokenize(line, &tokens, allocator) catch |err| {
        std.debug.print("{}\n", .{err});
        return;
    };
    const eq = parse.parse(tokens.items) catch |err| {
        std.debug.print("Unable to parse: {}\n", .{err});
        return;
    };
    try stdout.print("{d} {s}\n", .{ eq, OHM });
}

pub fn repl(stdin: *Io.Reader, stdout: *Io.Writer, allocator: Allocator) !void {
    while (true) {
        try stdout.print("> ", .{});
        try stdout.flush();
        const line = stdin.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        stdin.toss(1);
        run(stdout, line, allocator) catch {};
    }
}
