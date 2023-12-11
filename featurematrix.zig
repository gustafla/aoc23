// This is not an Advent of Code thing, but had no better repo to store it

const Error = std.mem.Allocator.Error;
const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

fn parseColumnHeaders(allocator: Allocator, line: []const u8) Error!List(u8) {
    var column_headers = try std.ArrayList(u8).initCapacity(allocator, 20);
    var it = std.mem.splitScalar(u8, line, ' ');
    while (it.next()) |str| {
        if (str.len != 1) {
            continue;
        }
        try column_headers.append(str[0]);
    }
    return column_headers;
}

const Col = struct {
    header: u8,
    features: List(bool),

    fn init(allocator: Allocator, header: u8) Error!Col {
        return .{ .header = header, .features = try List(bool).initCapacity(allocator, 20) };
    }

    fn value(col: Col) u64 {
        var val: u64 = 0;
        for (col.features.items, 0..) |c, i| {
            if (c) {
                val += @as(u64, 1) << @intCast(i);
            }
        }
        return val;
    }

    fn lessThan(_ctx: void, lhs: Col, rhs: Col) bool {
        _ = _ctx;
        return value(lhs) < value(rhs);
    }
};

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var line_buf = try List(u8).initCapacity(allocator, 1024);
    const writer = line_buf.writer();

    // Parse column headers
    try in_r.streamUntilDelimiter(writer, '\n', null);
    const column_headers = try parseColumnHeaders(allocator, line_buf.items);
    line_buf.clearRetainingCapacity();

    // Allocate columns
    const columns = try allocator.alloc(Col, column_headers.items.len);
    for (columns, column_headers.items) |*c, header| {
        c.* = try Col.init(allocator, header);
    }

    // Row headers
    var row_headers = try List([8]u8).initCapacity(allocator, 20);

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

        // Parse lines
        var it = std.mem.splitScalar(u8, line_buf.items, ' ');
        const header = it.next().?;
        const buf = try row_headers.addOne();
        @memset(buf, ' ');
        @memcpy(buf[0..header.len], header);
        std.debug.print("{s}\n", .{line_buf.items});

        var i: usize = 0;
        for (it.rest()) |char| {
            std.debug.print("{}: char = {c}\n", .{ i, char });
            if (std.ascii.isWhitespace(char)) {
                continue;
            }

            try columns[i].features.append(switch (char) {
                '+' => true,
                '-' => false,
                else => @panic("character was " ++ .{char}),
            });
            i += 1;
        }
        std.debug.assert(i == column_headers.items.len);
    }

    std.mem.sort(Col, columns, {}, Col.lessThan);

    std.debug.print("        ", .{});
    for (columns) |col| {
        std.debug.print("{c} ", .{col.header});
    }
    for (0..row_headers.items.len) |i| {
        std.debug.print("\n{s}", .{row_headers.items[i]});
        for (columns) |col| {
            std.debug.print("{c} ", .{if (col.features.items[i]) @as(u8, '+') else '-'});
        }
    }

    for (columns[0 .. columns.len - 1], columns[1..]) |a, b| {
        if (a.value() == b.value()) {
            std.debug.print("Identical columns!!\n", .{});
        }
    }

    std.debug.print("\n", .{});
}
