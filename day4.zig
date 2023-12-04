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

fn parseMatches(card: []const u8) Error!usize {
    // Get slice of everything after ":"
    const colon = std.mem.indexOfScalar(u8, card, ':') orelse return Error.InvalidInput;
    const numbers = card[colon + 1 ..];
    const bar = std.mem.indexOfScalar(u8, numbers, '|') orelse return Error.InvalidInput;
    const winners = numbers[0..bar];
    var winner_set = try parseList(winners);
    const have = numbers[bar + 1 ..];
    const have_set = try parseList(have);

    winner_set.setIntersection(have_set);
    return winner_set.count();
}

fn score(matches: usize) usize {
    if (matches == 0) {
        return 0;
    }

    return @as(usize, 1) << @intCast(matches - 1);
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    // This agorithm keeps a M+1 size array with "upcoming" card copies,
    // where M is the maximum number of matches.
    // The array is rotated with each iteration, so that at the start of
    // each iteration, the first element contains the number of card
    // copies that have already been won for the current card.
    //
    // Example:
    //
    // Counting 1 copies
    // And then, this card wins 4 new copies
    // Updated copies-array: { 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1 }
    //
    // Counting 2 copies
    // And then, these cards win 2 new copies
    // Updated copies-array: { 4, 4, 2, 1, 1, 1, 1, 1, 1, 1, 1 }
    //
    // Counting 4 copies
    // And then, these cards win 2 new copies
    // Updated copies-array: { 8, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
    //
    // Counting 8 copies
    // And then, these cards win 1 new copies
    // Updated copies-array: { 14, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
    //
    // Counting 14 copies
    // And then, these cards win 0 new copies
    // Updated copies-array: { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
    //
    // Counting 1 copies
    // And then, this card wins 0 new copies
    // Updated copies-array: { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
    //
    // Total cards: 30

    var score_sum: usize = 0;
    var count_sum: usize = 0;
    var copies: [11]usize = .{1} ** 11;

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        // Part 2 solution
        const matches = parseMatches(line) catch continue;
        const current_card_copies = copies[0];
        count_sum += current_card_copies;
        std.mem.rotate(usize, &copies, 1);
        for (0..matches) |i| {
            copies[i] += current_card_copies;
        }
        copies[copies.len - 1] = 1;

        // Part 1 solution
        score_sum += score(matches);
    }

    std.debug.print("Total score: {}\n", .{score_sum});
    std.debug.print("Total cards: {}\n", .{count_sum});
}
