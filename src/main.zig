const std = @import("std");
const Io = std.Io;

const eqpar = @import("eqpar");

pub fn main(init: std.process.Init) !void {
    var writer_buff: [1024]u8 = undefined;
    var writer: Io.File.Writer = .init(.stdout(), init.io, &writer_buff);
    defer writer.flush() catch {};

    const stdout = &writer.interface;

    const allocator = init.arena.allocator();
    const args = (try init.minimal.args.toSlice(allocator))[1..];

    if (args.len == 0) {
        var reader_buff: [1024]u8 = undefined;
        var reader: Io.File.Reader = .init(.stdin(), init.io, &reader_buff);

        try eqpar.repl(&reader.interface, stdout, allocator);
    } else {
        var line: std.ArrayList(u8) = .empty;
        for (args) |arg| {
            for (arg) |c|
                try line.append(allocator, c);
            try line.append(allocator, ' ');
        }

        try eqpar.run(stdout, line.items, allocator);
    }
}
