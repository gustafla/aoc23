const std = @import("std");

const Error = error{ InvalidCard, MalformedLine } || std.fmt.ParseIntError;

const Card = enum {
    j,
    c2,
    c3,
    c4,
    c5,
    c6,
    c7,
    c8,
    c9,
    t,
    q,
    k,
    a,

    fn face(self: Card) u8 {
        const tagname = @tagName(self);
        return std.ascii.toUpper(tagname[tagname.len - 1]);
    }

    fn parse(char: u8) Error!Card {
        return switch (char) {
            '2'...'9' => @enumFromInt(char - '2' + 1),
            'T' => .t,
            'J' => .j,
            'Q' => .q,
            'K' => .k,
            'A' => .a,
            else => Error.InvalidCard,
        };
    }

    fn lessThan(_ctx: void, lhs: Card, rhs: Card) bool {
        _ = _ctx;
        return @intFromEnum(lhs) < @intFromEnum(rhs);
    }
};

const HandType = enum {
    high_card,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,

    fn evaluateHand(cards: [5]Card) HandType {
        const fields = @typeInfo(Card).Enum.fields.len;
        var c: [fields]u3 = .{0} ** fields;
        for (cards) |card| {
            c[@intFromEnum(card)] += 1;
        }
        const jokers = c[0];
        const others = c[1..];
        std.mem.sort(u3, others, {}, std.sort.desc(u3));
        // Hand with greatest count of same card in earlier place is most valuable
        return switch (jokers) {
            5 => .five_of_a_kind,
            4 => .five_of_a_kind,
            3 => switch (others[0]) {
                2 => .five_of_a_kind,
                1 => .four_of_a_kind,
                else => unreachable,
            },
            2 => switch (others[0]) {
                3 => .five_of_a_kind,
                2 => .four_of_a_kind,
                1 => .three_of_a_kind, // todo ??
                else => unreachable,
            },
            1 => switch (others[0]) {
                4 => .five_of_a_kind,
                3 => .four_of_a_kind,
                2 => switch (others[1]) {
                    2 => .full_house,
                    1 => .three_of_a_kind,
                    else => unreachable,
                },
                1 => .one_pair,
                else => unreachable,
            },
            0 => switch (others[0]) {
                5 => .five_of_a_kind,
                4 => .four_of_a_kind,
                3 => switch (others[1]) {
                    2 => .full_house,
                    1 => .three_of_a_kind,
                    else => unreachable,
                },
                2 => switch (others[1]) {
                    2 => .two_pair,
                    1 => .one_pair,
                    else => unreachable,
                },
                1 => .high_card,
                else => unreachable,
            },
            else => unreachable,
        };
    }
};

const Hand = struct {
    cards: [5]Card,
    type: HandType,
    bid: u16,

    fn toStr(self: Hand) [5]u8 {
        var buf: [5]u8 = undefined;
        for (self.cards, &buf) |card, *char| {
            char.* = Card.face(card);
        }
        return buf;
    }

    fn parse(line: []const u8) Error!Hand {
        if (line.len < 6) {
            return Error.MalformedLine;
        }

        var hand: Hand = undefined;
        for (line[0..5], &hand.cards) |char, *card| {
            card.* = try Card.parse(char);
        }

        if (line[5] != ' ') {
            return Error.MalformedLine;
        }

        hand.type = HandType.evaluateHand(hand.cards);
        hand.bid = try std.fmt.parseInt(u16, line[6..], 10);

        return hand;
    }

    fn lessThanDefaultRule(lhs: Hand, rhs: Hand) bool {
        for (lhs.cards, rhs.cards) |l, r| {
            if (@intFromEnum(l) < @intFromEnum(r)) {
                return true;
            }
            if (@intFromEnum(l) > @intFromEnum(r)) {
                return false;
            }
        }
        return false;
    }

    fn lessThan(_ctx: void, lhs: Hand, rhs: Hand) bool {
        _ = _ctx;

        std.debug.print("\nComparing cards {s} and {s}\n", .{ toStr(lhs), toStr(rhs) });
        std.debug.print("    {s} and {s}\n", .{ @tagName(lhs.type), @tagName(rhs.type) });

        // Same type, uh oh
        if (lhs.type == rhs.type) {
            // Default rule
            std.debug.print("    Fall back to default rule\n", .{});
            const result = lessThanDefaultRule(lhs, rhs);
            std.debug.print("    Left is{s} lesser.\n", .{if (result) "" else "n't"});
            return result;
        }

        // Best type of hand
        const result = @intFromEnum(lhs.type) < @intFromEnum(rhs.type);
        std.debug.print("    Left is{s} lesser.\n", .{if (result) "" else "n't"});
        return result;
    }
};

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var hands = std.ArrayList(Hand).init(allocator);

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        try hands.append(try Hand.parse(line));
    }

    std.mem.sort(Hand, hands.items, {}, Hand.lessThan);

    var total: usize = 0;
    for (hands.items, 1..) |hand, rank| {
        std.debug.print("{:4}: {s} {s} {}\n", .{ rank, Hand.toStr(hand), @tagName(hand.type), hand.bid });
        total += hand.bid * rank;
    }
    std.debug.print("Total winnings: {}\n", .{total});
}
