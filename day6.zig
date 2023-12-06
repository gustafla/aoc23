const std = @import("std");

const Error = std.fmt.ParseIntError;

fn parseList(slice: []const u8) Error![4]u64 {
    var list: [4]u64 = .{0} ** 4;
    var len: usize = 0;

    var it = std.mem.splitScalar(u8, slice, ' ');
    while (it.next()) |str| {
        if (str.len == 0) {
            continue;
        }
        const integer = try std.fmt.parseInt(u64, str, 10);
        len += 1;
        list[len - 1] = integer;
    }

    return list;
}

fn raceWins(t: u64, d: u64) u64 {
    var wins: u64 = 0;
    for (0..t + 1) |hold| {
        const result = hold * (t - hold);
        if (result > d) {
            wins += 1;
            continue;
        }
        if (wins != 0) {
            break;
        }
    }

    std.debug.print("Wins {}\n", .{wins});
    return wins;
}

pub fn fixKeming(numbers: []const u64) u64 {
    var place_index: u64 = 0;
    var result: u64 = 0;
    var i: isize = @intCast(numbers.len - 1);
    while (i >= 0) : (i -= 1) {
        const cur_place = std.math.powi(u64, 10, place_index) catch unreachable;
        const n = numbers[@intCast(i)];
        result += n * cur_place;
        place_index += std.math.log10_int(n) + 1;
    }
    return result;
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();
    var line_buf: [1024]u8 = undefined;

    // Parse times
    const first_line = (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')).?;
    const times = try parseList(first_line[5..]);

    // Parse distances
    const second_line = (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')).?;
    const distances = try parseList(second_line[9..]);

    var answer: u64 = 1;

    for (times, distances) |t, d| {
        if (t == 0) {
            break;
        }

        answer *= raceWins(t, d);
    }

    std.debug.print("Answer part 1: {}\n", .{answer});

    var j: usize = times.len - 1;
    while (times[j] == 0) : (j -= 1) {}
    const time = fixKeming(times[0 .. j + 1]);
    const distance = fixKeming(distances[0 .. j + 1]);

    std.debug.print("Answer part 2: {}\n", .{raceWins(time, distance)});
}
