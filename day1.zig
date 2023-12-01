const std = @import("std");

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var sum: u32 = 0;

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        var prev_digit: ?u8 = null;

        for (line) |character| {
            if (std.ascii.isDigit(character)) {
                if (prev_digit == null) {
                    sum += (character - '0') * 10;
                }
                prev_digit = character;
            }
        }

        if (prev_digit) |pd| {
            sum += pd - '0';
        }
    }

    std.debug.print("{}\n", .{sum});
}
