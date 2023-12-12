const std = @import("std");

const Error = std.mem.Allocator.Error;
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

fn printImage(columns: []const List(bool)) void {
    for (0..columns[0].items.len) |i| {
        for (columns) |column| {
            std.debug.print("{c}", .{if (column.items[i]) @as(u8, '#') else '.'});
        }
        std.debug.print("\n", .{});
    }
}

fn inBetweenCount(min: usize, max: usize, list: []const usize) usize {
    var count: usize = 0;
    for (list) |item| {
        if (item >= max) {
            break;
        }
        if (item > min) {
            count += 1;
        }
    }
    return count;
}

const Galaxy = struct {
    column: usize,
    row: usize,

    fn distance(self: Galaxy, other: Galaxy, expand_rows: []const usize, expand_cols: []const usize) usize {
        const min_col = @min(self.column, other.column);
        const max_col = @max(self.column, other.column);
        const min_row = @min(self.row, other.row);
        const max_row = @max(self.row, other.row);

        return (max_col - min_col) + (max_row - min_row) + inBetweenCount(min_col, max_col, expand_cols) + inBetweenCount(min_row, max_row, expand_rows);
    }
};

fn parseRow(columns: []List(bool), expand_rows: *List(usize), galaxies: *List(Galaxy), line: []const u8, i: usize) Error!void {
    var empty = true;
    for (columns, line, 0..) |*column, char, j| {
        const galaxy = char == '#';
        try column.append(galaxy);
        if (galaxy) {
            empty = false;
            try galaxies.append(.{ .column = j, .row = i });
        }
    }
    if (empty) {
        try expand_rows.append(i);
    }
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var line_buf = try List(u8).initCapacity(allocator, 1024);
    const writer = line_buf.writer();

    // Initialize galaxy list
    var galaxies = try List(Galaxy).initCapacity(allocator, 1024);

    // Parse first line and allocate columns
    try in_r.streamUntilDelimiter(writer, '\n', null);
    // Initialize row expansion list
    var expand_rows = try List(usize).initCapacity(allocator, 1024);
    // Allocate and initialize columns
    const columns = try allocator.alloc(List(bool), line_buf.items.len);
    for (columns) |*column| {
        column.* = try List(bool).initCapacity(allocator, 1024);
    }
    // Parse first line
    try parseRow(columns, &expand_rows, &galaxies, line_buf.items, 0);
    line_buf.clearRetainingCapacity();

    // Parse rest of the lines
    var i: usize = 1;
    while (r: {
        in_r.streamUntilDelimiter(writer, '\n', null) catch |e| switch (e) {
            error.EndOfStream => break :r false,
            else => return e,
        };
        break :r true;
    }) : (line_buf.clearRetainingCapacity()) {
        if (line_buf.items.len == 0) {
            continue;
        }
        try parseRow(columns, &expand_rows, &galaxies, line_buf.items, i);
        i += 1;
    }

    // Initialize column expansion list
    var expand_cols = try List(usize).initCapacity(allocator, columns[0].items.len);
    for (columns, 0..) |column, j| {
        if (std.mem.allEqual(bool, column.items, false)) {
            try expand_cols.append(j);
        }
    }

    std.debug.print("{} galaxies.\n", .{galaxies.items.len});
    std.debug.print("Expand rows: {any}\n", .{expand_rows.items});
    std.debug.print("Expand cols: {any}\n", .{expand_cols.items});

    var sum: usize = 0;
    var a: usize = 0;
    while (a < galaxies.items.len) : (a += 1) {
        for (a..galaxies.items.len) |b| {
            if (a == b) {
                continue;
            }
            sum += galaxies.items[a].distance(galaxies.items[b], expand_rows.items, expand_cols.items);
        }
    }

    std.debug.print("Sum of all pair distances: {}\n", .{sum});
}
