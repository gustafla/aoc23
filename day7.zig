const std = @import("std");

const Error = error{ InvalidCard, NotEnoughCards };
const Card = enum { c2, c3, c4, c5, c6, c7, c8, c9, t, j, q, k, a };

fn cardFace(card: Card) u8 {
    return switch (card) {
        .c2....c9 => '2' + @intFromEnum(card),
        .t => 'T',
        .j => 'J',
        .q => 'Q',
        .k => 'K',
        .a => 'A',
    };
}

fn parseCard(char: u8) Error!Card {
    return switch (char) {
        '2'...'9' => @enumFromInt(char - '2'),
        'T' => .t,
        'J' => .j,
        'Q' => .q,
        'K' => .k,
        'A' => .a,
        else => Error.InvalidCard,
    };
}

const Hand = [5]Card;

fn handToStr(hand: Hand) [5]u8 {
    var buf: [5]u8 = undefined;
    for (hand, &buf) |card, *char| {
        char.* = cardFace(card);
    }
    return buf;
}

fn parseHand(str: []const u8) Error!struct { []const u8, Hand } {
    if (str.len < 5) {
        return Error.NotEnoughCards;
    }

    var hand: Hand = undefined;
    for (str[0..5], &hand) |char, *card| {
        card.* = try parseCard(char);
    }

    return .{ str[5..], hand };
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        _ = line;
    }
}
