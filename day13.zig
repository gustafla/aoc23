const std = @import("std");

const Error = std.fmt.ParseIntError || std.mem.Allocator.Error;
const Allocator = std.mem.Allocator;

const Pattern = struct {
    mat: []const u8,
    width: usize,

    fn print(self: Pattern) void {
        for (0..self.mat.len / self.width) |y| {
            std.debug.print("{: >4} ", .{y});
            for (0..self.width) |x| {
                std.debug.print("{c}", .{self.mat[y * self.width + x]});
                std.debug.print("{c}", .{self.mat[y * self.width + x]});
            }
            std.debug.print("\n", .{});
        }
    }

    fn transpose(self: Pattern, allocator: Allocator) Pattern {
        const transposed = allocator.alloc(u8, self.mat.len) catch @panic("OOM");
        const height = self.mat.len / self.width;
        for (self.mat, 0..) |elem, i| {
            const y = i / self.width;
            const x = i % self.width;
            transposed[x * height + y] = elem;
        }
        return .{ .mat = transposed, .width = height };
    }

    fn deinit(self: Pattern, allocator: Allocator) void {
        allocator.free(self.mat);
    }
};

fn linesAbove(yyc: struct { usize, usize }) usize {
    std.debug.print("lower is at {} and upper is at {}... ", .{ yyc[0], yyc[1] });
    const span = (yyc[0] - yyc[1]);
    std.debug.print("their range spans {} lines... ", .{span});
    const above = yyc[0] - span / 2 + if (yyc[1] == 0) @as(usize, 0) else 1; // off by one fix oof
    std.debug.print("thus there must be {} lines above the center\n", .{above});
    return above;
}

fn analyzeLines(pat: Pattern) struct { usize, usize } {
    var yc: usize = 1;
    for (1..pat.mat.len / pat.width) |y| {
        std.debug.print("y={}, yc={}... ", .{ y, yc - 1 });
        // If lines being compared match
        if (std.mem.eql(u8, pat.mat[y * pat.width ..][0..pat.width], pat.mat[(yc - 1) * pat.width ..][0..pat.width])) {
            std.debug.print("match\n", .{});
            // If mirror line index is at end, return
            if (yc == 1) {
                return .{ y, yc - 1 };
            }
            yc -= 1;
        } else {
            std.debug.print("no match\n", .{});
            yc = y + 1;
        }
    }
    return .{ pat.mat.len / pat.width - 1, yc - 1 };
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var pattern = std.ArrayList(u8).init(allocator);
    var width: usize = 0;
    var sum: usize = 0;

    var line_buf = try std.ArrayList(u8).initCapacity(allocator, 1024);
    const writer = line_buf.writer();
    while (r: {
        in_r.streamUntilDelimiter(writer, '\n', null) catch |e| switch (e) {
            error.EndOfStream => break :r false,
            else => return e,
        };
        break :r true;
    }) : (line_buf.clearRetainingCapacity()) {
        const line = line_buf.items;
        if (line.len == 0) {
            const pat = Pattern{ .mat = pattern.items, .width = width };
            const tat = pat.transpose(allocator);
            for ([2]Pattern{ pat, tat }, [2]usize{ 100, 1 }) |p, weight| {
                p.print();
                const analysis = analyzeLines(p);
                std.debug.print("Analysis: {any}\n", .{analysis});
                if (analysis[0] != analysis[1]) {
                    sum += linesAbove(analysis) * weight;
                }
            }
            tat.deinit(allocator);

            // New pattern
            pattern.clearRetainingCapacity();
            continue;
        }

        width = line.len;
        try pattern.appendSlice(line);
    }

    std.debug.print("Basic sum: {}\n", .{sum});
}
