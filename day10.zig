const std = @import("std");

const Error = std.mem.Allocator.Error;
const Allocator = std.mem.Allocator;

const Pipe = enum {
    ns,
    we,
    ne,
    nw,
    sw,
    se,
};

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var line_buf = try std.ArrayList(u8).initCapacity(allocator, 1024);
    try in_r.readAllArrayList(&line_buf, 1024 * 1024);

    const width = std.mem.indexOfScalar(u8, line_buf.items, '\n').?;
    const height = line_buf.items.len / (width + 1);

    const matrix = try allocator.alloc(?Pipe, width * height);
    var start: ?struct { usize, usize } = null;
    for (line_buf.items, 0..) |char, i| {
        if (char == '\n') {
            continue;
        }
        const y = i / (width + 1);
        const x = (i - y) % (width);
        const index = y * width + x;
        const tile = switch (char) {
            '|' => Pipe.ns,
            '-' => Pipe.we,
            'L' => Pipe.ne,
            'J' => Pipe.nw,
            '7' => Pipe.sw,
            'F' => Pipe.se,
            '.' => null,
            'S' => blk: {
                start = .{ x, y };
                break :blk null;
            },
            else => @panic("Unsupported character " ++ .{char}),
        };
        matrix[index] = tile;
    }
}
