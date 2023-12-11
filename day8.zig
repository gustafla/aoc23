const std = @import("std");

const Error = error{
    InvalidLine,
    InvalidNode,
    InvalidDirection,
};

const Direction = enum {
    l,
    r,

    fn parse(char: u8) Error!Direction {
        return switch (char) {
            'L' => .l,
            'R' => .r,
            else => Error.InvalidDirection,
        };
    }
};

const base = 'Z' - 'A' + 1;
const Node = u16;

fn parseNode(str: []const u8) Error!Node {
    var sum: Node = 0;
    var place: Node = 1;
    var i = str.len;
    while (i > 0) : (i -= 1) {
        const digit = str[i - 1];
        switch (digit) {
            'A'...'Z' => {},
            else => return Error.InvalidNode,
        }
        const value: Node = @intCast(digit - 'A');
        sum += value * place;
        place *= base;
    }
    return sum;
}

pub fn allEnd(nodes: []const Node) bool {
    for (nodes) |node| {
        if (node % base != base - 1) {
            return false;
        }
    }
    return true;
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var in_buf = std.io.bufferedReader(in.reader());
    var in_r = in_buf.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const nodes = base * base * base;
    var adjlist = try allocator.alloc([2]Node, nodes);
    var directions = try std.ArrayList(Direction).initCapacity(allocator, 1024);
    var starts = try std.ArrayList(Node).initCapacity(allocator, base * base);
    var ends = try std.ArrayList(Node).initCapacity(allocator, base * base);

    var line_buf = try std.ArrayList(u8).initCapacity(allocator, 1024);
    const writer = line_buf.writer();

    // Parse first line directions
    try in_r.streamUntilDelimiter(writer, '\n', null);
    for (line_buf.items) |char| {
        try directions.append(try Direction.parse(char));
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

        // Parse current node
        const line = line_buf.items;
        const eqsign = std.mem.indexOfScalar(u8, line, '=') orelse return Error.InvalidLine;
        const nodestr = std.mem.trim(u8, line[0..eqsign], " \t");
        const node = try parseNode(nodestr);

        // Add to starts, ends
        switch (node % base) {
            0 => try starts.append(node),
            base - 1 => try ends.append(node),
            else => {},
        }

        // Parse edges
        const edgestr = line[eqsign + 1 ..];
        const comma = std.mem.indexOfScalar(u8, edgestr, ',') orelse return Error.InvalidLine;
        const leftstr = edgestr[0..comma];
        const rightstr = edgestr[comma..];
        const left = try parseNode(std.mem.trim(u8, leftstr, " \t(,"));
        const right = try parseNode(std.mem.trim(u8, rightstr, " \t),"));

        adjlist[node][0] = left;
        adjlist[node][1] = right;
    }

    std.debug.assert(starts.items.len == ends.items.len);

    var i: usize = 0;
    var start = parseNode("AAA") catch unreachable;
    const goal = parseNode("ZZZ") catch unreachable;
    while (start != goal) : (i += 1) {
        const direction = directions.items[i % directions.items.len];
        start = adjlist[start][@intFromEnum(direction)];
    }

    std.debug.print("Basic traversal took {} steps\n", .{i});

    i = 0;
    while (!allEnd(starts.items)) : (i += 1) {
        const direction = directions.items[i % directions.items.len];
        for (starts.items) |*node| {
            node.* = adjlist[node.*][@intFromEnum(direction)];
        }
    }
    std.debug.print("Advanced traversal took {} steps\n", .{i});
}
