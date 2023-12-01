const std = @import("std");

const spelled: [9][]const u8 = .{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn search_slice_for_num(line: []const u8) ?usize {
    if (std.ascii.isDigit(line[0])) {
        return line[0] - '0';
    }
    for (spelled, 1..) |numeral, nth| {
        if (line.len < numeral.len) {
            continue;
        }
        const trimmed = line[0..numeral.len];
        if (std.mem.eql(u8, numeral, trimmed)) {
            return nth;
        }
    }
    return null;
}

fn search(line: []const u8, last: bool) usize {
    const len: isize = @intCast(line.len);
    var i: isize = if (last) len - 1 else 0;
    while (i >= 0 and i < len) : (i += if (last) -1 else 1) {
        if (search_slice_for_num(line[@intCast(i)..])) |num| {
            if (last) {
                return num;
            }
            return num * 10;
        }
    }
    return 0;
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var sum: usize = 0;

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        // First digit
        sum += search(line, false);
        // Last digit
        sum += search(line, true);
    }

    std.debug.print("{}\n", .{sum});
}
