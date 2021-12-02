const std = @import("std");
const Allocator = std.mem.Allocator;

const Direction = enum{ Up, Down, Forward };
const Move = struct {
    direction: Direction,
    distance: i64
};

fn read_moves_file(alloc: *Allocator, filename: []u8) ![]Move {
    var list = std.ArrayList(Move).init(alloc);
    errdefer list.deinit();

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var in_stream = buffered_reader.reader();

    var line_buf: [128]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        var parts = std.mem.split(line, " ");
        const command = parts.next().?;
        const distance = try std.fmt.parseInt(i64, parts.next().?, 10);
        const direction:Direction = switch(command[0]) {
            'f' => .Forward,
            'd' => .Down,
            'u' => .Up,
            else => unreachable
        };
        try list.append(.{
            .direction = direction,
            .distance = distance
        });
    }

    return list.toOwnedSlice();
}


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) @panic("Leaked!");
    }
    var alloc = &gpa.allocator;
    
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} inputfile\n", .{args[0]});
    }

    const moves = try read_moves_file(alloc, args[1]);
    defer alloc.free(moves);

    var forward: i64 = 0;
    var depth: i64 = 0;
    var aim: i64 = 0;

    for (moves) |move| {
        switch (move.direction) {
            .Down => {
                aim += move.distance;
            },
            .Up => {
                aim -= move.distance;
            },
            .Forward => {
                forward += move.distance;
                depth += aim * move.distance;
            }
        }
    }

    std.debug.print("Total Moves - forward: {} depth: {}\n", .{forward, depth});
    std.debug.print("Product: {}\n", .{forward * depth});
}