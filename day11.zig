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

fn parseRow(columns: []List(bool), expand_rows: *List(usize), line: []const u8, i: usize) Error!void {
    var empty = true;
    for (columns, line) |*column, char| {
        const galaxy = char == '#';
        try column.append(galaxy);
        empty = empty and !galaxy;
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

    var line_buf = try std.ArrayList(u8).initCapacity(allocator, 1024);
    const writer = line_buf.writer();

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
    try parseRow(columns, &expand_rows, line_buf.items, 0);
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
        try parseRow(columns, &expand_rows, line_buf.items, i);
        i += 1;
    }

    // Initialize column expansion list
    var expand_cols = try List(usize).initCapacity(allocator, columns[0].items.len);
    for (columns, 0..) |column, j| {
        if (std.mem.allEqual(bool, column.items, false)) {
            try expand_cols.append(j);
        }
    }

    std.debug.print("Expand rows: {any}\n", .{expand_rows.items});
    std.debug.print("Expand cols: {any}\n", .{expand_cols.items});
    printImage(columns);
}
