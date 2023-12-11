const std = @import("std");

const Error = std.fmt.ParseIntError || std.mem.Allocator.Error;
const Allocator = std.mem.Allocator;

fn parseList(list: *std.ArrayList(i32), slice: []const u8) Error!void {
    var it = std.mem.splitScalar(u8, slice, ' ');
    while (it.next()) |str| {
        if (str.len == 0) {
            continue;
        }
        const integer = try std.fmt.parseInt(i32, str, 10);
        try list.append(integer);
    }
}

fn nextValue(values: []i32) i32 {
    std.debug.print("{any}\n", .{values});
    if (values.len < 2) {
        @panic("wtf");
    }

    if (std.mem.allEqual(i32, values, values[0])) {
        return values[0];
    }

    const target = values[0 .. values.len - 1];
    for (target, values[1..]) |*a, b| {
        a.* = b - a.*;
    }

    return nextValue(target) + values[values.len - 1];
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var report = try std.ArrayList(i32).initCapacity(allocator, 20);
    var sum: i64 = 0;

    var line_buf = try std.ArrayList(u8).initCapacity(allocator, 1024);
    const writer = line_buf.writer();
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

        try parseList(&report, line_buf.items);
        const next = nextValue(report.items);
        std.debug.print("Next is {}\n", .{next});
        sum += next;

        report.clearRetainingCapacity();
    }

    std.debug.print("Sum {}\n", .{sum});
}
