const std = @import("std");

const List = std.ArrayList;
const Gpa = std.heap.GeneralPurposeAllocator(.{});
const Allocator = std.mem.Allocator;
const Error = Gpa.Error || std.fmt.ParseIntError;

fn parseList(alloc: Allocator, slice: []const u8) Error!List(u64) {
    var list = try List(u64).initCapacity(alloc, 20);
    errdefer list.deinit();

    var it = std.mem.splitScalar(u8, slice, ' ');
    while (it.next()) |str| {
        if (str.len == 0) {
            continue;
        }
        const integer = try std.fmt.parseInt(u64, str, 10);
        try list.append(integer);
    }

    return list;
}

const MapEntry = struct {
    from: u64,
    to: u64,
    len: u64,

    fn lessThan(ctx: void, lhs: MapEntry, rhs: MapEntry) bool {
        _ = ctx;
        return lhs.from < rhs.from;
    }
};

fn indexOfStart(map: []const MapEntry, number: u64) ?usize {
    var nearest_i: ?usize = null;
    for (map, 0..) |entry, i| {
        if (entry.from > number) {
            break;
        }
        if (nearest_i) |ni| {
            if (entry.from <= map[ni].from) {
                continue;
            }
        }
        nearest_i = i;
    }
    return nearest_i;
}

fn mapSeed(maps: []const List(MapEntry), seed: u64) u64 {
    var number = seed;
    for (maps) |map| {
        if (indexOfStart(map.items, number)) |i| {
            const entry = map.items[i];
            if (number < entry.from + entry.len) {
                number = number - entry.from + entry.to;
            }
            continue;
        }
    }
    return number;
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();
    var line_buf: [1024]u8 = undefined;

    // Initialize allocator for dynamic memory use
    var gpa = Gpa{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // Initialize mapping lists
    var maps: [7]List(MapEntry) = undefined;
    for (&maps) |*map| {
        map.* = try List(MapEntry).initCapacity(alloc, 64);
    }
    defer for (maps) |map| {
        map.deinit();
    };

    // Parse seeds
    const first_line = (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')).?;
    const seeds = try parseList(alloc, first_line[6..]);
    defer seeds.deinit();

    // Parse maps
    var n: usize = 0;
    while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        if (std.mem.endsWith(u8, line, "map:")) {
            n += 1;
            continue;
        }

        const list = parseList(alloc, line) catch continue;
        defer list.deinit();
        if (list.items.len != 3) {
            continue;
        }

        try maps[n - 1].append(.{ .from = list.items[1], .to = list.items[0], .len = list.items[2] });
    }

    // Sort maps
    for (maps) |map| {
        std.sort.heap(MapEntry, map.items, {}, MapEntry.lessThan);
    }

    var min: u64 = 0xffff_ffff_ffff_ffff;
    for (seeds.items) |seed| {
        const location = mapSeed(&maps, seed);
        if (location < min) {
            min = location;
        }
        std.debug.print("Seed {} location {}\n", .{ seed, location });
    }
    std.debug.print("min location {}\n", .{min});

    min = 0xffff_ffff_ffff_ffff;
    for (0..seeds.items.len / 2) |i| {
        for (seeds.items[i * 2]..seeds.items[i * 2] + seeds.items[i * 2 + 1]) |seed| {
            const location = mapSeed(&maps, seed);
            if (location < min) {
                min = location;
            }
            //std.debug.print("Seed (range) {} location {}\n", .{ seed, location });
        }
    }
    std.debug.print("min (range) location {}\n", .{min});

    return;

    //while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {}

    //std.debug.print("{}\n", .{sum});
}
