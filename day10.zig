const std = @import("std");

const Error = error{
    NoStartTile,
    TooManyStartTiles,
    AmbiguousStartTile,
    UnsupportedCharacter,
} || std.mem.Allocator.Error;
const Allocator = std.mem.Allocator;

const Direction = enum(u4) {
    n = 0b0001,
    w = 0b0010,
    e = 0b0100,
    s = 0b1000,

    fn reverse(self: Direction) Direction {
        return @enumFromInt(@bitReverse(@intFromEnum(self)));
    }

    fn toStr(self: Direction) []const u8 {
        return switch (self) {
            .n => "North",
            .w => "West",
            .e => "East",
            .s => "South",
        };
    }
};

const Pipe = enum(u4) {
    ns = @intFromEnum(Direction.n) | @intFromEnum(Direction.s),
    we = @intFromEnum(Direction.w) | @intFromEnum(Direction.e),
    ne = @intFromEnum(Direction.n) | @intFromEnum(Direction.e),
    nw = @intFromEnum(Direction.n) | @intFromEnum(Direction.w),
    sw = @intFromEnum(Direction.s) | @intFromEnum(Direction.w),
    se = @intFromEnum(Direction.s) | @intFromEnum(Direction.e),

    fn goesTo(self: Pipe, dir: Direction) bool {
        return (@intFromEnum(self) & @intFromEnum(dir)) != 0;
    }
};

const Position = struct {
    x: i32,
    y: i32,

    fn step(self: Position, dir: Direction) Position {
        return switch (dir) {
            .n => .{ .x = self.x, .y = self.y - 1 },
            .w => .{ .x = self.x - 1, .y = self.y },
            .e => .{ .x = self.x + 1, .y = self.y },
            .s => .{ .x = self.x, .y = self.y + 1 },
        };
    }
};

const Maze = struct {
    width: usize,
    height: usize,
    tiles: []?Pipe,
    start: Position,

    fn get(self: Maze, position: Position) ?Pipe {
        if (position.x < 0 or position.y < 0 or position.x > self.width or position.y > self.height) {
            return null;
        }
        const row: usize = @intCast(position.y);
        const col: usize = @intCast(position.x);
        return self.tiles[row * self.width + col];
    }

    fn init(allocator: Allocator, input: []u8) Error!Maze {
        var maze: Maze = undefined;

        maze.width = std.mem.indexOfScalar(u8, input, '\n').?;
        maze.height = input.len / (maze.width + 1);

        // Parse matrix from text
        maze.tiles = try allocator.alloc(?Pipe, maze.width * maze.height);
        var start: ?Position = null;
        for (input, 0..) |char, i| {
            if (char == '\n') {
                continue;
            }
            const y = i / (maze.width + 1);
            const x = (i - y) % (maze.width);
            const index = y * maze.width + x;
            const tile = switch (char) {
                '|' => Pipe.ns,
                '-' => Pipe.we,
                'L' => Pipe.ne,
                'J' => Pipe.nw,
                '7' => Pipe.sw,
                'F' => Pipe.se,
                '.' => null,
                'S' => blk: {
                    if (start != null) {
                        return Error.TooManyStartTiles;
                    }
                    start = .{ .x = @intCast(x), .y = @intCast(y) };
                    break :blk null;
                },
                else => return Error.UnsupportedCharacter,
            };
            maze.tiles[index] = tile;
        }

        maze.start = start orelse return Error.NoStartTile;

        // Resolve start tile pipe configuration
        var directions: u4 = 0;
        for (0..4) |i| {
            const dir: Direction = @enumFromInt(@as(u4, 1) << @intCast(i));
            const neighbor = maze.start.step(dir);
            const tile = maze.get(neighbor);
            if (tile) |pipe| {
                if (pipe.goesTo(dir.reverse())) {
                    directions |= @intFromEnum(dir);
                }
            }
        }

        if (@popCount(directions) != 2) {
            return Error.AmbiguousStartTile;
        }

        const x: usize = @intCast(maze.start.x);
        const y: usize = @intCast(maze.start.y);
        maze.tiles[y * maze.width + x] = @enumFromInt(directions);

        return maze;
    }

    fn loopLength(self: Maze) ?u32 {
        var walked: ?Direction = null;
        var at = self.start;
        var underfoot = self.get(at).?;
        var length: u32 = 0;

        walk: while (walked == null or !std.meta.eql(at, self.start)) : (length += 1) {
            for (0..4) |i| {
                const dir: Direction = @enumFromInt(@as(u4, 1) << @intCast(i));

                // Do not go to directions inavailable from this pipe
                if (!underfoot.goesTo(dir)) {
                    continue;
                }

                // Do not go backwards
                if (walked) |prev| {
                    if (dir.reverse() == prev) {
                        continue;
                    }
                }

                const neighbor = at.step(dir);
                const tile = self.get(neighbor);
                if (tile) |pipe| {
                    // Do not go to unconnected pipes
                    if (!pipe.goesTo(dir.reverse())) {
                        continue;
                    }

                    // Update state :)
                    walked = dir;
                    at = neighbor;
                    underfoot = pipe;
                    continue :walk;
                }
            }
            return null;
        }

        return length;
    }
};

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var line_buf = try std.ArrayList(u8).initCapacity(allocator, 1024);
    try in_r.readAllArrayList(&line_buf, 1024 * 1024);

    const maze = try Maze.init(allocator, line_buf.items);
    std.debug.print("Simple solution: {}\n", .{maze.loopLength().? / 2});
}
