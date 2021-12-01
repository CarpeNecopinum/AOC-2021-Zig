const std = @import("std");
const Allocator = std.mem.Allocator;

fn read_ints_file(alloc: *Allocator, filename: []u8) ![]i64 {
    var list = std.ArrayList(i64).init(alloc);
    errdefer list.deinit();

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var in_stream = buffered_reader.reader();

    var line_buf: [25]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        var num = try std.fmt.parseInt(i64, line, 10);
        try list.append(num);
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

    const numbers = try read_ints_file(alloc, args[1]);
    defer alloc.free(numbers);

    var increases: i64 = 0;
    var last = numbers[0];
    for (numbers[1..]) |number| {
        if (number > last) increases += 1;
        last = number;
    }

    std.debug.print("Num increases: {}\n", .{increases});
}