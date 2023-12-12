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
    const columns = try allocator.alloc(List(bool), line_buf.items.len);
    for (columns, line_buf.items) |*column, char| {
        column.* = try List(bool).initCapacity(allocator, 1024);
        try column.append(char == '#');
    }
    line_buf.clearRetainingCapacity();

    // Parse rest of the lines
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

        for (columns, line_buf.items) |*column, char| {
            try column.append(char == '#');
        }
    }

    printImage(columns);
}
