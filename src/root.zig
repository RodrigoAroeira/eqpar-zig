const std = @import("std");
const token = @import("token");
const parse = @import("parse");
const Io = std.Io;
const Allocator = std.mem.Allocator;

pub fn repl(stdin: *Io.Reader, stdout: *Io.Writer, allocator: Allocator) !void {
    while (true) {
        try stdout.print("> ", .{});
        try stdout.flush();
        const line = stdin.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        stdin.toss(1);
        var tokens: std.ArrayList(token.Token) = .empty;
        defer tokens.deinit(allocator);
        token.tokenize(line, &tokens, allocator) catch |err| {
            std.debug.print("{}\n", .{err});
            continue;
        };
        // for (tokens.items) |tok| {
        //     std.debug.print("{} ", .{tok});
        // }
        std.debug.print("\n", .{});
        const eq = parse.parse(tokens.items) catch |err| {
            std.debug.print("Unable to parse: {}\n", .{err});
            continue;
        };
        try stdout.print("{d}\n", .{eq});
    }
}
