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

    fn containsPos(self: Maze, position: Position) bool {
        return position.x >= 0 and position.y >= 0 and position.x < self.width and position.y < self.height;
    }

    fn get(self: Maze, position: Position) ?Pipe {
        if (!self.containsPos(position)) {
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

    fn processLoop(self: Maze, fill: []bool) ?u32 {
        var walked: ?Direction = null;
        var at = self.start;
        var underfoot = self.get(at).?;
        var length: u32 = 0;

        walk: while (walked == null or !std.meta.eql(at, self.start)) : (length += 1) {
            const x: usize = @intCast(at.x);
            const y: usize = @intCast(at.y);
            fill[y * self.width + x] = true;

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

fn search(fill: []const bool, maze: Maze, at: Position, depth: u32) ?u32 {
    // Base case #1, if overran from maze edge, do not count any tiles
    if (!maze.containsPos(at)) {
        return null;
    }

    // Check for max tile count in each cardinal direction
    var maximum: u32 = depth;
    for (0..4) |i| {
        const dir: Direction = @enumFromInt(@as(u4, 1) << @intCast(i));
        const neighbor = at.step(dir);
        const x: usize = @intCast(neighbor.x);
        const y: usize = @intCast(neighbor.y);

        // If direction is available
        if (!fill[y * maze.width + x]) {
            // Set the tile as visited/blocked
            fill[y * maze.width + x] = true;
            const next = search(fill, maze, neighbor, depth + 1);
            // If search finds maze edge, do not count any tiles
            if (next == null) {
                return null;
            }
            // Find the most tiles counted
            maximum = @max(maximum, next.?);
        }
    }

    // Base case #2, all options exhausted and didn't overrun the maze edge
    return maximum;
}

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
    const fill = try allocator.alloc(bool, maze.width * maze.height);
    for (fill) |*tile| {
        tile.* = false;
    }
    const len = maze.processLoop(fill).?;
    std.debug.print("Simple solution: {}\n", .{len / 2});
}
