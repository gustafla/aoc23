const std = @import("std");

fn getSchematic(line: []const u8, index: isize) u8 {
    // Bounds check
    if (index < 0 or index >= line.len) {
        return '.';
    }
    return line[@intCast(index)];
}

fn isPart(c: u8) bool {
    return !std.ascii.isWhitespace(c) and !std.ascii.isDigit(c) and c != '.';
}

fn lineSum(
    lines: []const []const u8,
) usize {
    var sum: usize = 0;

    var part: bool = false;
    var place: usize = 1;
    var integer: usize = 0;

    var i: isize = @intCast(lines[1].len);
    while (i >= -1) : (i -= 1) {
        const c = getSchematic(lines[1], i);

        // If not a digit, reset integer parser and skip ahead
        if (!std.ascii.isDigit(c)) {
            // Count part
            if (part) {
                sum += integer;
            }

            part = false;
            place = 1;
            integer = 0;
            continue;
        }

        // Check for adjacent parts in a 3x3 matrix
        var j: isize = i - 1;
        while (j <= i + 1) : (j += 1) {
            for (0..3) |k| {
                const cc = getSchematic(lines[k], j);
                part = part or isPart(cc);
            }
        }

        // Update integer parser
        const value: usize = @intCast(c - '0');
        integer += value * place;
        place *= 10;
    }

    return sum;
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var sum: usize = 0;

    // Define a three-line buffer and slices pointing to each line
    var line_buf: [3][1024]u8 = undefined;
    var lines: [3][]u8 = .{ &line_buf[0], line_buf[1][0..0], line_buf[2][0..0] };

    while (try in_r.readUntilDelimiterOrEof(lines[0], '\n')) |next_line| {
        // Update first in lines length to what was read
        lines[0] = next_line;

        // Update sum from previous line
        sum += lineSum(&lines);

        // Swap pointers, switching underlying line_buf memory around
        // The effect of this pointer juggling is, that when the slices in the
        // `lines` array are read from first to last, the lines are
        // always in chronological order. No extra copies are needed.
        std.mem.swap([]u8, &lines[1], &lines[2]);
        std.mem.swap([]u8, &lines[0], &lines[1]);

        // Update lines[0] len for next iteration's read-call
        lines[0].len = line_buf[0].len;
    }

    // Process remaining line
    lines[0].len = 0;
    sum += lineSum(&lines);

    std.debug.print("{}\n", .{sum});
}
