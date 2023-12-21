const std = @import("std");

const Error = std.fmt.ParseIntError || std.mem.Allocator.Error;
const Allocator = std.mem.Allocator;
const List = std.ArrayListUnmanaged;

const Direction = enum(u4) {
    n = 0b0001,
    w = 0b0010,
    s = 0b0100,
    e = 0b1000,
};

const Pattern = struct {
    mat: List(u8),
    width: usize,

    fn print(self: Pattern) void {
        const h = self.mat.items.len / self.width;
        for (0..h) |y| {
            std.debug.print("{: >4} ", .{h - y});
            for (0..self.width) |x| {
                std.debug.print("{c}", .{self.mat.items[y * self.width + x]});
            }
            std.debug.print("\n", .{});
        }
    }

    fn getLoad(self: Pattern) usize {
        var sum: usize = 0;
        const h = self.mat.items.len / self.width;
        for (0..h) |y| {
            const factor = h - y;
            for (0..self.width) |x| {
                if (self.get(y, x).* == 'O') {
                    sum += factor;
                }
            }
        }
        return sum;
    }

    fn init() Pattern {
        return std.mem.zeroInit(Pattern, .{});
    }

    fn get(self: Pattern, y: usize, x: usize) *u8 {
        return &self.mat.items[y * self.width + x];
    }

    fn roll(from: *u8, to: *u8) bool {
        if (from.* != 'O') {
            return false;
        }

        if (to.* == '.') {
            std.mem.swap(u8, from, to);
            return true;
        }

        return false;
    }

    fn tilt(self: Pattern, dir: Direction) void {
        const height = self.mat.items.len / self.width;
        var moved: ?bool = null;
        while (moved orelse true) {
            moved = false;

            switch (dir) {
                .n => {
                    for (1..height) |y| {
                        for (0..self.width) |x| {
                            if (roll(self.get(y, x), self.get(y - 1, x))) {
                                moved = true;
                            }
                        }
                    }
                },
                .w => {
                    for (1..self.width) |x| {
                        for (0..height) |y| {
                            if (roll(self.get(y, x), self.get(y, x - 1))) {
                                moved = true;
                            }
                        }
                    }
                },
                .s => {
                    var y = height - 1;
                    while (y > 0) : (y -= 1) {
                        for (0..self.width) |x| {
                            if (roll(self.get(y - 1, x), self.get(y, x))) {
                                moved = true;
                            }
                        }
                    }
                },
                .e => {
                    var x = self.width - 1;
                    while (x > 0) : (x -= 1) {
                        for (0..height) |y| {
                            if (roll(self.get(y, x - 1), self.get(y, x))) {
                                moved = true;
                            }
                        }
                    }
                },
            }
        }
    }

    fn deinit(self: Pattern, allocator: Allocator) void {
        self.mat.deinit(allocator);
    }
};

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var pattern = Pattern.init();

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
            continue;
        }

        pattern.width = line.len;
        try pattern.mat.appendSlice(allocator, line);
    }

    // Basic tilt
    pattern.print();
    std.debug.print("----- Start -----\n", .{});
    pattern.tilt(Direction.n);
    pattern.print();
    std.debug.print("Load is {}\n", .{pattern.getLoad()});

    // Run advanced spin
    pattern.tilt(Direction.w);
    pattern.tilt(Direction.s);
    pattern.tilt(Direction.e);
    const target = 1000000000;
    var indices = std.StringHashMap(usize).init(allocator);
    var i: usize = 1;
    while (i < target) : (i += 1) {
        std.debug.print("\nAfter {} cycles:\n", .{i});
        pattern.print();

        const key = try allocator.dupe(u8, pattern.mat.items);
        const v = try indices.getOrPut(key);
        if (v.found_existing) {
            allocator.free(key);
            const prev = v.value_ptr.*;
            const dist = i - prev;
            std.debug.print("Previously seen after {} cycles, repeat dist {}\n", .{ prev, dist });
            while ((i + dist) < target) : (i += dist) {}
        }
        v.value_ptr.* = i;

        for (0..4) |j| {
            const dir: Direction = @enumFromInt(@as(u4, 1) << @intCast(j));
            pattern.tilt(dir);
        }
    }

    std.debug.print("\nAfter {} cycles:\n", .{i});
    pattern.print();
    std.debug.print("Load after spinning is {}\n", .{pattern.getLoad()});
}
