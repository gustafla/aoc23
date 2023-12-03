const std = @import("std");

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    const sum: usize = 0;

    var prev_lines_buf: [2][1024]u8 = undefined;
    var prev_lines: [2][]u8 = .{ prev_lines_buf[0][0..0], prev_lines_buf[1][0..0] };

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |next_line| {
        std.debug.print("{s}\n", .{prev_lines[1]});

        std.mem.swap([]u8, &prev_lines[0], &prev_lines[1]);
        prev_lines[0].len = next_line.len;
        std.mem.copyForwards(u8, prev_lines[0], next_line);
    }

    std.debug.print("{}\n", .{sum});
}
