const std = @import("std");

const Error = error{
    InvalidInteger,
    InvalidId,
    InvalidCubes,
    InvalidColor,
    InvalidSet,
};

fn parse_integer(str: []const u8) Error!usize {
    var n: usize = 0;

    // Keep count of place (ones, tens, hundreds, ...)
    var place: usize = 1;

    // Iterate digits from last to first
    const len: isize = @intCast(str.len);
    var i: isize = len - 1;
    while (i >= 0) : (i -= 1) {
        const digit = str[@intCast(i)];

        // Check for valid digit
        if (!std.ascii.isDigit(digit)) {
            return Error.InvalidInteger;
        }

        // Convert to integer
        const value: usize = @intCast(digit - '0');
        n += value * place;

        // Update place for next iteration
        place *= 10;
    }

    return n;
}

fn count_characters(str: []const u8, isFn: *const fn (c: u8) bool) usize {
    var n: usize = 0;
    for (str) |char| {
        if (!isFn(char)) {
            break;
        }
        n += 1;
    }
    return n;
}

fn parse_id(game: []const u8) Error!struct { []const u8, usize } {
    if (game.len < 7) {
        return Error.InvalidId;
    }

    // Check that string starts with Game
    if (!std.mem.eql(u8, "Game ", game[0..5])) {
        return Error.InvalidId;
    }

    // Count digits
    const g = game[5..];
    const digits = g[count_characters(g, std.ascii.isWhitespace)..];
    const n_digits = count_characters(digits, std.ascii.isDigit);

    // Check for id number presence
    if (n_digits == 0) {
        return Error.InvalidId;
    }

    // Check for buffer overread (semicolon)
    if (n_digits >= digits.len) {
        return Error.InvalidId;
    }

    // Check for semicolon
    if (digits[n_digits] != ':') {
        return Error.InvalidId;
    }

    const id = try parse_integer(digits[0..n_digits]);

    return .{ digits[n_digits + 1 ..], id };
}

const color_names: [3][]const u8 = .{ "red", "green", "blue" };
const Color = enum { red, green, blue };

fn parse_color(game: []const u8) Error!struct { []const u8, Color } {
    for (color_names, 0..) |color_name, i| {
        // Check that available length matches expectation
        if (color_name.len > game.len) {
            continue;
        }

        // Check that color name is correct
        const color = game[0..color_name.len];
        if (std.mem.eql(u8, color, color_name)) {
            return .{ game[color_name.len..], @enumFromInt(i) };
        }
    }

    return Error.InvalidColor;
}

fn parse_cubes(game: []const u8) Error!struct { []const u8, usize, Color } {
    // Count digits
    const n_digits = count_characters(game, std.ascii.isDigit);
    if (n_digits == 0) {
        return Error.InvalidCubes;
    }

    // Count spaces after digits
    const n_spaces = count_characters(game[n_digits..], std.ascii.isWhitespace);
    if (n_spaces == 0) {
        return Error.InvalidCubes;
    }

    // Parse color and count
    const color = try parse_color(game[n_digits + n_spaces ..]);
    const count = try parse_integer(game[0..n_digits]);

    return .{ color[0], count, color[1] };
}

const Set = struct {
    counts: [3]usize,

    fn update(self: *Set, color: Color, count: usize) Error!void {
        const i: usize = @intFromEnum(color);
        if (self.counts[i] != 0) {
            return Error.InvalidSet;
        }
        self.counts[i] = count;
    }

    fn update_maximum(self: *Set, s: Set) void {
        for (&self.counts, s.counts) |*i, j| {
            if (j > i.*) {
                i.* = j;
            }
        }
    }

    fn is_possible(self: Set, limits: [3]usize) bool {
        for (self.counts, limits) |i, j| {
            if (i > j) {
                return false;
            }
        }
        return true;
    }

    fn power(self: Set) usize {
        return self.counts[0] * self.counts[1] * self.counts[2];
    }

    fn print(self: Set) void {
        for (self.counts, 0..) |count, i| {
            if (count > 0) {
                std.debug.print("{} ", .{count});
                std.debug.print("{s} ", .{color_names[i]});
            }
        }
        std.debug.print("\n", .{});
    }
};

fn parse_set(game: []const u8) Error!struct { []const u8, Set } {
    var set = std.mem.zeroInit(Set, .{});
    var position = game[count_characters(game, std.ascii.isWhitespace)..];

    while (position.len > 0 and position[0] != ';') {
        // Parse a cubes value
        const cubes = try parse_cubes(position);
        try set.update(cubes[2], cubes[1]);
        position = cubes[0];

        // Walk comma
        if (position.len > 0 and position[0] == ',') {
            position = position[1..];
        }

        // Walk spaces
        position = position[count_characters(position, std.ascii.isWhitespace)..];
    }

    return .{ position, set };
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var sum: usize = 0;

    var line_buf: [1024]u8 = undefined;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        if (line.len == 0) {
            continue;
        }

        var min_set = std.mem.zeroInit(Set, .{});

        // Parse id
        const id = try parse_id(line);

        var position = id[0];
        while (position.len > 0) {
            const set = try parse_set(position);
            set[1].print();
            //if (!set[1].is_possible(.{ 12, 13, 14 })) {
            //    continue :lines;
            //}
            min_set.update_maximum(set[1]);
            position = set[0];

            // Walk semicolon
            if (position.len > 0 and position[0] == ';') {
                position = position[1..];
            }
        }

        // Sum up id for a valid game
        //sum += id[1];

        // Sum up power for minimum set
        sum += min_set.power();
    }

    std.debug.print("{}\n", .{sum});
}
