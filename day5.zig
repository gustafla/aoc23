const std = @import("std");

const List = std.ArrayList;
const Gpa = std.heap.GeneralPurposeAllocator(.{});
const Allocator = std.mem.Allocator;
const Error = Gpa.Error || std.fmt.ParseIntError;

fn parseList(alloc: Allocator, slice: []const u8) Error!List(u32) {
    var list = try List(u32).initCapacity(alloc, 20);
    errdefer list.deinit();

    var it = std.mem.splitScalar(u8, slice, ' ');
    while (it.next()) |str| {
        if (str.len == 0) {
            continue;
        }
        const integer = try std.fmt.parseInt(u32, str, 10);
        try list.append(integer);
    }

    return list;
}

const MapEntry = struct {
    from: u32,
    to: u32,
    len: u32,
};

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

    for (seeds.items) |seed| {
        std.debug.print("Seed {}\n", .{seed});
    }

    for (maps, 1..) |map, i| {
        std.debug.print("\nMap {}:\n", .{i});
        for (map.items) |entry| {
            std.debug.print("\t{any}\n", .{entry});
        }
    }

    return;

    //while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {}

    //std.debug.print("{}\n", .{sum});
}
