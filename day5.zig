const std = @import("std");

const Error = std.fmt.ParseIntError;

const T = u32;
const maxlen = 20;
const sentinel = 0xffffffff;
const List = [maxlen:sentinel]T;

fn parseList(slice: []const u8) Error!List {
    var list: List = std.mem.zeroInit(List, .{});
    var it = std.mem.splitScalar(u8, slice, ' ');
    while (it.next()) |str| {
        if (str.len == 0) {
            continue;
        }
        const integer = try std.fmt.parseInt(u32, str, 10);
        list[list.len] = integer;
    }

    return list;
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();
    var line_buf: [1024]u8 = undefined;

    //var sum: usize = 0;

    const first_line = (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')).?;
    const seeds = try parseList(first_line[6..]);
    for (seeds) |seed| {
        std.debug.print("Seed {}\n", .{seed});
    }

    return;

    //while (try in_r.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {}

    //std.debug.print("{}\n", .{sum});
}
