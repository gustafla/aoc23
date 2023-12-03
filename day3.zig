const std = @import("std");

fn findIntegerSpan(str: []const u8, i: isize) ?[]const u8 {
    if (i < 0 or i >= str.len or !std.ascii.isDigit(str[@intCast(i)])) {
        return null;
    }

    // Start index
    var j: isize = i;
    while (j >= 0) : (j -= 1) {
        if (!std.ascii.isDigit(str[@intCast(j)])) {
            break;
        }
    }
    const start: usize = @intCast(j + 1);

    // Stop index
    for (@intCast(i)..str.len) |k| {
        if (!std.ascii.isDigit(str[k])) {
            return str[start..k];
        }
    }

    return str[start..];
}

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

const SchematicResult = struct {
    part_number_sum: usize,
    gear_ratio_sum: usize,

    fn accumulate(self: *SchematicResult, other: SchematicResult) void {
        self.part_number_sum += other.part_number_sum;
        self.gear_ratio_sum += other.gear_ratio_sum;
    }
};

fn gearRatio(lines: []const []const u8, i: isize) ?usize {
    if (getSchematic(lines[1], i) != '*') {
        return null;
    }

    var prev_slice: []const u8 = undefined;
    var gear_part_numbers: usize = 0;
    var ratio: usize = 1;

    // Check for adjacent numbers in a 3x3 matrix
    for (0..3) |k| {
        var j: isize = i - 1;
        while (j <= i + 1) : (j += 1) {
            if (findIntegerSpan(lines[k], j)) |slice| {
                if (slice.ptr != prev_slice.ptr) {
                    const partnum = std.fmt.parseInt(usize, slice, 10) catch unreachable;
                    gear_part_numbers += 1;
                    if (gear_part_numbers > 2) {
                        return null;
                    }
                    ratio *= partnum;
                    prev_slice = slice;
                }
            }
        }
    }

    if (gear_part_numbers != 2) {
        return null;
    }

    return ratio;
}

fn analyzeLine(
    lines: []const []const u8,
) SchematicResult {
    var sum = std.mem.zeroInit(SchematicResult, .{});

    var part: bool = false;

    var i: isize = @intCast(lines[1].len);
    search: while (i >= -1) : (i -= 1) {
        sum.gear_ratio_sum += gearRatio(lines, i) orelse 0;

        const c = getSchematic(lines[1], i);

        // If not a digit, reset parser and skip ahead
        if (!std.ascii.isDigit(c)) {
            // Count part number
            if (part) {
                const int_slice = findIntegerSpan(lines[1], i + 1).?;
                sum.part_number_sum += std.fmt.parseInt(usize, int_slice, 10) catch unreachable;
            }

            part = false;
            continue :search;
        }

        if (part) {
            continue :search;
        }

        // Check for adjacent parts in a 3x3 matrix
        for (0..3) |k| {
            var j: isize = i - 1;
            while (j <= i + 1) : (j += 1) {
                const cc = getSchematic(lines[k], j);
                part = isPart(cc);
                if (part) {
                    continue :search;
                }
            }
        }
    }

    return sum;
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var sum = std.mem.zeroInit(SchematicResult, .{});

    // Define a three-line buffer and slices pointing to each line
    var line_buf: [3][1024]u8 = undefined;
    var lines: [3][]u8 = .{ &line_buf[0], line_buf[1][0..0], line_buf[2][0..0] };

    while (try in_r.readUntilDelimiterOrEof(lines[0], '\n')) |next_line| {
        // Update first in lines length to what was read
        lines[0] = next_line;

        // Update sum from previous line
        sum.accumulate(analyzeLine(&lines));

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
    sum.accumulate(analyzeLine(&lines));

    std.debug.print("{}\n", .{sum});
}
