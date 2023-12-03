const std = @import("std");

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    const sum: usize = 0;

    var prev_lines: [2][1024]u8 = undefined;

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        std.debug.print("{s}\n", .{prev_lines[1]});

        prev_lines[1] = prev_lines[0];
        std.mem.copyForwards(u8, &prev_lines[0], line);
    }

    std.debug.print("{}\n", .{sum});
}
