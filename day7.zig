const std = @import("std");

const Error = error{ InvalidCard, MalformedLine };
const Card = enum { c2, c3, c4, c5, c6, c7, c8, c9, t, j, q, k, a };

fn cardFace(card: Card) u8 {
    return switch (@intFromEnum(card)) {
        0...@intFromEnum(Card.c9) => @as(u8, '2') + @intFromEnum(card),
        @intFromEnum(Card.t) => 'T',
        @intFromEnum(Card.j) => 'J',
        @intFromEnum(Card.q) => 'Q',
        @intFromEnum(Card.k) => 'K',
        @intFromEnum(Card.a) => 'A',
        else => unreachable,
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
        return Error.MalformedLine;
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

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var hands = std.ArrayList(Hand).init(allocator);
    var bids = std.ArrayList(u16).init(allocator);

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        const h = try parseHand(line);
        try hands.append(h[1]);
        if (h[0][0] != ' ') {
            return Error.MalformedLine;
        }
        const bid = try std.fmt.parseInt(u16, h[0][1..], 10);
        try bids.append(bid);
    }

    for (hands.items, bids.items) |hand, bid| {
        std.debug.print("{s} {}\n", .{ handToStr(hand), bid });
    }
}
