const std = @import("std");

const Error = error{
    InvalidInput,
} || std.fmt.ParseIntError;

const Set = std.bit_set.ArrayBitSet(usize, 100);

fn parseList(slice: []const u8) Error!Set {
    var set = Set.initEmpty();
    var it = std.mem.splitScalar(u8, slice, ' ');
    while (it.next()) |str| {
        if (str.len == 0) {
            continue;
        }
        const index = try std.fmt.parseInt(usize, str, 10);
        set.set(index);
    }

    return set;
}

fn score(card: []const u8) Error!usize {
    // Get slice of everything after ":"
    const colon = std.mem.indexOfScalar(u8, card, ':') orelse return Error.InvalidInput;
    const numbers = card[colon + 1 ..];
    const bar = std.mem.indexOfScalar(u8, numbers, '|') orelse return Error.InvalidInput;
    const winners = numbers[0..bar];
    var winner_set = try parseList(winners);
    const have = numbers[bar + 1 ..];
    const have_set = try parseList(have);

    winner_set.setIntersection(have_set);
    const matches = winner_set.count();

    if (matches == 0) {
        return 0;
    }

    return @as(usize, 1) << @intCast(matches - 1);
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var sum: usize = 0;

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        sum += score(line) catch 0; // Ignore errors
    }

    std.debug.print("{}\n", .{sum});
}
